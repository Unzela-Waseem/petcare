import 'package:flutter_test/flutter_test.dart';
import 'package:pawfect_care/data/repositories/demo_auth_repository.dart';
import 'package:pawfect_care/data/services/session_store.dart';
import 'package:pawfect_care/domain/models/user_role.dart';
import 'package:pawfect_care/presentation/controllers/auth_controller.dart';

void main() {
  test(
    'role session authenticates and logout clears protected state',
    () async {
      final controller = AuthController(
        authRepository: DemoAuthRepository(),
        sessionStore: MemorySessionStore(onboardingComplete: true),
      );

      await controller.initialize();
      expect(controller.stage, AuthStage.signedOut);

      await controller.signInDemo(UserRole.shelterAdmin);
      expect(controller.stage, AuthStage.authenticated);
      expect(controller.user?.role, UserRole.shelterAdmin);

      await controller.signOut();
      expect(controller.stage, AuthStage.signedOut);
      expect(controller.user, isNull);
    },
  );
}
