import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/config/app_services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/media_picker.dart';
import '../../../core/widgets/adaptive_image.dart';
import '../../../core/widgets/paw_button.dart';
import '../../../domain/models/app_user.dart';
import '../../../domain/models/care_models.dart';
import '../../../domain/models/user_role.dart';
import '../../../domain/repositories/care_repository.dart';
import '../../../domain/repositories/media_storage_service.dart';

class SuccessStoriesScreen extends StatelessWidget {
  const SuccessStoriesScreen({
    required this.user,
    required this.services,
    this.galleryOnly = false,
    super.key,
  });
  final AppUser user;
  final AppServices services;
  final bool galleryOnly;

  bool get _isManager => user.role == UserRole.shelterAdmin && !galleryOnly;

  @override
  Widget build(BuildContext context) {
    if (!_isManager) return _storiesScaffold(context, null);
    return StreamBuilder<List<ShelterProfile>>(
      stream: services.care.watchShelters(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final own = snapshot.data!
            .where((item) => item.adminId == user.uid)
            .toList();
        return _storiesScaffold(context, own.isEmpty ? null : own.first);
      },
    );
  }

  Widget _storiesScaffold(
    BuildContext context,
    ShelterProfile? shelter,
  ) => Scaffold(
    backgroundColor: AppColors.cream,
    appBar: AppBar(
      title: Text(_isManager ? 'Manage Success Stories' : 'Success Stories'),
      actions: _isManager
          ? [
              IconButton(
                tooltip: 'Preview public gallery',
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => SuccessStoriesScreen(
                      user: user,
                      services: services,
                      galleryOnly: true,
                    ),
                  ),
                ),
                icon: const Icon(Icons.visibility_outlined),
              ),
            ]
          : null,
    ),
    body: StreamBuilder<List<SuccessStory>>(
      stream: services.care.watchSuccessStories(
        shelterId: _isManager ? shelter?.id : null,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              snapshot.error is CareFailure
                  ? (snapshot.error! as CareFailure).message
                  : 'Stories could not be loaded.',
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final stories = snapshot.data!;
        if (stories.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Text(
                _isManager
                    ? 'No stories yet. Create a draft, add a photo, then publish it to the public gallery.'
                    : 'No published success stories yet.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          itemCount: stories.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final story = stories[index];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: index.isEven ? AppColors.peachLight : AppColors.mint,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (story.photoUrl != null && story.photoUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: AdaptiveImage(
                        source: story.photoUrl!,
                        height: 170,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        fallback: const SizedBox.shrink(),
                      ),
                    ),
                  if (story.photoUrl != null && story.photoUrl!.isNotEmpty)
                    const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          story.title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      if (_isManager)
                        Chip(
                          label: Text(
                            story.published
                                ? 'Published in gallery'
                                : 'Draft · private',
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(story.story),
                  if (story.updatedAt != null || story.createdAt != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      DateFormat(
                        'd MMM yyyy',
                      ).format(story.updatedAt ?? story.createdAt!),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  if (_isManager && shelter != null) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: () => _edit(context, shelter, story),
                          child: const Text('Edit'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _setPublished(
                            context,
                            story,
                            published: !story.published,
                          ),
                          icon: Icon(
                            story.published
                                ? Icons.visibility_off_outlined
                                : Icons.publish_outlined,
                          ),
                          label: Text(
                            story.published ? 'Unpublish' : 'Publish',
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () => _delete(context, story),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    ),
    floatingActionButton: _isManager && shelter != null
        ? FloatingActionButton.extended(
            onPressed: () => _edit(context, shelter, null),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create Story'),
          )
        : null,
  );

  Future<void> _edit(
    BuildContext context,
    ShelterProfile shelter,
    SuccessStory? story,
  ) => Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => _StoryForm(
        user: user,
        shelter: shelter,
        services: services,
        story: story,
      ),
    ),
  );

  Future<void> _delete(BuildContext context, SuccessStory story) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this story?'),
        content: const Text(
          'The story will be removed from your manager and the public gallery.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await services.care.deleteSuccessStory(story);
      if (story.photoPath != null) {
        await services.media.delete(story.photoPath!);
      }
    } on Object catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is CareFailure
                  ? error.message
                  : 'Story could not be deleted.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _setPublished(
    BuildContext context,
    SuccessStory story, {
    required bool published,
  }) async {
    if (published && (story.photoUrl?.trim().isEmpty ?? true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a story image in Edit before publishing.'),
        ),
      );
      return;
    }
    try {
      await services.care.saveSuccessStory(
        story.copyWith(published: published),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              published
                  ? 'Story published to the public gallery.'
                  : 'Story moved back to private drafts.',
            ),
          ),
        );
      }
    } on Object catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is CareFailure
                  ? error.message
                  : 'Story status could not be updated.',
            ),
          ),
        );
      }
    }
  }
}

class _StoryForm extends StatefulWidget {
  const _StoryForm({
    required this.user,
    required this.shelter,
    required this.services,
    this.story,
  });
  final AppUser user;
  final ShelterProfile shelter;
  final AppServices services;
  final SuccessStory? story;

  @override
  State<_StoryForm> createState() => _StoryFormState();
}

class _StoryFormState extends State<_StoryForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _story;
  late bool _published;
  PickedMedia? _image;
  String? _imageError;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.story?.title);
    _story = TextEditingController(text: widget.story?.story);
    _published = widget.story?.published ?? false;
  }

  @override
  void dispose() {
    _title.dispose();
    _story.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.cream,
    appBar: AppBar(
      title: Text(widget.story == null ? 'Create Story' : 'Edit Story'),
    ),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
        children: [
          if (_image != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Image.memory(
                _image!.bytes,
                height: 210,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            )
          else if (widget.story?.photoUrl?.isNotEmpty ?? false)
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: AdaptiveImage(
                source: widget.story!.photoUrl!,
                height: 210,
                width: double.infinity,
                fit: BoxFit.cover,
                fallback: const _StoryPhotoPlaceholder(),
              ),
            )
          else
            const _StoryPhotoPlaceholder(),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _pick,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: Text(_image?.name ?? 'Choose story image'),
          ),
          if (_imageError != null) ...[
            const SizedBox(height: 6),
            Text(
              _imageError!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextFormField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Title'),
            validator: _required,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _story,
            maxLines: 9,
            maxLength: 5000,
            decoration: const InputDecoration(labelText: 'Adoption story'),
            validator: _required,
          ),
          SwitchListTile(
            value: _published,
            onChanged: (value) => setState(() => _published = value),
            title: const Text('Publish in public gallery'),
            subtitle: Text(
              _published
                  ? 'Pet owners and veterinarians will be able to read it.'
                  : 'Draft stays private to your shelter admin account.',
            ),
          ),
          const SizedBox(height: 14),
          PawButton(label: 'Save Story', busy: _busy, onPressed: _save),
        ],
      ),
    ),
  );

  Future<void> _pick() async {
    try {
      final image = await MediaPicker.image();
      if (image != null && mounted) {
        setState(() {
          _image = image;
          _imageError = null;
        });
      }
    } on FormatException catch (error) {
      if (mounted) _show(error.message);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final existingPhotoUrl = widget.story?.photoUrl?.trim() ?? '';
    if (_published && _image == null && existingPhotoUrl.isEmpty) {
      setState(() {
        _imageError = 'Add an image before publishing this story.';
      });
      return;
    }
    setState(() => _busy = true);
    try {
      StoredMedia? uploadedMedia;
      if (_image != null) {
        try {
          uploadedMedia = await widget.services.media.upload(
            path:
                'shelters/${widget.shelter.id}/images/${DateTime.now().millisecondsSinceEpoch}_${_image!.name}',
            bytes: _image!.bytes,
            contentType: _image!.contentType,
          );
        } on MediaFailure catch (error) {
          if (mounted) {
            setState(() => _imageError = error.message);
            _show('${error.message} The story was not saved.');
          }
          return;
        }
      }
      final story = SuccessStory(
        id: widget.story?.id ?? '',
        shelterId: widget.shelter.id,
        adminId: widget.user.uid,
        title: _title.text,
        story: _story.text,
        published: _published,
        photoPath: uploadedMedia?.path ?? widget.story?.photoPath,
        photoUrl: uploadedMedia?.downloadUrl ?? widget.story?.photoUrl,
        createdAt: widget.story?.createdAt,
      );
      await widget.services.care.saveSuccessStory(story);
      if (uploadedMedia != null && widget.story?.photoPath != null) {
        await widget.services.media.delete(widget.story!.photoPath!);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _published
                  ? 'Story saved and published to the gallery.'
                  : 'Private draft saved. Publish it when it is ready.',
            ),
          ),
        );
        Navigator.pop(context);
      }
    } on Object catch (error) {
      if (mounted) {
        _show(
          error is CareFailure ? error.message : 'Story could not be saved.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _show(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required.' : null;
}

class _StoryPhotoPlaceholder extends StatelessWidget {
  const _StoryPhotoPlaceholder();

  @override
  Widget build(BuildContext context) => Container(
    height: 210,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: AppColors.peachLight,
      borderRadius: BorderRadius.circular(22),
    ),
    child: const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.photo_library_outlined, size: 42),
        SizedBox(height: 8),
        Text('Add a happy-ending photo'),
      ],
    ),
  );
}

enum CommunityModule { volunteer, contact }

class CommunityRequestsScreen extends StatelessWidget {
  const CommunityRequestsScreen({
    required this.user,
    required this.services,
    required this.module,
    super.key,
  });
  final AppUser user;
  final AppServices services;
  final CommunityModule module;

  @override
  Widget build(BuildContext context) {
    final stream = module == CommunityModule.volunteer
        ? services.care.watchVolunteerRequests(user)
        : services.care.watchContactMessages(user);
    final title = module == CommunityModule.volunteer
        ? 'Volunteer Requests'
        : 'Contact Messages';
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: Text(title)),
      body: StreamBuilder<List<CommunityRequest>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error is CareFailure
                    ? (snapshot.error! as CareFailure).message
                    : '$title could not be loaded.',
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final requests = snapshot.data!;
          if (requests.isEmpty) {
            return Center(child: Text('No ${title.toLowerCase()} yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            itemCount: requests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final request = requests[index];
              return Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: index.isEven ? AppColors.yellow : AppColors.peachLight,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            request.userName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Chip(label: Text(request.status)),
                      ],
                    ),
                    Text(
                      '${request.kind} · ${DateFormat.yMMMd().format(request.createdAt)}',
                    ),
                    const SizedBox(height: 7),
                    Text(request.message),
                    if (user.role == UserRole.shelterAdmin &&
                        request.status == 'pending') ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: [
                          FilledButton(
                            onPressed: () =>
                                _update(context, request, 'approved'),
                            child: const Text('Approve'),
                          ),
                          OutlinedButton(
                            onPressed: () =>
                                _update(context, request, 'closed'),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _update(
    BuildContext context,
    CommunityRequest request,
    String status,
  ) async {
    try {
      await services.care.updateCommunityRequestStatus(
        request: request,
        status: status,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${request.userName} request marked $status.'),
          ),
        );
      }
    } on Object catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is CareFailure
                  ? error.message
                  : 'Request could not be updated.',
            ),
          ),
        );
      }
    }
  }
}
