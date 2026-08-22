import 'package:flutter/material.dart';

import '../../../core/config/auth_validators.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/paw_button.dart';
import '../../controllers/auth_controller.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({required this.controller, super.key});
  final AuthController controller;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: AppColors.cream),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.key_rounded,
                      size: 54,
                      color: AppColors.orangeDeep,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Reset your password',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'We will send secure reset instructions to your verified email.',
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _email,
                      validator: AuthValidators.email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email address',
                        prefixIcon: Icon(Icons.mail_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 18),
                    PawButton(
                      label: 'Send Reset Link',
                      busy: widget.controller.busy,
                      onPressed: () async {
                        if (!_formKey.currentState!.validate()) return;
                        final sent = await widget.controller.resetPassword(
                          _email.text,
                        );
                        if (sent && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(widget.controller.message!)),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
