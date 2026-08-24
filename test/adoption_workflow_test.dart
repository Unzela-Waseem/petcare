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
}
