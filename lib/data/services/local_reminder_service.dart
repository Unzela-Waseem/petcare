import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/models/app_user.dart';
import '../../domain/models/care_models.dart';
import '../../domain/models/pet.dart';
import '../../domain/models/user_role.dart';
import '../../domain/repositories/care_repository.dart';
import '../../domain/repositories/reminder_service.dart';

class LocalReminderService implements ReminderService {
  LocalReminderService({FlutterLocalNotificationsPlugin? notifications})
    : _notifications = notifications ?? FlutterLocalNotificationsPlugin();

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'pawfectcare_reminders',
      'PawfectCare reminders',
      channelDescription: 'Appointment, vaccination, and follow-up reminders',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  final FlutterLocalNotificationsPlugin _notifications;
  bool _initialized = false;
  AppUser? _user;
  List<CareAppointment> _appointments = const [];
  Map<String, bool> _preferences = const {
    'appointments': true,
    'vaccinations': true,
  };
  final Map<String, Pet> _pets = {};
  final Map<String, List<HealthRecord>> _healthRecords = {};
  final Map<String, StreamSubscription<List<HealthRecord>>>
  _healthSubscriptions = {};
  StreamSubscription<List<CareAppointment>>? _appointmentSubscription;
  StreamSubscription<Map<String, bool>>? _preferenceSubscription;
  StreamSubscription<List<Pet>>? _petSubscription;
  Future<void> _syncFuture = Future<void>.value();

  @override
  Future<void> initialize() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return;
    }
    try {
      tz_data.initializeTimeZones();
      await _notifications.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      _initialized = true;
    } on Object {
      _initialized = false;
    }
  }

  @override
  Future<void> start({
    required AppUser user,
    required CareRepository care,
  }) async {
    await stop();
    if (!_initialized) return;
    _user = user;
    try {
      await _requestPermission();
    } on Object {
      return;
    }

    _preferenceSubscription = care
        .watchNotificationPreferences(user.uid)
        .listen((preferences) {
          _preferences = preferences;
          _requestSync();
        }, onError: (_) {});
    if (user.role != UserRole.shelterAdmin) {
      _appointmentSubscription = care.watchAppointments(user).listen((items) {
        _appointments = items;
        _requestSync();
      }, onError: (_) {});
    }

    final petStream = switch (user.role) {
      UserRole.petOwner => care.watchOwnedPets(user.uid),
      UserRole.veterinarian => care.watchAssignedPets(user.uid),
      UserRole.shelterAdmin => null,
    };
    if (petStream != null) {
      _petSubscription = petStream.listen(
        (pets) => unawaited(
          _replacePetSubscriptions(pets, care).catchError((Object _) {}),
        ),
        onError: (_) {},
      );
    }
  }

  @override
  Future<void> stop() async {
    _user = null;
    await _appointmentSubscription?.cancel();
    await _preferenceSubscription?.cancel();
    await _petSubscription?.cancel();
    _appointmentSubscription = null;
    _preferenceSubscription = null;
    _petSubscription = null;
    for (final subscription in _healthSubscriptions.values) {
      await subscription.cancel();
    }
    _healthSubscriptions.clear();
    _pets.clear();
    _healthRecords.clear();
    _appointments = const [];
    await _syncFuture;
    if (_initialized) await _notifications.cancelAll();
  }

  Future<void> _requestPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  Future<void> _replacePetSubscriptions(
    List<Pet> pets,
    CareRepository care,
  ) async {
    final incomingIds = pets.map((pet) => pet.id).toSet();
    final removedIds = _healthSubscriptions.keys
        .where((id) => !incomingIds.contains(id))
        .toList();
    for (final id in removedIds) {
      await _healthSubscriptions.remove(id)?.cancel();
      _healthRecords.remove(id);
      _pets.remove(id);
    }
    for (final pet in pets) {
      _pets[pet.id] = pet;
      if (_healthSubscriptions.containsKey(pet.id)) continue;
      _healthSubscriptions[pet.id] = care.watchHealthRecords(pet.id).listen((
        records,
      ) {
        _healthRecords[pet.id] = records;
        _requestSync();
      }, onError: (_) {});
    }
    _requestSync();
  }

  void _requestSync() {
    _syncFuture = _syncFuture
        .then((_) => _synchronizeNotifications())
        .catchError((Object _) {
          // Local reminders must never interrupt the authenticated app flow.
        });
  }

  Future<void> _synchronizeNotifications() async {
    if (!_initialized) return;
    await _notifications.cancelAll();
    final user = _user;
    if (user == null) return;

    final now = DateTime.now();
    final reminders = <_ReminderCandidate>[];
    if (_preferences['appointments'] != false) {
      for (final appointment in _appointments) {
        if (appointment.dateTime.isBefore(now) ||
            appointment.status == AppointmentStatus.cancelled ||
            appointment.status == AppointmentStatus.completed) {
          continue;
        }
        reminders.add(
          _ReminderCandidate(
            key: '${user.uid}:appointment:${appointment.id}',
            title: 'Upcoming appointment',
            body:
                '${appointment.petName} has a visit with ${appointment.veterinarianName}.',
            when: _reminderTime(
              target: appointment.dateTime,
              before: const Duration(hours: 24),
              now: now,
            ),
            payload: 'appointment:${appointment.id}',
          ),
        );
      }
    }

    if (_preferences['vaccinations'] != false) {
      for (final entry in _healthRecords.entries) {
        final pet = _pets[entry.key];
        if (pet == null) continue;
        for (final record in entry.value) {
          final dueDate = record.dueDate;
          if (dueDate != null &&
              (record.type == HealthRecordType.vaccination ||
                  record.type == HealthRecordType.deworming)) {
            final target = DateTime(
              dueDate.year,
              dueDate.month,
              dueDate.day,
              9,
            );
            if (target.isAfter(now)) {
              reminders.add(
                _ReminderCandidate(
                  key: '${user.uid}:health:${record.id}:due',
                  title: '${record.type.label} due soon',
                  body: '${pet.name}: ${record.title}',
                  when: _reminderTime(
                    target: target,
                    before: const Duration(days: 7),
                    now: now,
                  ),
                  payload: 'health:${pet.id}:${record.id}',
                ),
              );
            }
          }
          final followUp = record.followUpDate;
          if (followUp != null) {
            final target = DateTime(
              followUp.year,
              followUp.month,
              followUp.day,
              9,
            );
            if (target.isAfter(now)) {
              reminders.add(
                _ReminderCandidate(
                  key: '${user.uid}:health:${record.id}:follow-up',
                  title: 'Clinical follow-up due',
                  body: '${pet.name}: ${record.title}',
                  when: _reminderTime(
                    target: target,
                    before: const Duration(days: 1),
                    now: now,
                  ),
                  payload: 'health:${pet.id}:${record.id}',
                ),
              );
            }
          }
        }
      }
    }

    reminders.sort((a, b) => a.when.compareTo(b.when));
    for (final reminder in reminders.take(50)) {
      if (_user?.uid != user.uid) return;
      await _notifications.zonedSchedule(
        id: notificationId(reminder.key),
        title: reminder.title,
        body: reminder.body,
        scheduledDate: tz.TZDateTime.from(reminder.when.toUtc(), tz.UTC),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: reminder.payload,
      );
    }
  }
}

DateTime _reminderTime({
  required DateTime target,
  required Duration before,
  required DateTime now,
}) {
  final planned = target.subtract(before);
  return planned.isAfter(now) ? planned : now.add(const Duration(seconds: 10));
}

int notificationId(String value) {
  var hash = 0x811c9dc5;
  for (final codeUnit in value.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x01000193) & 0x7fffffff;
  }
  return hash == 0 ? 1 : hash;
}

class _ReminderCandidate {
  const _ReminderCandidate({
    required this.key,
    required this.title,
    required this.body,
    required this.when,
    required this.payload,
  });

  final String key;
  final String title;
  final String body;
  final DateTime when;
  final String payload;
}
