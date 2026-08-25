import 'package:flutter_test/flutter_test.dart';
import 'package:pawfect_care/data/services/activity_notification_builder.dart';
import 'package:pawfect_care/domain/models/app_user.dart';
import 'package:pawfect_care/domain/models/care_models.dart';
import 'package:pawfect_care/domain/models/pet.dart';
import 'package:pawfect_care/domain/models/user_role.dart';

void main() {
  const owner = AppUser(
    uid: 'owner-1',
    name: 'Jamie',
    email: 'jamie@example.com',
    phone: '+1 555 0100',
    role: UserRole.petOwner,
    emailVerified: true,
  );
  const pet = Pet(
    id: 'pet-1',
    ownerId: 'owner-1',
    name: 'Luna',
    species: 'Dog',
    breed: 'Husky',
    age: 3,
    gender: 'Female',
  );

  test('free-plan activity feed covers every notification requirement', () {
    final notifications = buildActivityNotifications(
      user: owner,
      appointments: [
        CareAppointment(
          id: 'appointment-1',
          slotId: 'slot-1',
          petId: pet.id,
          petName: pet.name,
          ownerId: owner.uid,
          veterinarianId: 'vet-1',
          veterinarianName: 'Dr Morgan',
          dateTime: DateTime(2026, 8, 28, 10),
          reason: 'Wellness visit',
          status: AppointmentStatus.confirmed,
        ),
      ],
      adoptionRequests: [
        AdoptionRequest(
          id: 'request-1',
          listingId: 'listing-1',
          petName: 'Milo',
          ownerId: owner.uid,
          ownerName: owner.name,
          shelterId: 'shelter-1',
          shelterAdminId: 'admin-1',
          status: RequestStatus.approved,
          message: 'A safe family home.',
          createdAt: DateTime(2026, 8, 24),
        ),
      ],
      blogs: [
        BlogArticle(
          id: 'guide-1',
          title: 'Hydration and warning signs',
          category: 'Nutrition',
          summary: 'Healthy hydration.',
          content: 'Provide clean water.',
          publishedAt: DateTime(2026, 8, 23),
        ),
      ],
      pets: const [pet],
      healthRecords: {
        pet.id: [
          HealthRecord(
            id: 'record-1',
            petId: pet.id,
            type: HealthRecordType.vaccination,
            title: 'Annual booster',
            date: DateTime(2025, 8, 30),
            dueDate: DateTime(2026, 8, 30),
          ),
        ],
      },
      readIds: const {},
      now: DateTime(2026, 8, 25),
    );

    expect(notifications.map((item) => item.type), contains('appointment'));
    expect(notifications.map((item) => item.type), contains('adoption'));
    expect(notifications.map((item) => item.type), contains('blog'));
    expect(notifications.map((item) => item.type), contains('vaccination'));
    expect(notifications.every((item) => item.readAt == null), isTrue);
  });

  test('derived activity IDs support local read state', () {
    const notificationId = '${activityNotificationPrefix}blog:guide-1';
    final notifications = buildActivityNotifications(
      user: owner,
      appointments: const [],
      adoptionRequests: const [],
      blogs: [
        BlogArticle(
          id: 'guide-1',
          title: 'Daily care',
          category: 'Pet Care',
          summary: 'A care routine.',
          content: 'Observe daily changes.',
          publishedAt: DateTime(2026, 8, 23),
        ),
      ],
      pets: const [],
      healthRecords: const {},
      readIds: const {notificationId},
      now: DateTime(2026, 8, 25),
    );

    expect(notifications.single.id, notificationId);
    expect(notifications.single.readAt, isNotNull);
  });
}
