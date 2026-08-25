import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawfect_care/core/config/app_services.dart';
import 'package:pawfect_care/core/theme/app_theme.dart';
import 'package:pawfect_care/core/utils/search_matcher.dart';
import 'package:pawfect_care/data/repositories/demo_care_repository.dart';
import 'package:pawfect_care/domain/models/app_user.dart';
import 'package:pawfect_care/domain/models/user_role.dart';
import 'package:pawfect_care/presentation/screens/shared/dashboard_screen.dart';
import 'package:pawfect_care/presentation/screens/shared/feature_catalog.dart';

void main() {
  const owner = AppUser(
    uid: 'demo-owner',
    name: 'Jamie Morgan',
    email: 'owner@example.com',
    phone: '+1 555 0100',
    role: UserRole.petOwner,
    emailVerified: true,
  );

  test('search matches every word across authorized record fields', () {
    expect(
      SearchMatcher.matches('husky luna', ['Luna', 'Siberian Husky', 'Dog']),
      isTrue,
    );
    expect(
      SearchMatcher.matches('booster vaccine', [
        'Annual Vaccine',
        'Booster due in seven days',
      ]),
      isTrue,
    );
    expect(
      SearchMatcher.matches('nutrition water', [
        'Everyday nutrition basics',
        'Provide fresh water every day.',
      ]),
      isTrue,
    );
    expect(SearchMatcher.matches('private diagnosis', ['Pet Care']), isFalse);
  });

  test('care tips are available to every required role', () {
    for (final role in UserRole.values) {
      expect(
        FeatureCatalog.forRole(role).any((item) => item.title == 'Care Tips'),
        isTrue,
      );
    }
  });

  test('demo catalog has several items in every required category', () async {
    final repository = DemoCareRepository();
    final products = await repository.watchProducts().first;
    final blogs = await repository.watchBlogs().first;

    expect(products, hasLength(20));
    expect(blogs, hasLength(16));
    for (final category in const ['Food', 'Grooming', 'Toys', 'Health']) {
      expect(products.where((item) => item.category == category), hasLength(5));
    }
    for (final category in const [
      'Training',
      'Nutrition',
      'First Aid',
      'Pet Care',
    ]) {
      expect(blogs.where((item) => item.category == category), hasLength(4));
    }
  });

  testWidgets('dashboard forwards a global query into blog search', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: DashboardScreen(user: owner, services: AppServices.demo()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Search pets, care, or services'),
      'nutrition',
    );
    await tester.pumpAndSettle();

    expect(find.text('Search in Care Tips'), findsOneWidget);
    await tester.tap(find.text('Search in Care Tips'));
    await tester.pumpAndSettle();

    expect(find.text('Everyday nutrition basics'), findsOneWidget);
    expect(find.text('A calmer first vet visit'), findsNothing);
  });
}
