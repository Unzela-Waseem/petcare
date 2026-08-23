import 'package:flutter/material.dart';

import '../../../core/config/app_services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/media_picker.dart';
import '../../../core/widgets/adaptive_image.dart';
import '../../../core/widgets/paw_button.dart';
import '../../../domain/models/app_user.dart';
import '../../../domain/models/pet.dart';
import '../../../domain/models/user_role.dart';
import '../../../domain/repositories/care_repository.dart';
import '../../../domain/repositories/media_storage_service.dart';
import 'pet_detail_screen.dart';

class PetsScreen extends StatefulWidget {
  const PetsScreen({required this.user, required this.services, super.key});

  final AppUser user;
  final AppServices services;

  @override
  State<PetsScreen> createState() => _PetsScreenState();
}

class _PetsScreenState extends State<PetsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final owner = widget.user.role == UserRole.petOwner;
    final stream = owner
        ? widget.services.care.watchOwnedPets(widget.user.uid)
        : widget.services.care.watchAssignedPets(widget.user.uid);
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(owner ? 'My Pets' : 'Assigned Pets'),
        backgroundColor: AppColors.cream,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                hintText: 'Search by pet name or breed',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Pet>>(
              stream: stream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _Message(
                    icon: Icons.lock_outline_rounded,
                    text: _errorText(snapshot.error),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final query = _query.trim().toLowerCase();
                final pets = snapshot.data!
                    .where(
                      (pet) =>
                          pet.name.toLowerCase().contains(query) ||
                          pet.breed.toLowerCase().contains(query),
                    )
                    .toList();
                if (pets.isEmpty) {
                  return _Message(
                    icon: Icons.pets_outlined,
                    text: query.isEmpty
                        ? owner
                              ? 'Add your first pet profile.'
                              : 'No pets are assigned to you.'
                        : 'No matching pets found.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  itemCount: pets.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final pet = pets[index];
                    return _PetCard(
                      pet: pet,
                      canManage: owner,
                      onOpen: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PetDetailScreen(
                            pet: pet,
                            user: widget.user,
                            services: widget.services,
                          ),
                        ),
                      ),
                      onEdit: () => _edit(pet),
                      onDelete: () => _delete(pet),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: owner
          ? FloatingActionButton.extended(
              onPressed: () => _edit(null),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Pet'),
            )
          : null,
    );
  }

  Future<void> _edit(Pet? pet) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PetFormScreen(
          user: widget.user,
          services: widget.services,
          pet: pet,
        ),
      ),
    );
  }

  Future<void> _delete(Pet pet) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${pet.name}?'),
        content: const Text(
          'This removes the pet profile. Medical records remain protected for audit and cannot be deleted by the owner.',
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
    if (confirmed != true) return;
    try {
      if (pet.photoPath != null) {
        await widget.services.media.delete(pet.photoPath!);
      }
      await widget.services.care.deletePet(pet);
    } on Object catch (error) {
      if (mounted) _show(_errorText(error));
    }
  }

  void _show(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
}

class PetFormScreen extends StatefulWidget {
  const PetFormScreen({
    required this.user,
    required this.services,
    this.pet,
    super.key,
  });

  final AppUser user;
  final AppServices services;
  final Pet? pet;

  @override
  State<PetFormScreen> createState() => _PetFormScreenState();
}

class _PetFormScreenState extends State<PetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _species;
  late final TextEditingController _breed;
  late final TextEditingController _age;
  late final TextEditingController _description;
  late String _gender;
  PickedMedia? _image;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final pet = widget.pet;
    _name = TextEditingController(text: pet?.name);
    _species = TextEditingController(text: pet?.species);
    _breed = TextEditingController(text: pet?.breed);
    _age = TextEditingController(text: pet?.age.toString());
    _description = TextEditingController(text: pet?.description);
    _gender = pet?.gender.isNotEmpty == true ? pet!.gender : 'Female';
  }

  @override
  void dispose() {
    _name.dispose();
    _species.dispose();
    _breed.dispose();
    _age.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: Text(widget.pet == null ? 'Add Pet' : 'Edit Pet')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            _PhotoPicker(
              image: _image,
              photoUrl: widget.pet?.photoUrl,
              onTap: _pickImage,
            ),
            const SizedBox(height: 18),
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
              controller: _breed,
              decoration: const InputDecoration(labelText: 'Breed'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _age,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Age in years'),
              validator: (value) {
                final age = int.tryParse(value ?? '');
                if (age == null || age < 0 || age > 80) {
                  return 'Enter a valid age.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _gender,
              decoration: const InputDecoration(labelText: 'Gender'),
              items: const ['Female', 'Male', 'Unknown']
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  )
                  .toList(),
              onChanged: (value) => _gender = value ?? _gender,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              maxLines: 4,
              maxLength: 500,
              decoration: const InputDecoration(labelText: 'About your pet'),
            ),
            const SizedBox(height: 10),
            PawButton(
              label: widget.pet == null ? 'Create Pet Profile' : 'Save Changes',
              busy: _busy,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final image = await MediaPicker.image();
      if (image != null && mounted) setState(() => _image = image);
    } on FormatException catch (error) {
      if (mounted) _show(error.message);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      var pet = Pet(
        id: widget.pet?.id ?? '',
        ownerId: widget.user.uid,
        name: _name.text.trim(),
        species: _species.text.trim(),
        breed: _breed.text.trim(),
        age: int.parse(_age.text),
        gender: _gender,
        photoPath: widget.pet?.photoPath,
        photoUrl: widget.pet?.photoUrl,
        description: _description.text.trim(),
      );
      final id = await widget.services.care.savePet(pet);
      final image = _image;
      if (image != null) {
        late final StoredMedia media;
        try {
          media = await widget.services.media.upload(
            path:
                'pets/$id/images/${DateTime.now().millisecondsSinceEpoch}_${image.name}',
            bytes: image.bytes,
            contentType: image.contentType,
          );
        } on MediaFailure catch (error) {
          if (mounted) {
            _show('${error.message} The pet profile was saved without it.');
            Navigator.pop(context);
          }
          return;
        }
        if (widget.pet?.photoPath != null &&
            widget.pet!.photoPath != media.path) {
          await widget.services.media.delete(widget.pet!.photoPath!);
        }
        pet = pet.copyWith(
          id: id,
          photoPath: media.path,
          photoUrl: media.downloadUrl,
        );
        await widget.services.care.savePet(pet);
      }
      if (mounted) Navigator.pop(context);
    } on Object catch (error) {
      if (mounted) _show(_errorText(error));
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

class _PetCard extends StatelessWidget {
  const _PetCard({
    required this.pet,
    required this.canManage,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final Pet pet;
  final bool canManage;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            _PetImage(url: pet.photoUrl, size: 76),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pet.name, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text('${pet.breed} · ${pet.age} years · ${pet.gender}'),
                  const SizedBox(height: 7),
                  const Text(
                    'Private care profile',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            if (canManage)
              PopupMenuButton<String>(
                onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              )
            else
              const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ],
        ),
      ),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({
    required this.image,
    required this.photoUrl,
    required this.onTap,
  });
  final PickedMedia? image;
  final String? photoUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Center(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(54),
      child: Stack(
        children: [
          ClipOval(
            child: image != null
                ? Image.memory(
                    image!.bytes,
                    width: 108,
                    height: 108,
                    fit: BoxFit.cover,
                  )
                : _PetImage(url: photoUrl, size: 108),
          ),
          const Positioned(
            right: 0,
            bottom: 0,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.orange,
              child: Icon(Icons.photo_camera_outlined, size: 19),
            ),
          ),
        ],
      ),
    ),
  );
}

class _PetImage extends StatelessWidget {
  const _PetImage({required this.url, required this.size});
  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size,
      height: size,
      color: AppColors.peach,
      padding: EdgeInsets.all(size * 0.08),
      child: Image.asset('assets/images/pawfect_pet_family_cutout.png'),
    );
    if (url == null || url!.isEmpty) return ClipOval(child: fallback);
    return ClipOval(
      child: AdaptiveImage(
        source: url!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        fallback: fallback,
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: AppColors.orangeDeep),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

String _errorText(Object? error) => switch (error) {
  CareFailure failure => failure.message,
  FormatException failure => failure.message,
  _ => 'The information could not be loaded securely.',
};
