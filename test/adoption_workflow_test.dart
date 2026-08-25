import 'package:flutter_test/flutter_test.dart';
import 'package:pawfect_care/data/repositories/demo_care_repository.dart';
import 'package:pawfect_care/domain/models/app_user.dart';
import 'package:pawfect_care/domain/models/care_models.dart';
import 'package:pawfect_care/domain/models/user_role.dart';
import 'package:pawfect_care/domain/repositories/care_repository.dart';
import 'package:pawfect_care/presentation/screens/shared/feature_catalog.dart';

void main() {
  const owner = AppUser(
    uid: 'owner-test',
    name: 'Owner Test',
    email: 'owner@test.pawfectcare.app',
    phone: '+92 300 0000000',
    role: UserRole.petOwner,
    emailVerified: true,
  );
  const shelterAdmin = AppUser(
    uid: 'demo-shelterAdmin',
    name: 'Shelter Admin',
    email: 'shelter@test.pawfectcare.app',
    phone: '+92 300 0000001',
    role: UserRole.shelterAdmin,
    emailVerified: true,
  );
  const veterinarian = AppUser(
    uid: 'demo-veterinarian',
    name: 'Dr. Maya Chen',
    email: 'vet@test.pawfectcare.app',
    phone: '+92 300 0000002',
    role: UserRole.veterinarian,
    emailVerified: true,
  );

  test(
    'owners can track adoption requests and cannot submit duplicates',
    () async {
      final repository = DemoCareRepository();
      final listing = (await repository.watchAdoptionListings().first).first;

      await repository.submitAdoptionRequest(
        owner: owner,
        listing: listing,
        message: 'A safe home.',
      );
      await expectLater(
        repository.submitAdoptionRequest(
          owner: owner,
          listing: listing,
          message: 'Duplicate request.',
        ),
        throwsA(isA<CareFailure>()),
      );

      final requests = await repository.watchAdoptionRequests(owner).first;
      expect(requests, hasLength(1));
      expect(requests.single.status, RequestStatus.pending);
      expect(
        FeatureCatalog.owner.any((item) => item.title == 'Adoption Requests'),
        isTrue,
      );
    },
  );

  test(
    'volunteer requests reach both the user and destination shelter',
    () async {
      final repository = DemoCareRepository();
      await repository.submitCommunityRequest(
        user: owner,
        shelterId: 'demo-shelter',
        kind: 'volunteer',
        message: 'I can help on weekends.',
      );

      final ownerRequests = await repository
          .watchVolunteerRequests(owner)
          .first;
      final shelterRequests = await repository
          .watchVolunteerRequests(shelterAdmin)
          .first;
      expect(ownerRequests, hasLength(1));
      expect(shelterRequests, hasLength(1));
      expect(shelterRequests.single.message, 'I can help on weekends.');

      await repository.updateCommunityRequestStatus(
        request: shelterRequests.single,
        status: 'approved',
      );
      final updated = await repository.watchVolunteerRequests(owner).first;
      expect(updated.single.status, 'approved');
    },
  );

  test(
    'success-story drafts stay private until the shelter publishes them',
    () async {
      final repository = DemoCareRepository();
      final draft = SuccessStory(
        id: '',
        shelterId: 'demo-shelter',
        adminId: shelterAdmin.uid,
        title: 'Coco found a family',
        story: 'Coco is safe and loved in her new home.',
        published: false,
        photoPath: 'cloudinary:coco-story',
        photoUrl: 'https://example.com/coco.jpg',
      );

      final id = await repository.saveSuccessStory(draft);
      expect(
        await repository.watchSuccessStories(shelterId: 'demo-shelter').first,
        hasLength(1),
      );
      expect(await repository.watchSuccessStories().first, isEmpty);

      await repository.saveSuccessStory(
        draft.copyWith(id: id, published: true),
      );
      final gallery = await repository.watchSuccessStories().first;
      expect(gallery, hasLength(1));
      expect(gallery.single.title, 'Coco found a family');
      expect(
        FeatureCatalog.owner.any((item) => item.title == 'Success Stories'),
        isTrue,
      );
      expect(
        FeatureCatalog.veterinarian.any(
          (item) => item.title == 'Success Stories',
        ),
        isTrue,
      );
    },
  );

  test('demo health records persist and reminders stay owner-scoped', () async {
    final repository = DemoCareRepository();
    final record = HealthRecord(
      id: '',
      petId: 'demo-luna',
      type: HealthRecordType.vaccination,
      title: 'Distemper booster',
      date: DateTime(2026, 8, 25),
      dueDate: DateTime(2026, 9, 25),
      veterinarianId: veterinarian.uid,
      notes: 'Booster recorded during the visit.',
    );

    final id = await repository.saveHealthRecord(
      actor: veterinarian,
      record: record,
    );
    final records = await repository.watchHealthRecords('demo-luna').first;
    expect(records.any((item) => item.id == id), isTrue);

    final ownerNotifications = await repository
        .watchNotifications('demo-owner')
        .first;
    final vetNotifications = await repository
        .watchNotifications(veterinarian.uid)
        .first;
    expect(
      ownerNotifications.any((item) => item.title.contains('Reminder Set')),
      isTrue,
    );
    expect(
      vetNotifications.any((item) => item.title.contains('Reminder Set')),
      isFalse,
    );
  });

  test(
    'demo adoption notifications are private and can be marked read',
    () async {
      final repository = DemoCareRepository();
      final listing = (await repository.watchAdoptionListings().first).first;
      await repository.submitAdoptionRequest(
        owner: owner,
        listing: listing,
        message: 'A safe and loving home.',
      );

      final ownerNotifications = await repository
          .watchNotifications(owner.uid)
          .first;
      final shelterNotifications = await repository
          .watchNotifications(shelterAdmin.uid)
          .first;
      expect(ownerNotifications, hasLength(1));
      expect(ownerNotifications.single.title, 'Adoption Application Sent');
      expect(shelterNotifications, hasLength(1));
      expect(shelterNotifications.single.title, 'New Adoption Application');

      await repository.markNotificationRead(
        uid: owner.uid,
        notificationId: ownerNotifications.single.id,
      );
      final readNotifications = await repository
          .watchNotifications(owner.uid)
          .first;
      expect(readNotifications.single.readAt, isNotNull);
    },
  );
}
