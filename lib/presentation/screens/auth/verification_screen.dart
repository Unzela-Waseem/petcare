import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/paw_button.dart';
import '../../controllers/auth_controller.dart';

class VerificationScreen extends StatelessWidget {
  const VerificationScreen({required this.controller, super.key});
  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 94,
                    height: 94,
                    decoration: const BoxDecoration(
                      color: AppColors.peachLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mark_email_unread_outlined,
                      size: 42,
                      color: AppColors.orangeDeep,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Check your inbox',
                    style: Theme.of(context).textTheme.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Verify ${controller.user?.email ?? 'your email'} before accessing protected care features.',
                    textAlign: TextAlign.center,
                  ),
                  if (controller.message != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      controller.message!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.orangeDeep),
                    ),
                  ],
                  const SizedBox(height: 26),
                  PawButton(
                    label: 'I Have Verified',
                    busy: controller.busy,
                    onPressed: controller.refreshVerification,
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: controller.resendVerification,
                    child: const Text('Resend verification email'),
                  ),
                  TextButton(
                    onPressed: controller.signOut,
                    child: const Text(
                      'Use another account',
                      style: TextStyle(color: AppColors.ink),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
