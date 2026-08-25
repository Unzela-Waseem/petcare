import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/config/app_services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/paw_button.dart';
import '../../../domain/models/app_user.dart';
import '../../../domain/models/care_models.dart';
import '../../../domain/models/pet.dart';
import '../../../domain/models/user_role.dart';
import '../../../domain/repositories/care_repository.dart';

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({
    required this.user,
    required this.services,
    this.initialPet,
    super.key,
  });

  final AppUser user;
  final AppServices services;
  final Pet? initialPet;

  @override
  Widget build(BuildContext context) {
    final isOwner = user.role == UserRole.petOwner;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(isOwner ? 'Appointments' : "Today's Appointments"),
      ),
      body: StreamBuilder<List<CareAppointment>>(
        stream: services.care.watchAppointments(user),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _center(
              snapshot.error is CareFailure
                  ? (snapshot.error! as CareFailure).message
                  : 'Appointments could not be loaded.',
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final appointments = snapshot.data!;
          if (appointments.isEmpty) {
            return _center(
              isOwner
                  ? 'No appointments yet. Choose an open veterinarian slot to book care.'
                  : 'No patients are scheduled yet.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            itemCount: appointments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _AppointmentCard(
              appointment: appointments[index],
              user: user,
              onStatus: (status) =>
                  _update(context, appointments[index], status),
              onReschedule: () => _openReschedule(context, appointments[index]),
            ),
          );
        },
      ),
      floatingActionButton: isOwner
          ? FloatingActionButton.extended(
              onPressed: () => _openBooking(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Book Visit'),
            )
          : null,
    );
  }

  Widget _center(String message) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Text(message, textAlign: TextAlign.center),
    ),
  );

  Future<void> _openBooking(
    BuildContext context, {
    CareAppointment? existing,
  }) => Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => BookAppointmentScreen(
        owner: user,
        services: services,
        initialPet: initialPet,
        existing: existing,
      ),
    ),
  );

  Future<void> _openReschedule(
    BuildContext context,
    CareAppointment appointment,
  ) => Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => user.role == UserRole.petOwner
          ? BookAppointmentScreen(
              owner: user,
              services: services,
              initialPet: initialPet,
              existing: appointment,
            )
          : VetRescheduleScreen(
              veterinarian: user,
              services: services,
              appointment: appointment,
            ),
    ),
  );

  Future<void> _update(
    BuildContext context,
    CareAppointment appointment,
    AppointmentStatus status,
  ) async {
    try {
      await services.care.updateAppointmentStatus(
        appointment: appointment,
        status: status,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Appointment marked ${status.label.toLowerCase()}.'),
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
                  : 'Appointment could not be updated.',
            ),
          ),
        );
      }
    }
  }
}

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({
    required this.owner,
    required this.services,
    this.initialPet,
    this.existing,
    super.key,
  });

  final AppUser owner;
  final AppServices services;
  final Pet? initialPet;
  final CareAppointment? existing;

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final _reason = TextEditingController();
  Pet? _pet;
  VeterinarianProfile? _veterinarian;
  AvailabilitySlot? _slot;
  String _vetQuery = '';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _pet = widget.initialPet;
    _reason.text = widget.existing?.reason ?? '';
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(
          widget.existing == null ? 'Book Appointment' : 'Reschedule',
        ),
      ),
      body: StreamBuilder<List<Pet>>(
        stream: widget.services.care.watchOwnedPets(widget.owner.uid),
        builder: (context, petSnapshot) {
          if (!petSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final pets = petSnapshot.data!;
          if (pets.isEmpty) {
            return const Center(child: Text('Add a pet profile first.'));
          }
          final selectedPet =
              pets.any((pet) => pet.id == (_pet?.id ?? widget.existing?.petId))
              ? pets.firstWhere(
                  (pet) => pet.id == (_pet?.id ?? widget.existing?.petId),
                )
              : pets.first;
          _pet = selectedPet;
          return StreamBuilder<List<VeterinarianProfile>>(
            stream: widget.services.care.watchVeterinarians(),
            builder: (context, vetSnapshot) {
              if (!vetSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final allVets = vetSnapshot.data!;
              final vetQuery = _vetQuery.trim().toLowerCase();
              final matches = widget.existing == null && vetQuery.isNotEmpty
                  ? allVets.where((vet) {
                      final searchable = [
                        vet.name,
                        vet.clinicName,
                        vet.specialty,
                        vet.location,
                      ].join(' ').toLowerCase();
                      return searchable.contains(vetQuery);
                    }).toList()
                  : allVets;
              if (allVets.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: Text(
                      'No verified veterinarian profiles are available.',
                    ),
                  ),
                );
              }
              final noVetMatch = vetQuery.isNotEmpty && matches.isEmpty;
              final vets = noVetMatch ? allVets : matches;
              final desiredVetId =
                  _veterinarian?.uid ?? widget.existing?.veterinarianId;
              final selectedVet = vets.any((vet) => vet.uid == desiredVetId)
                  ? vets.firstWhere((vet) => vet.uid == desiredVetId)
                  : vets.first;
              _veterinarian = selectedVet;
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedPet.id,
                    decoration: const InputDecoration(labelText: 'Pet'),
                    items: pets
                        .map(
                          (pet) => DropdownMenuItem(
                            value: pet.id,
                            child: Text(pet.name),
                          ),
                        )
                        .toList(),
                    onChanged: widget.existing != null
                        ? null
                        : (id) => setState(() {
                            _pet = pets.firstWhere((pet) => pet.id == id);
                            _slot = null;
                          }),
                  ),
                  const SizedBox(height: 12),
                  if (widget.existing == null) ...[
                    TextField(
                      onChanged: (value) => setState(() {
                        _vetQuery = value;
                        _slot = null;
                      }),
                      decoration: const InputDecoration(
                        labelText: 'Search veterinarians',
                        hintText: 'Name, clinic, specialty, or location',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                    if (noVetMatch)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'No exact match; showing all veterinarians.',
                        ),
                      ),
                    const SizedBox(height: 12),
                  ],
                  DropdownButtonFormField<String>(
                    value: selectedVet.uid,
                    decoration: const InputDecoration(
                      labelText: 'Veterinarian',
                    ),
                    items: vets
                        .map(
                          (vet) => DropdownMenuItem(
                            value: vet.uid,
                            child: Text(
                              '${vet.name}${vet.clinicName.isEmpty ? '' : ' · ${vet.clinicName}'}',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: widget.existing != null
                        ? null
                        : (id) => setState(() {
                            _veterinarian = vets.firstWhere(
                              (vet) => vet.uid == id,
                            );
                            _slot = null;
                          }),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _reason,
                    maxLines: 3,
                    maxLength: 500,
                    decoration: const InputDecoration(
                      labelText: 'Reason for visit',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Available times',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<List<AvailabilitySlot>>(
                    stream: widget.services.care.watchAvailability(
                      veterinarianId: selectedVet.uid,
                    ),
                    builder: (context, slotSnapshot) {
                      if (!slotSnapshot.hasData) {
                        return const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final now = DateTime.now();
                      final slots = slotSnapshot.data!
                          .where(
                            (slot) => !slot.isBooked && slot.start.isAfter(now),
                          )
                          .toList();
                      if (slots.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'This veterinarian has no open future slots.',
                          ),
                        );
                      }
                      return Column(
                        children: slots
                            .map(
                              (slot) => ListTile(
                                selected: _slot?.id == slot.id,
                                selectedTileColor: AppColors.peachLight,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                onTap: () => setState(() => _slot = slot),
                                leading: Icon(
                                  _slot?.id == slot.id
                                      ? Icons.radio_button_checked_rounded
                                      : Icons.radio_button_off_rounded,
                                ),
                                title: Text(
                                  DateFormat(
                                    'EEE, d MMM · h:mm a',
                                  ).format(slot.start),
                                ),
                                subtitle: Text(
                                  '${slot.end.difference(slot.start).inMinutes} minutes',
                                ),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  PawButton(
                    label: widget.existing == null
                        ? 'Book Securely'
                        : 'Confirm New Time',
                    busy: _busy,
                    onPressed: _submit,
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _submit() async {
    final pet = _pet;
    final vet = _veterinarian;
    final slot = _slot;
    if (pet == null ||
        vet == null ||
        slot == null ||
        _reason.text.trim().isEmpty) {
      _show('Select a pet, veterinarian, open time, and visit reason.');
      return;
    }
    setState(() => _busy = true);
    try {
      if (widget.existing == null) {
        await widget.services.care.bookAppointment(
          owner: widget.owner,
          pet: pet,
          veterinarian: vet,
          slot: slot,
          reason: _reason.text,
        );
      } else {
        await widget.services.care.rescheduleAppointment(
          actor: widget.owner,
          appointment: widget.existing!,
          newSlot: slot,
        );
      }
      if (mounted) Navigator.pop(context);
    } on Object catch (error) {
      if (mounted) {
        _show(
          error is CareFailure
              ? error.message
              : 'The appointment could not be booked.',
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

class VetRescheduleScreen extends StatefulWidget {
  const VetRescheduleScreen({
    required this.veterinarian,
    required this.services,
    required this.appointment,
    super.key,
  });

  final AppUser veterinarian;
  final AppServices services;
  final CareAppointment appointment;

  @override
  State<VetRescheduleScreen> createState() => _VetRescheduleScreenState();
}

class _VetRescheduleScreenState extends State<VetRescheduleScreen> {
  AvailabilitySlot? _selected;
  bool _busy = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.cream,
    appBar: AppBar(title: const Text('Reschedule Appointment')),
    body: StreamBuilder<List<AvailabilitySlot>>(
      stream: widget.services.care.watchAvailability(
        veterinarianId: widget.veterinarian.uid,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final now = DateTime.now();
        final slots = snapshot.data!
            .where((slot) => !slot.isBooked && slot.start.isAfter(now))
            .toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Text(
              '${widget.appointment.petName} · ${widget.appointment.reason}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'Current: ${DateFormat('EEE, d MMM · h:mm a').format(widget.appointment.dateTime)}',
            ),
            const SizedBox(height: 18),
            Text(
              'Choose one of your open times',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (slots.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Text(
                  'No open future slots. Add availability from your calendar first.',
                ),
              )
            else
              ...slots.map(
                (slot) => ListTile(
                  selected: _selected?.id == slot.id,
                  selectedTileColor: AppColors.peachLight,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  leading: Icon(
                    _selected?.id == slot.id
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                  ),
                  title: Text(
                    DateFormat('EEE, d MMM · h:mm a').format(slot.start),
                  ),
                  subtitle: Text(
                    '${slot.end.difference(slot.start).inMinutes} minutes',
                  ),
                  onTap: () => setState(() => _selected = slot),
                ),
              ),
            const SizedBox(height: 18),
            PawButton(
              label: 'Confirm New Time',
              busy: _busy,
              onPressed: slots.isEmpty ? null : _submit,
            ),
          ],
        );
      },
    ),
  );

  Future<void> _submit() async {
    final slot = _selected;
    if (slot == null) {
      _show('Choose an open time first.');
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.services.care.rescheduleAppointment(
        actor: widget.veterinarian,
        appointment: widget.appointment,
        newSlot: slot,
      );
      if (mounted) Navigator.pop(context);
    } on Object catch (error) {
      if (mounted) {
        _show(
          error is CareFailure
              ? error.message
              : 'The appointment could not be rescheduled.',
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

class AvailabilityScreen extends StatelessWidget {
  const AvailabilityScreen({
    required this.user,
    required this.services,
    super.key,
  });
  final AppUser user;
  final AppServices services;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.cream,
    appBar: AppBar(title: const Text('Availability Calendar')),
    body: StreamBuilder<List<AvailabilitySlot>>(
      stream: services.care.watchAvailability(veterinarianId: user.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final slots = snapshot.data!;
        if (slots.isEmpty) {
          return const Center(child: Text('Add your first appointment slot.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          itemCount: slots.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final slot = slots[index];
            return ListTile(
              tileColor: slot.isBooked ? AppColors.lavender : AppColors.mint,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              leading: Icon(
                slot.isBooked
                    ? Icons.event_busy_outlined
                    : Icons.event_available_outlined,
              ),
              title: Text(DateFormat('EEE, d MMM · h:mm a').format(slot.start)),
              subtitle: Text(slot.isBooked ? 'Booked' : 'Open'),
              trailing: slot.isBooked
                  ? const Icon(Icons.lock_outline_rounded)
                  : IconButton(
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: () => services.care.deleteAvailability(slot),
                    ),
            );
          },
        );
      },
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => _AvailabilityForm(user: user, services: services),
      ),
      icon: const Icon(Icons.add_rounded),
      label: const Text('Add Slot'),
    ),
  );
}

class _AvailabilityForm extends StatefulWidget {
  const _AvailabilityForm({required this.user, required this.services});
  final AppUser user;
  final AppServices services;

  @override
  State<_AvailabilityForm> createState() => _AvailabilityFormState();
}

class _AvailabilityFormState extends State<_AvailabilityForm> {
  DateTime _start = DateTime.now().add(const Duration(days: 1));
  int _minutes = 30;
  bool _busy = false;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'New availability',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          ListTile(
            onTap: _pickDateTime,
            tileColor: AppColors.cream,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            leading: const Icon(Icons.schedule_outlined),
            title: const Text('Starts'),
            subtitle: Text(
              DateFormat('EEE, d MMM yyyy · h:mm a').format(_start),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: _minutes,
            decoration: const InputDecoration(labelText: 'Duration'),
            items: const [20, 30, 45, 60]
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text('$value minutes'),
                  ),
                )
                .toList(),
            onChanged: (value) => _minutes = value ?? _minutes,
          ),
          const SizedBox(height: 18),
          PawButton(label: 'Publish Open Slot', busy: _busy, onPressed: _save),
        ],
      ),
    ),
  );

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_start),
    );
    if (time == null || !mounted) return;
    setState(
      () => _start = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ),
    );
  }

  Future<void> _save() async {
    if (!_start.isAfter(DateTime.now())) {
      _show('Availability must be in the future.');
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.services.care.createAvailability(
        veterinarianId: widget.user.uid,
        start: _start,
        end: _start.add(Duration(minutes: _minutes)),
      );
      if (mounted) Navigator.pop(context);
    } on Object catch (error) {
      if (mounted) {
        _show(
          error is CareFailure
              ? error.message
              : 'Availability could not be saved.',
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

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.appointment,
    required this.user,
    required this.onStatus,
    required this.onReschedule,
  });
  final CareAppointment appointment;
  final AppUser user;
  final ValueChanged<AppointmentStatus> onStatus;
  final VoidCallback onReschedule;

  @override
  Widget build(BuildContext context) {
    final isOwner = user.role == UserRole.petOwner;
    final closed =
        appointment.status == AppointmentStatus.cancelled ||
        appointment.status == AppointmentStatus.completed;
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: _statusColor(appointment.status),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppColors.surface,
                child: Icon(Icons.medical_services_outlined),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.petName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(appointment.veterinarianName),
                  ],
                ),
              ),
              Chip(label: Text(appointment.status.label)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            DateFormat(
              'EEEE, d MMM yyyy · h:mm a',
            ).format(appointment.dateTime),
          ),
          const SizedBox(height: 4),
          Text(appointment.reason),
          if (!closed) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: isOwner
                  ? [
                      OutlinedButton(
                        onPressed: onReschedule,
                        child: const Text('Reschedule'),
                      ),
                      OutlinedButton(
                        onPressed: () => onStatus(AppointmentStatus.cancelled),
                        child: const Text('Cancel'),
                      ),
                    ]
                  : [
                      OutlinedButton(
                        onPressed: onReschedule,
                        child: const Text('Reschedule'),
                      ),
                      if (appointment.status == AppointmentStatus.pending)
                        FilledButton(
                          onPressed: () =>
                              onStatus(AppointmentStatus.confirmed),
                          child: const Text('Confirm'),
                        ),
                      if (appointment.status == AppointmentStatus.confirmed)
                        FilledButton(
                          onPressed: () =>
                              onStatus(AppointmentStatus.completed),
                          child: const Text('Complete'),
                        ),
                      OutlinedButton(
                        onPressed: () => onStatus(AppointmentStatus.cancelled),
                        child: const Text('Cancel'),
                      ),
                    ],
            ),
          ],
        ],
      ),
    );
  }

  Color _statusColor(AppointmentStatus status) => switch (status) {
    AppointmentStatus.pending => AppColors.yellow,
    AppointmentStatus.confirmed => AppColors.mint,
    AppointmentStatus.completed => AppColors.peachLight,
    AppointmentStatus.cancelled => AppColors.lavender,
  };
}
