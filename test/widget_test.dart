import 'package:flutter_test/flutter_test.dart';
import 'package:pawfect_care/app/pawfect_care_app.dart';
import 'package:pawfect_care/data/repositories/demo_auth_repository.dart';
import 'package:pawfect_care/data/services/session_store.dart';
import 'package:pawfect_care/domain/models/user_role.dart';
import 'package:pawfect_care/presentation/controllers/auth_controller.dart';

void main() {
  testWidgets('shows the themed onboarding experience for a first launch', (
    tester,
  ) async {
    final controller = AuthController(
      authRepository: DemoAuthRepository(),
      sessionStore: MemorySessionStore(),
    );

    await tester.pumpWidget(PawfectCareApp(authController: controller));
    await tester.pumpAndSettle();

    expect(find.text('Care that feels\nlike family.'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('demo role access routes to the selected protected dashboard', (
    tester,
  ) async {
    final controller = AuthController(
      authRepository: DemoAuthRepository(),
      sessionStore: MemorySessionStore(onboardingComplete: true),
    );

    await tester.pumpWidget(PawfectCareApp(authController: controller));
    await tester.pumpAndSettle();
    final signIn = controller.signInDemo(UserRole.veterinarian);
    await tester.pump(const Duration(milliseconds: 250));
    await signIn;
    await tester.pumpAndSettle();

    expect(find.text('Veterinarian'), findsOneWidget);
    expect(controller.stage, AuthStage.authenticated);
  });
}
