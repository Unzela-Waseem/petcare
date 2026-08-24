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

class AdoptionListingsScreen extends StatefulWidget {
  const AdoptionListingsScreen({
    required this.user,
    required this.services,
    super.key,
  });

  final AppUser user;
  final AppServices services;

  @override
  State<AdoptionListingsScreen> createState() => _AdoptionListingsScreenState();
}

class _AdoptionListingsScreenState extends State<AdoptionListingsScreen> {
  String _query = '';
  AdoptionStatus? _status;

  bool get _isAdmin => widget.user.role == UserRole.shelterAdmin;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: Text(_isAdmin ? 'Pet Listings' : 'Adoption')),
      body: _isAdmin
          ? StreamBuilder<List<ShelterProfile>>(
              stream: widget.services.care.watchShelters(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final own = snapshot.data!
                    .where((shelter) => shelter.adminId == widget.user.uid)
                    .toList();
                if (own.isEmpty) {
                  return _CreateShelterPrompt(
                    user: widget.user,
                    services: widget.services,
                  );
                }
                return _listingBody(own.first);
              },
            )
          : _listingBody(null),
    );
  }

  Widget _listingBody(ShelterProfile? shelter) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        child: TextField(
          onChanged: (value) => setState(() => _query = value),
          decoration: const InputDecoration(
            hintText: 'Search pet name, species, or health status',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
      ),
      SizedBox(
        height: 46,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          scrollDirection: Axis.horizontal,
          children: [
            ChoiceChip(
              label: const Text('All'),
              selected: _status == null,
              onSelected: (_) => setState(() => _status = null),
            ),
            const SizedBox(width: 8),
            ...AdoptionStatus.values.map(
              (status) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(status.label),
                  selected: _status == status,
                  onSelected: (_) => setState(() => _status = status),
                ),
              ),
            ),
          ],
        ),
      ),
      Expanded(
        child: StreamBuilder<List<AdoptionListing>>(
          stream: widget.services.care.watchAdoptionListings(
            shelterId: shelter?.id,
          ),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  snapshot.error is CareFailure
                      ? (snapshot.error! as CareFailure).message
                      : 'Listings could not be loaded.',
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final query = _query.trim().toLowerCase();
            final listings = snapshot.data!
                .where(
                  (item) =>
                      (_status == null || item.status == _status) &&
                      (item.petName.toLowerCase().contains(query) ||
                          item.species.toLowerCase().contains(query) ||
                          item.healthStatus.toLowerCase().contains(query)),
                )
                .toList();
            if (listings.isEmpty) {
              return const Center(
                child: Text('No matching adoption listings.'),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
              itemCount: listings.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final listing = listings[index];
                return _ListingCard(
                  listing: listing,
                  isAdmin: _isAdmin,
                  onRequest: () => _request(listing),
                  onEdit: () => _edit(shelter!, listing),
                  onDelete: () => _delete(listing),
                );
              },
            );
          },
        ),
      ),
      if (_isAdmin && shelter != null)
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
            child: PawButton(
              label: 'Add Adoption Listing',
              icon: Icons.add_rounded,
              onPressed: () => _edit(shelter, null),
            ),
          ),
        ),
    ],
  );

  Future<void> _request(AdoptionListing listing) async {
    final message = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Adopt ${listing.petName}'),
        content: TextField(
          controller: message,
          maxLines: 4,
          maxLength: 1000,
          decoration: const InputDecoration(
            labelText: 'Tell the shelter about your home',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    if (submitted != true || message.text.trim().isEmpty) return;
    try {
      await widget.services.care.submitAdoptionRequest(
        owner: widget.user,
        listing: listing,
        message: message.text,
      );
      if (mounted) _show('Your private adoption request was submitted.');
    } on Object catch (error) {
      if (mounted) {
        _show(
          error is CareFailure
              ? error.message
              : 'Request could not be submitted.',
        );
      }
    } finally {
      message.dispose();
    }
  }

  Future<void> _edit(ShelterProfile shelter, AdoptionListing? listing) =>
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => AdoptionListingFormScreen(
            user: widget.user,
            shelter: shelter,
            services: widget.services,
            listing: listing,
          ),
        ),
      );

  Future<void> _delete(AdoptionListing listing) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${listing.petName}?'),
        content: const Text(
          'Existing adoption requests remain available for audit.',
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
    if (yes != true) return;
    try {
      await widget.services.care.deleteAdoptionListing(listing);
      if (listing.photoPath != null) {
        await widget.services.media.delete(listing.photoPath!);
      }
    } on Object catch (error) {
      if (mounted) {
        _show(
          error is CareFailure
              ? error.message
              : 'Listing could not be deleted.',
        );
      }
    }
  }

  void _show(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
}

class AdoptionListingFormScreen extends StatefulWidget {
  const AdoptionListingFormScreen({
    required this.user,
    required this.shelter,
    required this.services,
    this.listing,
    super.key,
  });
  final AppUser user;
  final ShelterProfile shelter;
  final AppServices services;
  final AdoptionListing? listing;

  @override
  State<AdoptionListingFormScreen> createState() =>
      _AdoptionListingFormScreenState();
}

class _AdoptionListingFormScreenState extends State<AdoptionListingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _species;
  late final TextEditingController _age;
  late final TextEditingController _health;
  late final TextEditingController _description;
  late String _gender;
  late AdoptionStatus _status;
  PickedMedia? _image;
  String? _imageError;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final listing = widget.listing;
    _name = TextEditingController(text: listing?.petName);
    _species = TextEditingController(text: listing?.species);
    _age = TextEditingController(text: listing?.age.toString());
    _health = TextEditingController(text: listing?.healthStatus);
    _description = TextEditingController(text: listing?.description);
    _gender = listing?.gender ?? 'Female';
    _status = listing?.status ?? AdoptionStatus.available;
  }

  @override
  void dispose() {
    _name.dispose();
    _species.dispose();
    _age.dispose();
    _health.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.cream,
    appBar: AppBar(
      title: Text(widget.listing == null ? 'Add Listing' : 'Edit Listing'),
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
                width: double.infinity,
                height: 210,
                fit: BoxFit.cover,
              ),
            )
          else if (widget.listing?.photoUrl != null &&
              widget.listing!.photoUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: AdaptiveImage(
                source: widget.listing!.photoUrl!,
                width: double.infinity,
                height: 210,
                fit: BoxFit.cover,
                fallback: _PhotoPlaceholder(hasError: _imageError != null),
              ),
            )
          else
            _PhotoPlaceholder(hasError: _imageError != null),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: Text(
              _image == null ? 'Choose pet photo (required)' : _image!.name,
            ),
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
          const SizedBox(height: 4),
          Text(
            'JPG, PNG, or WebP · maximum 5 MB',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Pet name'),
            validator: _required,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _species,
            decoration: const InputDecoration(labelText: 'Species'),
            validator: _required,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _age,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Age in years'),
            validator: (value) =>
                int.tryParse(value ?? '') == null ? 'Enter a valid age.' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _gender,
            decoration: const InputDecoration(labelText: 'Gender'),
            items: const ['Female', 'Male', 'Unknown']
                .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)),
                )
                .toList(),
            onChanged: (value) => _gender = value ?? _gender,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _health,
            decoration: const InputDecoration(labelText: 'Health status'),
            validator: _required,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _description,
            maxLines: 4,
            maxLength: 1000,
            decoration: const InputDecoration(labelText: 'Description'),
            validator: _required,
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<AdoptionStatus>(
            initialValue: _status,
            decoration: const InputDecoration(labelText: 'Adoption status'),
            items: AdoptionStatus.values
                .map(
                  (value) =>
                      DropdownMenuItem(value: value, child: Text(value.label)),
                )
                .toList(),
            onChanged: (value) => _status = value ?? _status,
          ),
          const SizedBox(height: 18),
          PawButton(label: 'Save Listing', busy: _busy, onPressed: _save),
        ],
      ),
    ),
  );

  Future<void> _pickImage() async {
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
    final existingPhotoUrl = widget.listing?.photoUrl?.trim() ?? '';
    if (_image == null && existingPhotoUrl.isEmpty) {
      setState(() {
        _imageError = 'Add a clear pet photo before saving this listing.';
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
            _show('${error.message} The listing was not saved.');
          }
          return;
        }
      }

      final listing = AdoptionListing(
        id: widget.listing?.id ?? '',
        shelterId: widget.shelter.id,
        adminId: widget.user.uid,
        petName: _name.text.trim(),
        species: _species.text.trim(),
        age: int.parse(_age.text),
        gender: _gender,
        healthStatus: _health.text.trim(),
        status: _status,
        description: _description.text.trim(),
        photoPath: uploadedMedia?.path ?? widget.listing?.photoPath,
        photoUrl: uploadedMedia?.downloadUrl ?? widget.listing?.photoUrl,
      );
      await widget.services.care.saveAdoptionListing(listing);
      if (uploadedMedia != null && widget.listing?.photoPath != null) {
        await widget.services.media.delete(widget.listing!.photoPath!);
      }
      if (mounted) Navigator.pop(context);
    } on Object catch (error) {
      if (mounted) {
        _show(
          error is CareFailure ? error.message : 'Listing could not be saved.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required.' : null;
  void _show(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder({required this.hasError});

  final bool hasError;

  @override
  Widget build(BuildContext context) => Container(
    height: 210,
    width: double.infinity,
    decoration: BoxDecoration(
      color: AppColors.peach.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(
        color: hasError
            ? Theme.of(context).colorScheme.error
            : AppColors.border,
        width: hasError ? 1.5 : 1,
      ),
    ),
    child: const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.pets_rounded, size: 52),
        SizedBox(height: 10),
        Text('A pet photo is required'),
      ],
    ),
  );
}

class AdoptionRequestsScreen extends StatelessWidget {
  const AdoptionRequestsScreen({
    required this.user,
    required this.services,
    super.key,
  });
  final AppUser user;
  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final admin = user.role == UserRole.shelterAdmin;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Adoption Requests')),
      body: StreamBuilder<List<AdoptionRequest>>(
        stream: services.care.watchAdoptionRequests(user),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error is CareFailure
                    ? (snapshot.error! as CareFailure).message
                    : 'Requests could not be loaded.',
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final requests = snapshot.data!;
          if (requests.isEmpty) {
            return const Center(child: Text('No adoption requests yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
            itemCount: requests.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final request = requests[index];
              return Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: _requestColor(request.status),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${request.ownerName} → ${request.petName}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Chip(label: Text(request.status.label)),
                      ],
                    ),
                    Text(DateFormat.yMMMd().format(request.createdAt)),
                    const SizedBox(height: 8),
                    Text(request.message),
                    if (admin && request.status == RequestStatus.pending) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          FilledButton(
                            onPressed: () => _update(
                              context,
                              request,
                              RequestStatus.approved,
                            ),
                            child: const Text('Approve'),
                          ),
                          OutlinedButton(
                            onPressed: () => _update(
                              context,
                              request,
                              RequestStatus.rejected,
                            ),
                            child: const Text('Reject'),
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
    AdoptionRequest request,
    RequestStatus status,
  ) async {
    try {
      await services.care.updateAdoptionRequest(
        request: request,
        status: status,
      );
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

  Color _requestColor(RequestStatus status) => switch (status) {
    RequestStatus.pending => AppColors.yellow,
    RequestStatus.approved => AppColors.mint,
    RequestStatus.rejected => AppColors.lavender,
  };
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({
    required this.listing,
    required this.isAdmin,
    required this.onRequest,
    required this.onEdit,
    required this.onDelete,
  });
  final AdoptionListing listing;
  final bool isAdmin;
  final VoidCallback onRequest;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (listing.photoUrl != null && listing.photoUrl!.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AdaptiveImage(
              source: listing.photoUrl!,
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
              fallback: const SizedBox.shrink(),
            ),
          ),
        if (listing.photoUrl != null && listing.photoUrl!.isNotEmpty)
          const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                listing.petName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Chip(label: Text(listing.status.label)),
          ],
        ),
        Text('${listing.species} · ${listing.age} years · ${listing.gender}'),
        const SizedBox(height: 6),
        Text(
          listing.healthStatus,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        if (listing.description.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(listing.description),
        ],
        const SizedBox(height: 12),
        if (isAdmin)
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit'),
              ),
              OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Delete'),
              ),
            ],
          )
        else if (listing.status == AdoptionStatus.available)
          FilledButton.icon(
            onPressed: onRequest,
            icon: const Icon(Icons.favorite_outline_rounded),
            label: const Text('Request Adoption'),
          ),
      ],
    ),
  );
}

class _CreateShelterPrompt extends StatelessWidget {
  const _CreateShelterPrompt({required this.user, required this.services});
  final AppUser user;
  final AppServices services;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.home_work_outlined,
            size: 48,
            color: AppColors.orangeDeep,
          ),
          const SizedBox(height: 12),
          Text(
            'Create your shelter profile first.',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              builder: (_) =>
                  ShelterProfileForm(user: user, services: services),
            ),
            child: const Text('Create Shelter'),
          ),
        ],
      ),
    ),
  );
}

class ShelterProfileForm extends StatefulWidget {
  const ShelterProfileForm({
    required this.user,
    required this.services,
    this.shelter,
    super.key,
  });
  final AppUser user;
  final AppServices services;
  final ShelterProfile? shelter;

  @override
  State<ShelterProfileForm> createState() => _ShelterProfileFormState();
}

class _ShelterProfileFormState extends State<ShelterProfileForm> {
  late final TextEditingController _name;
  late final TextEditingController _location;
  late final TextEditingController _phone;
  late final TextEditingController _description;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.shelter?.name);
    _location = TextEditingController(text: widget.shelter?.location);
    _phone = TextEditingController(text: widget.shelter?.phone);
    _description = TextEditingController(text: widget.shelter?.description);
  }

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    _phone.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Shelter Profile',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Shelter name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _location,
              decoration: const InputDecoration(labelText: 'Location/address'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _description,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 18),
            PawButton(label: 'Save Shelter', busy: _busy, onPressed: _save),
          ],
        ),
      ),
    ),
  );

  Future<void> _save() async {
    if (_name.text.trim().isEmpty || _location.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      await widget.services.care.saveShelter(
        ShelterProfile(
          id: widget.shelter?.id ?? '',
          adminId: widget.user.uid,
          name: _name.text,
          location: _location.text,
          phone: _phone.text,
          description: _description.text,
        ),
      );
      if (mounted) Navigator.pop(context);
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is CareFailure
                  ? error.message
                  : 'Shelter could not be saved.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
