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
  LocalReminderService({
    FlutterLocalNotificationsPlugin? notifications,
  }) : _notifications =
            notifications ?? FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel =
      AndroidNotificationChannel(
    'pawfectcare_reminders',
    'PawfectCare reminders',
    description:
        'Appointment, vaccination, and follow-up reminders',
    importance: Importance.high,
  );

  static const NotificationDetails _details =
      NotificationDetails(
    android: AndroidNotificationDetails(
      'pawfectcare_reminders',
      'PawfectCare reminders',
      channelDescription:
          'Appointment, vaccination, and follow-up reminders',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
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

  StreamSubscription<List<CareAppointment>>?
      _appointmentSubscription;

  StreamSubscription<Map<String, bool>>?
      _preferenceSubscription;

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
      // Initialize timezone database.
      tz_data.initializeTimeZones();

      // Use the device's local timezone.
      tz.setLocalLocation(
        tz.getLocation('Asia/Karachi'),
      );

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        settings,
      );

      // Create Android notification channel.
      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);

      _initialized = true;
    } catch (e) {
      debugPrint(
        'LocalReminderService initialization failed: $e',
      );

      _initialized = false;
    }
  }

  @override
  Future<void> start({
    required AppUser user,
    required CareRepository care,
  }) async {
    await stop();

    if (!_initialized) {
      debugPrint(
        'LocalReminderService is not initialized.',
      );
      return;
    }

    _user = user;

    try {
      await _requestPermission();
    } catch (e) {
      debugPrint(
        'Notification permission error: $e',
      );
    }

    _preferenceSubscription = care
        .watchNotificationPreferences(user.uid)
        .listen(
      (preferences) {
        _preferences = preferences;
        _requestSync();
      },
      onError: (error) {
        debugPrint(
          'Notification preference error: $error',
        );
      },
    );

    if (user.role != UserRole.shelterAdmin) {
      _appointmentSubscription = care
          .watchAppointments(user)
          .listen(
        (items) {
          _appointments = items;
          _requestSync();
        },
        onError: (error) {
          debugPrint(
            'Appointment stream error: $error',
          );
        },
      );
    }

    final petStream = switch (user.role) {
      UserRole.petOwner =>
        care.watchOwnedPets(user.uid),
      UserRole.veterinarian =>
        care.watchAssignedPets(user.uid),
      UserRole.shelterAdmin => null,
    };

    if (petStream != null) {
      _petSubscription = petStream.listen(
        (pets) {
          unawaited(
            _replacePetSubscriptions(
              pets,
              care,
            ).catchError(
              (Object error) {
                debugPrint(
                  'Pet subscription error: $error',
                );
              },
            ),
          );
        },
        onError: (error) {
          debugPrint(
            'Pet stream error: $error',
          );
        },
      );
    }

    // Run an initial sync immediately.
    _requestSync();
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

    for (final subscription
        in _healthSubscriptions.values) {
      await subscription.cancel();
    }

    _healthSubscriptions.clear();
    _pets.clear();
    _healthRecords.clear();

    _appointments = const [];

    await _syncFuture;

    if (_initialized) {
      await _notifications.cancelAll();
    }
  }

  Future<void> _requestPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await android?.requestNotificationsPermission();
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();

      await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  Future<void> _replacePetSubscriptions(
    List<Pet> pets,
    CareRepository care,
  ) async {
    final incomingIds =
        pets.map((pet) => pet.id).toSet();

    final removedIds = _healthSubscriptions.keys
        .where(
          (id) => !incomingIds.contains(id),
        )
        .toList();

    for (final id in removedIds) {
      await _healthSubscriptions
          .remove(id)
          ?.cancel();

      _healthRecords.remove(id);
      _pets.remove(id);
    }

    for (final pet in pets) {
      _pets[pet.id] = pet;

      if (_healthSubscriptions.containsKey(
        pet.id,
      )) {
        continue;
      }

      _healthSubscriptions[pet.id] =
          care.watchHealthRecords(pet.id).listen(
        (records) {
          _healthRecords[pet.id] = records;
          _requestSync();
        },
        onError: (error) {
          debugPrint(
            'Health record stream error: $error',
          );
        },
      );
    }

    _requestSync();
  }

  void _requestSync() {
    _syncFuture = _syncFuture
        .then(
          (_) => _synchronizeNotifications(),
        )
        .catchError(
          (Object error) {
            debugPrint(
              'Reminder synchronization error: $error',
            );
          },
        );
  }

  Future<void> _synchronizeNotifications() async {
    if (!_initialized) {
      debugPrint(
        'Cannot sync reminders: service not initialized.',
      );
      return;
    }

    await _notifications.cancelAll();

    final user = _user;

    if (user == null) {
      debugPrint(
        'Cannot sync reminders: no logged-in user.',
      );
      return;
    }

    final now = DateTime.now();

    final reminders = <_ReminderCandidate>[];

    // Appointment reminders.
    if (_preferences['appointments'] != false) {
      for (final appointment in _appointments) {
        if (appointment.dateTime.isBefore(now) ||
            appointment.status ==
                AppointmentStatus.cancelled ||
            appointment.status ==
                AppointmentStatus.completed) {
          continue;
        }

        reminders.add(
          _ReminderCandidate(
            key:
                '${user.uid}:appointment:${appointment.id}',
            title: 'Upcoming appointment',
            body:
                '${appointment.petName} has a visit with ${appointment.veterinarianName}.',
            when: _reminderTime(
              target: appointment.dateTime,
              before: const Duration(hours: 24),
              now: now,
            ),
            payload:
                'appointment:${appointment.id}',
          ),
        );
      }
    }

    // Vaccination / health reminders.
    if (_preferences['vaccinations'] != false) {
      for (final entry in _healthRecords.entries) {
        final pet = _pets[entry.key];

        if (pet == null) {
          continue;
        }

        for (final record in entry.value) {
          final dueDate = record.dueDate;

          if (dueDate != null &&
              (record.type ==
                      HealthRecordType.vaccination ||
                  record.type ==
                      HealthRecordType.deworming)) {
            final target = DateTime(
              dueDate.year,
              dueDate.month,
              dueDate.day,
              9,
            );

            if (target.isAfter(now)) {
              reminders.add(
                _ReminderCandidate(
                  key:
                      '${user.uid}:health:${record.id}:due',
                  title:
                      '${record.type.label} due soon',
                  body:
                      '${pet.name}: ${record.title}',
                  when: _reminderTime(
                    target: target,
                    before: const Duration(days: 7),
                    now: now,
                  ),
                  payload:
                      'health:${pet.id}:${record.id}',
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
                  key:
                      '${user.uid}:health:${record.id}:follow-up',
                  title: 'Clinical follow-up due',
                  body:
                      '${pet.name}: ${record.title}',
                  when: _reminderTime(
                    target: target,
                    before: const Duration(days: 1),
                    now: now,
                  ),
                  payload:
                      'health:${pet.id}:${record.id}',
                ),
              );
            }
          }
        }
      }
    }

    reminders.sort(
      (a, b) => a.when.compareTo(b.when),
    );

    for (final reminder
        in reminders.take(50)) {
      if (_user?.uid != user.uid) {
        return;
      }

      // Convert the reminder to the device's local timezone.
      final scheduledDate =
          tz.TZDateTime.from(
        reminder.when,
        tz.local,
      );

      debugPrint(
        'Scheduling reminder: '
        '${reminder.title} '
        'at $scheduledDate',
      );

      await _notifications.zonedSchedule(
        notificationId(reminder.key),
        reminder.title,
        reminder.body,
        scheduledDate,
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: reminder.payload,
      );
    }

    debugPrint(
      'Total reminders scheduled: ${reminders.length}',
    );
  }
}

DateTime _reminderTime({
  required DateTime target,
  required Duration before,
  required DateTime now,
}) {
  final planned = target.subtract(before);

  // For testing / already-near reminders:
  // trigger 10 seconds from now.
  if (!planned.isAfter(now)) {
    return now.add(
      const Duration(seconds: 10),
    );
  }

  return planned;
}

int notificationId(String value) {
  var hash = 0x811c9dc5;

  for (final codeUnit in value.codeUnits) {
    hash ^= codeUnit;
    hash =
        (hash * 0x01000193) & 0x7fffffff;
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