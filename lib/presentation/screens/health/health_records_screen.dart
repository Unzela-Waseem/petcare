import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/config/app_services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/media_picker.dart';
import '../../../core/widgets/paw_button.dart';
import '../../../domain/models/app_user.dart';
import '../../../domain/models/care_models.dart';
import '../../../domain/models/pet.dart';
import '../../../domain/models/user_role.dart';
import '../../../domain/repositories/care_repository.dart';
import '../../../domain/repositories/media_storage_service.dart';

class HealthRecordsScreen extends StatefulWidget {
  const HealthRecordsScreen({
    required this.user,
    required this.services,
    this.initialPet,
    super.key,
  });

  final AppUser user;
  final AppServices services;
  final Pet? initialPet;

  @override
  State<HealthRecordsScreen> createState() => _HealthRecordsScreenState();
}

class _HealthRecordsScreenState extends State<HealthRecordsScreen> {
  Pet? _selectedPet;
  HealthRecordType? _filter;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selectedPet = widget.initialPet;
    if (widget.user.role == UserRole.veterinarian) {
      _filter = HealthRecordType.medical;
    }
  }

  @override
  Widget build(BuildContext context) {
    final petStream = widget.user.role == UserRole.petOwner
        ? widget.services.care.watchOwnedPets(widget.user.uid)
        : widget.services.care.watchAssignedPets(widget.user.uid);
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(
          widget.user.role == UserRole.veterinarian
              ? 'Medical Records'
              : 'Health Records',
        ),
      ),
      body: StreamBuilder<List<Pet>>(
        stream: petStream,
        builder: (context, petSnapshot) {
          if (petSnapshot.hasError) return _error(petSnapshot.error);
          if (!petSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final pets = petSnapshot.data!;
          if (pets.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: Text('No authorized pets are available.'),
              ),
            );
          }
          final selected = pets.any((pet) => pet.id == _selectedPet?.id)
              ? pets.firstWhere((pet) => pet.id == _selectedPet!.id)
              : pets.first;
          _selectedPet = selected;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: DropdownButtonFormField<String>(
                  value: selected.id,
                  decoration: const InputDecoration(
                    labelText: 'Pet',
                    prefixIcon: Icon(Icons.pets_outlined),
                  ),
                  items: pets
                      .map(
                        (pet) => DropdownMenuItem(
                          value: pet.id,
                          child: Text('${pet.name} · ${pet.breed}'),
                        ),
                      )
                      .toList(),
                  onChanged: (id) => setState(
                    () => _selectedPet = pets.firstWhere((pet) => pet.id == id),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: const InputDecoration(
                    hintText: 'Search medical requirement or record',
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
                      selected: _filter == null,
                      onSelected: (_) => setState(() => _filter = null),
                    ),
                    const SizedBox(width: 8),
                    ...HealthRecordType.values.map(
                      (type) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(type.label),
                          selected: _filter == type,
                          onSelected: (_) => setState(() => _filter = type),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<List<HealthRecord>>(
                  stream: widget.services.care.watchHealthRecords(selected.id),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) return _error(snapshot.error);
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final query = _query.trim().toLowerCase();
                    final records = snapshot.data!.where((record) {
                      final clinical =
                          record.type == HealthRecordType.medical ||
                          record.veterinarianId != null;
                      final matchesType =
                          _filter == null ||
                          (_filter == HealthRecordType.medical
                              ? clinical
                              : record.type == _filter);
                      final searchable = [
                        record.title,
                        record.type.label,
                        record.diagnosis,
                        record.treatment,
                        record.prescription,
                        record.notes,
                      ].join(' ').toLowerCase();
                      return matchesType && searchable.contains(query);
                    }).toList();
                    if (records.isEmpty) {
                      return _EmptyRecords(
                        clinical:
                            widget.user.role == UserRole.veterinarian &&
                            _filter == HealthRecordType.medical,
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                      itemCount: records.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final record = records[index];
                        return _RecordCard(
                          record: record,
                          onTap: () => _details(record),
                          onDelete: () => _delete(record),
                          canDelete: widget.user.role == UserRole.veterinarian
                              ? record.veterinarianId == widget.user.uid
                              : record.veterinarianId == null &&
                                    record.type != HealthRecordType.medical,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final pet = _selectedPet;
          if (pet == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Wait for an authorized pet to load.'),
              ),
            );
            return;
          }
          Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => HealthRecordFormScreen(
                user: widget.user,
                pet: pet,
                services: widget.services,
              ),
            ),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: Text(
          widget.user.role == UserRole.veterinarian
              ? 'Clinical Record'
              : 'Care Record',
        ),
      ),
    );
  }

  Widget _error(Object? error) => Center(
    child: Padding(
      padding: const EdgeInsets.all(30),
      child: Text(
        error is CareFailure
            ? error.message
            : 'Protected health records could not be loaded.',
        textAlign: TextAlign.center,
      ),
    ),
  );

  void _details(HealthRecord record) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 6, 24, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                record.title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 5),
              Text(
                '${record.type.label} · ${DateFormat.yMMMd().format(record.date)}',
              ),
              if (record.diagnosis.isNotEmpty) ...[
                const SizedBox(height: 18),
                const Text(
                  'Diagnosis',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(record.diagnosis),
              ],
              if (record.treatment.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text(
                  'Treatment',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(record.treatment),
              ],
              if (record.prescription.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text(
                  'Prescription',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(record.prescription),
              ],
              if (record.notes.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text(
                  'Notes',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(record.notes),
              ],
              if (record.dueDate != null) ...[
                const SizedBox(height: 14),
                Text('Due ${DateFormat.yMMMd().format(record.dueDate!)}'),
              ],
              if (record.followUpDate != null) ...[
                const SizedBox(height: 14),
                Text(
                  'Follow-up ${DateFormat.yMMMd().format(record.followUpDate!)}',
                ),
              ],
              if (record.reportPaths.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  '${record.reportPaths.length} protected report(s) attached.',
                ),
              ],
              const SizedBox(height: 18),
              const Row(
                children: [
                  Icon(Icons.shield_outlined, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Clinical fields are editable only by an assigned veterinarian.',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _delete(HealthRecord record) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete health record?'),
        content: const Text(
          'Only records you are authorized to manage can be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
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
      await widget.services.care.deleteHealthRecord(
        actor: widget.user,
        record: record,
      );
      for (final path in record.reportPaths) {
        await widget.services.media.delete(path);
      }
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is CareFailure
                  ? error.message
                  : 'Record could not be deleted.',
            ),
          ),
        );
      }
    }
  }
}

class HealthRecordFormScreen extends StatefulWidget {
  const HealthRecordFormScreen({
    required this.user,
    required this.pet,
    required this.services,
    super.key,
  });

  final AppUser user;
  final Pet pet;
  final AppServices services;

  @override
  State<HealthRecordFormScreen> createState() => _HealthRecordFormScreenState();
}

class _HealthRecordFormScreenState extends State<HealthRecordFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _diagnosis = TextEditingController();
  final _treatment = TextEditingController();
  final _prescription = TextEditingController();
  final _notes = TextEditingController();
  late HealthRecordType _type;
  DateTime _date = DateTime.now();
  DateTime? _dueDate;
  DateTime? _followUp;
  final List<PickedMedia> _reports = [];
  bool _busy = false;

  bool get _isVet => widget.user.role == UserRole.veterinarian;

  @override
  void initState() {
    super.initState();
    _type = _isVet ? HealthRecordType.medical : HealthRecordType.vaccination;
  }

  @override
  void dispose() {
    _title.dispose();
    _diagnosis.dispose();
    _treatment.dispose();
    _prescription.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ownerTypes = HealthRecordType.values
        .where((type) => type != HealthRecordType.medical)
        .toList();
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: Text('Add ${_isVet ? 'Clinical' : 'Care'} Record')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: AppColors.peachLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${widget.pet.name} · ${widget.pet.breed}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<HealthRecordType>(
              value: _type,
              decoration: InputDecoration(
                labelText: 'Record type',
                helperText: _isVet
                    ? 'Veterinarian entries are protected medical records.'
                    : null,
              ),
              items: (_isVet ? const [HealthRecordType.medical] : ownerTypes)
                  .map(
                    (type) =>
                        DropdownMenuItem(value: type, child: Text(type.label)),
                  )
                  .toList(),
              onChanged: _isVet
                  ? null
                  : (value) => setState(() => _type = value ?? _type),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: _required,
            ),
            if (_isVet) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _diagnosis,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Diagnosis'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _treatment,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Treatment notes'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _prescription,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Prescription'),
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              maxLines: 3,
              maxLength: 1000,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
            const SizedBox(height: 4),
            _DateTile(
              label: 'Record date',
              date: _date,
              onTap: () => _pickDate(_date, (date) => _date = date),
            ),
            _DateTile(
              label: 'Due date',
              date: _dueDate,
              onTap: () => _pickDate(
                _dueDate ?? DateTime.now(),
                (date) => _dueDate = date,
              ),
            ),
            if (_isVet)
              _DateTile(
                label: 'Follow-up date',
                date: _followUp,
                onTap: () => _pickDate(
                  _followUp ?? DateTime.now(),
                  (date) => _followUp = date,
                ),
              ),
            if (_isVet) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickReport,
                icon: const Icon(Icons.attach_file_rounded),
                label: Text(
                  _reports.isEmpty
                      ? 'Attach X-ray, report, or PDF'
                      : '${_reports.length} file(s) selected',
                ),
              ),
            ],
            const SizedBox(height: 16),
            PawButton(
              label: 'Save Protected Record',
              busy: _busy,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(DateTime initial, ValueChanged<DateTime> apply) async {
    final value = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (value != null && mounted) setState(() => apply(value));
  }

  Future<void> _pickReport() async {
    try {
      final file = await MediaPicker.medicalDocument();
      if (file != null && mounted) setState(() => _reports.add(file));
    } on FormatException catch (error) {
      if (mounted) _show(error.message);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      var record = HealthRecord(
        id: '',
        petId: widget.pet.id,
        veterinarianId: _isVet ? widget.user.uid : null,
        type: _type,
        title: _title.text.trim(),
        diagnosis: _diagnosis.text.trim(),
        treatment: _treatment.text.trim(),
        prescription: _prescription.text.trim(),
        notes: _notes.text.trim(),
        date: _date,
        dueDate: _dueDate,
        followUpDate: _followUp,
      );
      final id = await widget.services.care.saveHealthRecord(
        actor: widget.user,
        record: record,
      );
      final paths = <String>[];
      try {
        for (final file in _reports) {
          final media = await widget.services.media.upload(
            path:
                'medical/${widget.pet.id}/$id/${DateTime.now().microsecondsSinceEpoch}_${file.name}',
            bytes: file.bytes,
            contentType: file.contentType,
          );
          paths.add(media.path);
        }
      } on MediaFailure catch (error) {
        for (final path in paths) {
          try {
            await widget.services.media.delete(path);
          } on Object {
            // The unreferenced protected object remains inaccessible.
          }
        }
        if (mounted) {
          _show(
            '${error.message} The clinical record was saved without files.',
          );
          Navigator.pop(context);
        }
        return;
      }
      if (paths.isNotEmpty) {
        record = HealthRecord(
          id: id,
          petId: record.petId,
          veterinarianId: record.veterinarianId,
          type: record.type,
          title: record.title,
          diagnosis: record.diagnosis,
          treatment: record.treatment,
          prescription: record.prescription,
          notes: record.notes,
          date: record.date,
          dueDate: record.dueDate,
          followUpDate: record.followUpDate,
          reportPaths: paths,
        );
        await widget.services.care.saveHealthRecord(
          actor: widget.user,
          record: record,
        );
      }
      if (mounted) Navigator.pop(context);
    } on Object catch (error) {
      if (mounted) {
        _show(
          error is CareFailure
              ? error.message
              : 'Record could not be saved securely.',
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

class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.record,
    required this.onTap,
    required this.onDelete,
    required this.canDelete,
  });
  final HealthRecord record;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool canDelete;

  bool get _clinical =>
      record.type == HealthRecordType.medical || record.veterinarianId != null;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(22),
    child: Ink(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _clinical ? AppColors.mint : _color(record.type),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.surface,
            child: Icon(
              _clinical
                  ? Icons.medical_information_outlined
                  : _icon(record.type),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  '${_clinical ? 'Medical${record.type == HealthRecordType.medical ? '' : ' · ${record.type.label}'}' : record.type.label} · ${DateFormat.yMMMd().format(record.date)}',
                ),
                if (_clinical && record.diagnosis.isNotEmpty) ...[
                  const SizedBox(height: 7),
                  _ClinicalPreview(label: 'Diagnosis', value: record.diagnosis),
                ],
                if (_clinical && record.treatment.isNotEmpty)
                  _ClinicalPreview(label: 'Treatment', value: record.treatment),
                if (_clinical && record.prescription.isNotEmpty)
                  _ClinicalPreview(
                    label: 'Prescription',
                    value: record.prescription,
                  ),
                if (record.dueDate != null)
                  Text(
                    'Due ${DateFormat.yMMMd().format(record.dueDate!)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                if (record.followUpDate != null)
                  Text(
                    'Follow-up ${DateFormat.yMMMd().format(record.followUpDate!)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          if (canDelete)
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded),
            )
          else
            const Icon(Icons.lock_outline_rounded, size: 18),
        ],
      ),
    ),
  );

  Color _color(HealthRecordType type) => switch (type) {
    HealthRecordType.vaccination => AppColors.peachLight,
    HealthRecordType.deworming => AppColors.yellow,
    HealthRecordType.allergy => AppColors.lavender,
    HealthRecordType.medical => AppColors.mint,
  };

  IconData _icon(HealthRecordType type) => switch (type) {
    HealthRecordType.vaccination => Icons.vaccines_outlined,
    HealthRecordType.deworming => Icons.medication_outlined,
    HealthRecordType.allergy => Icons.coronavirus_outlined,
    HealthRecordType.medical => Icons.medical_information_outlined,
  };
}

class _ClinicalPreview extends StatelessWidget {
  const _ClinicalPreview({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 3),
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          TextSpan(text: value),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 12),
    ),
  );
}

class _EmptyRecords extends StatelessWidget {
  const _EmptyRecords({required this.clinical});

  final bool clinical;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(30),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: clinical ? AppColors.mint : AppColors.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              clinical
                  ? Icons.medical_information_outlined
                  : Icons.folder_open_outlined,
              size: 38,
            ),
            const SizedBox(height: 12),
            Text(
              clinical
                  ? 'No clinical medical records yet.'
                  : 'No health records found.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              clinical
                  ? 'Tap Clinical Record to add diagnosis, treatment, prescription, and a follow-up date.'
                  : 'Try another record filter.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
          ],
        ),
      ),
    ),
  );
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.date,
    required this.onTap,
  });
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    contentPadding: EdgeInsets.zero,
    leading: const Icon(Icons.calendar_today_outlined),
    title: Text(label),
    subtitle: Text(date == null ? 'Not set' : DateFormat.yMMMd().format(date!)),
    trailing: const Icon(Icons.edit_calendar_outlined),
  );
}
