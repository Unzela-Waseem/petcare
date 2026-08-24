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
    super.key,
  });
  final AppUser user;
  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final admin = user.role == UserRole.shelterAdmin;
    if (!admin) return _storiesScaffold(context, null);
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
    appBar: AppBar(title: const Text('Success Stories')),
    body: StreamBuilder<List<SuccessStory>>(
      stream: services.care.watchSuccessStories(
        shelterId: user.role == UserRole.shelterAdmin ? shelter?.id : null,
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
          return const Center(child: Text('No success stories yet.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          itemCount: stories.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
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
                      if (user.role == UserRole.shelterAdmin)
                        Chip(
                          label: Text(story.published ? 'Published' : 'Draft'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(story.story),
                  if (user.role == UserRole.shelterAdmin &&
                      shelter != null) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: () => _edit(context, shelter, story),
                          child: const Text('Edit'),
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
    floatingActionButton: user.role == UserRole.shelterAdmin && shelter != null
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
  late final TextEditingController _title;
  late final TextEditingController _story;
  late bool _published;
  PickedMedia? _image;
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
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
      children: [
        OutlinedButton.icon(
          onPressed: _pick,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: Text(_image?.name ?? 'Choose story image'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _title,
          decoration: const InputDecoration(labelText: 'Title'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _story,
          maxLines: 9,
          maxLength: 5000,
          decoration: const InputDecoration(labelText: 'Adoption story'),
        ),
        SwitchListTile(
          value: _published,
          onChanged: (value) => setState(() => _published = value),
          title: const Text('Publish story'),
          subtitle: const Text('Drafts remain visible only to your shelter.'),
        ),
        const SizedBox(height: 14),
        PawButton(label: 'Save Story', busy: _busy, onPressed: _save),
      ],
    ),
  );

  Future<void> _pick() async {
    try {
      final image = await MediaPicker.image();
      if (image != null && mounted) setState(() => _image = image);
    } on FormatException catch (error) {
      if (mounted) _show(error.message);
    }
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty || _story.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      var story = SuccessStory(
        id: widget.story?.id ?? '',
        shelterId: widget.shelter.id,
        adminId: widget.user.uid,
        title: _title.text,
        story: _story.text,
        published: _published,
        photoPath: widget.story?.photoPath,
        photoUrl: widget.story?.photoUrl,
      );
      final id = await widget.services.care.saveSuccessStory(story);
      if (_image != null) {
        late final StoredMedia media;
        try {
          media = await widget.services.media.upload(
            path:
                'shelters/${widget.shelter.id}/images/${DateTime.now().millisecondsSinceEpoch}_${_image!.name}',
            bytes: _image!.bytes,
            contentType: _image!.contentType,
          );
        } on MediaFailure catch (error) {
          if (mounted) {
            _show('${error.message} The story was saved without it.');
            Navigator.pop(context);
          }
          return;
        }
        if (widget.story?.photoPath != null) {
          await widget.services.media.delete(widget.story!.photoPath!);
        }
        story = SuccessStory(
          id: id,
          shelterId: story.shelterId,
          adminId: story.adminId,
          title: story.title,
          story: story.story,
          published: story.published,
          photoPath: media.path,
          photoUrl: media.downloadUrl,
        );
        await widget.services.care.saveSuccessStory(story);
      }
      if (mounted) Navigator.pop(context);
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
            separatorBuilder: (_, _) => const SizedBox(height: 12),
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
