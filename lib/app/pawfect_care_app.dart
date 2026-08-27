import 'package:flutter/material.dart';

import '../core/config/app_environment.dart';
import '../core/config/app_services.dart';
import '../core/theme/app_theme.dart';
import '../presentation/controllers/auth_controller.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/verification_screen.dart';
import '../presentation/screens/onboarding/onboarding_screen.dart';
import '../presentation/screens/shared/role_home_shell.dart';
import '../presentation/screens/shared/splash_screen.dart';

class PawfectCareApp extends StatefulWidget {
  PawfectCareApp({
    required this.authController,
    AppServices? services,
    super.key,
  }) : services = services ?? AppServices.demo();

  final AuthController authController;
  final AppServices services;

  @override
  State<PawfectCareApp> createState() => _PawfectCareAppState();
}

class _PawfectCareAppState extends State<PawfectCareApp> {
  @override
  void initState() {
    super.initState();
    widget.authController.initialize();
  }

  @override
  void dispose() {
    widget.authController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.authController,
      builder: (context, _) {
        final controller = widget.authController;
        final navigatorIdentity =
            '${controller.stage.name}-${controller.user?.uid ?? 'guest'}';
        return MaterialApp(
          key: ValueKey(navigatorIdentity),
          title: AppEnvironment.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: switch (controller.stage) {
            AuthStage.initializing => const SplashScreen(),
            AuthStage.onboarding => OnboardingScreen(
              onComplete: controller.completeOnboarding,
            ),
            AuthStage.signedOut => LoginScreen(controller: controller),
            AuthStage.verifying => VerificationScreen(controller: controller),
            AuthStage.authenticated => RoleHomeShell(
              user: controller.user!,
              controller: controller,
              services: widget.services,
            ),
          },
        );
      },
    );
  }
}
