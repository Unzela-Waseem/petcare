import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/config/app_services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/app_user.dart';
import '../../../domain/models/care_models.dart';
import '../../../domain/models/pet.dart';
import '../../../domain/models/user_role.dart';
import '../../../domain/repositories/care_repository.dart';

class PatientHistoryScreen extends StatefulWidget {
  const PatientHistoryScreen({
    required this.user,
    required this.services,
    super.key,
  });

  final AppUser user;
  final AppServices services;

  @override
  State<PatientHistoryScreen> createState() => _PatientHistoryScreenState();
}

class _PatientHistoryScreenState extends State<PatientHistoryScreen> {
  Pet? _selectedPet;
  _HistoryFilter _filter = _HistoryFilter.all;

  @override
  Widget build(BuildContext context) {
    final pets = widget.user.role == UserRole.veterinarian
        ? widget.services.care.watchAssignedPets(widget.user.uid)
        : widget.services.care.watchOwnedPets(widget.user.uid);
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Patient History'),
        backgroundColor: AppColors.cream,
      ),
      body: StreamBuilder<List<Pet>>(
        stream: pets,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _message(
              snapshot.error is CareFailure
                  ? (snapshot.error! as CareFailure).message
                  : 'The protected patient history could not be loaded.',
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final authorizedPets = snapshot.data!;
          if (authorizedPets.isEmpty) {
            return _message('No assigned patients are available.');
          }
          final selected =
              authorizedPets.any((pet) => pet.id == _selectedPet?.id)
              ? authorizedPets.firstWhere((pet) => pet.id == _selectedPet!.id)
              : authorizedPets.first;
          _selectedPet = selected;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                child: DropdownButtonFormField<String>(
                  value: selected.id,
                  decoration: const InputDecoration(
                    labelText: 'Patient',
                    prefixIcon: Icon(Icons.pets_outlined),
                  ),
                  items: authorizedPets
                      .map(
                        (pet) => DropdownMenuItem(
                          value: pet.id,
                          child: Text('${pet.name} · ${pet.breed}'),
                        ),
                      )
                      .toList(),
                  onChanged: (id) => setState(
                    () => _selectedPet = authorizedPets.firstWhere(
                      (pet) => pet.id == id,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: AppColors.lavender,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.history_rounded),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Read-only timeline of visits and care records.',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: _HistoryFilter.values.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final filter = _HistoryFilter.values[index];
                    return ChoiceChip(
                      label: Text(filter.label),
                      selected: _filter == filter,
                      onSelected: (_) => setState(() => _filter = filter),
                    );
                  },
                ),
              ),
              Expanded(
                child: _Timeline(
                  user: widget.user,
                  services: widget.services,
                  pet: selected,
                  filter: _filter,
                  onOpen: _openEntry,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _message(String text) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Text(text, textAlign: TextAlign.center),
    ),
  );

  void _openEntry(_HistoryEntry entry) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: entry.color,
                    child: Icon(entry.icon, color: AppColors.ink),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          '${entry.label} · ${DateFormat.yMMMd().format(entry.date)}',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              for (final detail in entry.details)
                if (detail.value.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    detail.key,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(detail.value),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({
    required this.user,
    required this.services,
    required this.pet,
    required this.filter,
    required this.onOpen,
  });

  final AppUser user;
  final AppServices services;
  final Pet pet;
  final _HistoryFilter filter;
  final ValueChanged<_HistoryEntry> onOpen;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CareAppointment>>(
      stream: services.care.watchAppointments(user),
      builder: (context, appointmentSnapshot) {
        if (appointmentSnapshot.hasError) {
          return _error('Visit history could not be loaded.');
        }
        if (!appointmentSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return StreamBuilder<List<HealthRecord>>(
          stream: services.care.watchHealthRecords(pet.id),
          builder: (context, recordSnapshot) {
            if (recordSnapshot.hasError) {
              return _error('Care history could not be loaded.');
            }
            if (!recordSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final appointments = appointmentSnapshot.data!
                .where((appointment) => appointment.petId == pet.id)
                .toList();
            final records = recordSnapshot.data!;
            final entries = <_HistoryEntry>[
              if (filter != _HistoryFilter.records)
                ...appointments.map(_appointmentEntry),
              if (filter != _HistoryFilter.visits) ...records.map(_recordEntry),
            ]..sort((a, b) => b.date.compareTo(a.date));
            if (entries.isEmpty) {
              return _error(
                filter == _HistoryFilter.all
                    ? 'No patient history has been recorded yet.'
                    : 'No ${filter.label.toLowerCase()} found.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final entry = entries[index];
                return InkWell(
                  onTap: () => onOpen(entry),
                  borderRadius: BorderRadius.circular(22),
                  child: Ink(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: entry.color,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.white.withValues(alpha: 0.8),
                          child: Icon(entry.icon, color: AppColors.ink),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.label,
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                entry.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (entry.summary.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  entry.summary,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 5),
                              Text(
                                DateFormat.yMMMd().add_jm().format(entry.date),
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _error(String text) => Center(
    child: Padding(
      padding: const EdgeInsets.all(30),
      child: Text(text, textAlign: TextAlign.center),
    ),
  );

  _HistoryEntry _appointmentEntry(CareAppointment appointment) {
    final reason = appointment.reason.trim();
    return _HistoryEntry(
      date: appointment.dateTime,
      label: 'Visit · ${appointment.status.label}',
      title: reason.isEmpty ? 'Veterinary appointment' : reason,
      summary: 'With ${appointment.veterinarianName}',
      icon: Icons.event_available_outlined,
      color: _statusColor(appointment.status),
      details: [
        MapEntry('Status', appointment.status.label),
        MapEntry('Reason for visit', reason),
        MapEntry('Veterinarian', appointment.veterinarianName),
        MapEntry(
          'Appointment time',
          DateFormat.yMMMMd().add_jm().format(appointment.dateTime),
        ),
      ],
    );
  }

  _HistoryEntry _recordEntry(HealthRecord record) {
    final summary = [
      record.diagnosis,
      record.treatment,
      record.notes,
    ].firstWhere((value) => value.trim().isNotEmpty, orElse: () => '');
    return _HistoryEntry(
      date: record.date,
      label: record.type.label,
      title: record.title,
      summary: summary,
      icon: _recordIcon(record.type),
      color: _recordColor(record.type),
      details: [
        MapEntry('Diagnosis', record.diagnosis),
        MapEntry('Treatment', record.treatment),
        MapEntry('Prescription', record.prescription),
        MapEntry('Notes', record.notes),
        MapEntry(
          'Due date',
          record.dueDate == null
              ? ''
              : DateFormat.yMMMMd().format(record.dueDate!),
        ),
        MapEntry(
          'Follow-up date',
          record.followUpDate == null
              ? ''
              : DateFormat.yMMMMd().format(record.followUpDate!),
        ),
      ],
    );
  }

  Color _statusColor(AppointmentStatus status) => switch (status) {
    AppointmentStatus.pending => AppColors.yellow,
    AppointmentStatus.confirmed => AppColors.mint,
    AppointmentStatus.completed => AppColors.lavender,
    AppointmentStatus.cancelled => AppColors.peachLight,
  };

  Color _recordColor(HealthRecordType type) => switch (type) {
    HealthRecordType.vaccination => AppColors.peachLight,
    HealthRecordType.deworming => AppColors.yellow,
    HealthRecordType.allergy => AppColors.lavender,
    HealthRecordType.medical => AppColors.mint,
  };

  IconData _recordIcon(HealthRecordType type) => switch (type) {
    HealthRecordType.vaccination => Icons.vaccines_outlined,
    HealthRecordType.deworming => Icons.medication_outlined,
    HealthRecordType.allergy => Icons.coronavirus_outlined,
    HealthRecordType.medical => Icons.medical_information_outlined,
  };
}

enum _HistoryFilter {
  all('All activity'),
  visits('Visits'),
  records('Care records');

  const _HistoryFilter(this.label);
  final String label;
}

class _HistoryEntry {
  const _HistoryEntry({
    required this.date,
    required this.label,
    required this.title,
    required this.summary,
    required this.icon,
    required this.color,
    required this.details,
  });

  final DateTime date;
  final String label;
  final String title;
  final String summary;
  final IconData icon;
  final Color color;
  final List<MapEntry<String, String>> details;
}
