import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawfect_care/core/config/app_services.dart';
import 'package:pawfect_care/core/theme/app_theme.dart';
import 'package:pawfect_care/data/repositories/demo_care_repository.dart';
import 'package:pawfect_care/domain/models/app_user.dart';
import 'package:pawfect_care/domain/models/pet.dart';
import 'package:pawfect_care/domain/models/public_pet_profile.dart';
import 'package:pawfect_care/domain/models/user_role.dart';
import 'package:pawfect_care/presentation/screens/pets/pet_identity_screen.dart';

void main() {
  const owner = AppUser(
    uid: 'demo-owner',
    name: 'Justin',
    email: 'owner@test.pawfectcare.app',
    phone: '+92 300 1234567',
    role: UserRole.petOwner,
    emailVerified: true,
  );
  const luna = Pet(
    id: 'demo-luna',
    ownerId: 'demo-owner',
    name: 'Luna',
    species: 'Dog',
    breed: 'Siberian Husky',
    age: 3,
    gender: 'Female',
    description: 'Gentle and friendly.',
  );

  test('public QR links use the stable hosted pet route', () {
    final link = Uri.parse(publicPetProfileUrl('secure-random-id'));
    expect(link.host, 'pawfectcare-unzela-2026.web.app');
    expect(link.queryParameters['pet'], 'secure-random-id');
  });

  test(
    'demo QR profile lifecycle supports create, update, and disable',
    () async {
      final repository = DemoCareRepository();
      expect(
        await repository
            .watchManagedPublicPetProfile(
              managerId: owner.uid,
              sourceType: PublicPetSourceType.ownedPet,
              sourceId: luna.id,
            )
            .first,
        isNull,
      );

      final id = await repository.savePublicPetProfile(
        const PublicPetProfile(
          id: '',
          sourceId: 'demo-luna',
          sourceType: PublicPetSourceType.ownedPet,
          managerId: 'demo-owner',
          petName: 'Luna',
          species: 'Dog',
          breed: 'Siberian Husky',
          age: 3,
          gender: 'Female',
          contactName: 'Justin',
          contactPhone: '+92 300 1234567',
        ),
      );
      final created = await repository.watchPublicPetProfile(id).first;
      expect(created?.petName, 'Luna');
      expect(created?.active, isTrue);

      await repository.savePublicPetProfile(created!.copyWith(isLost: true));
      expect(
        (await repository.watchPublicPetProfile(id).first)?.isLost,
        isTrue,
      );

      await repository.deletePublicPetProfile(id);
      expect(await repository.watchPublicPetProfile(id).first, isNull);
    },
  );

  testWidgets('owner can generate and preview a scannable QR identity', (
    tester,
  ) async {
    final services = AppServices.demo();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: PetIdentityScreen(
          user: owner,
          services: services,
          seed: PetIdentitySeed.ownedPet(pet: luna, owner: owner),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Create Luna’s QR identity'), findsOneWidget);
    await tester.tap(find.text('Create Secure QR'));
    await tester.pumpAndSettle();
    expect(find.text('Create Pet QR'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Generate Secure QR'));
    await tester.pumpAndSettle();

    expect(find.text('QR tag active'), findsOneWidget);
    expect(find.text('Download / Share QR'), findsOneWidget);
    expect(find.text('Preview'), findsOneWidget);
  });

  testWidgets('public scan page shows safe details and contact actions', (
    tester,
  ) async {
    final repository = DemoCareRepository();
    final id = await repository.savePublicPetProfile(
      const PublicPetProfile(
        id: '',
        sourceId: 'demo-luna',
        sourceType: PublicPetSourceType.ownedPet,
        managerId: 'demo-owner',
        petName: 'Luna',
        species: 'Dog',
        breed: 'Siberian Husky',
        age: 3,
        gender: 'Female',
        description: 'Gentle and friendly.',
        allergies: 'Chicken',
        emergencyNotes: 'Please approach slowly.',
        contactName: 'Justin',
        contactPhone: '+92 300 1234567',
        isLost: true,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: PublicPetProfileScreen(publicId: id, care: repository),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('LOST PET'), findsOneWidget);
    expect(find.text('Luna'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Allergies: Chicken'),
      400,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Allergies: Chicken'), findsOneWidget);
    expect(find.text('Call Justin'), findsOneWidget);
    expect(find.text('I Found This Pet'), findsOneWidget);
    expect(find.textContaining('private medical records'), findsOneWidget);
  });
}
