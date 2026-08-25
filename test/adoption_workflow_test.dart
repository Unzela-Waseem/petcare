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
}
