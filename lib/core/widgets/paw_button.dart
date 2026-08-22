import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PawButton extends StatelessWidget {
  const PawButton({
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.icon = Icons.pets_rounded,
    this.backgroundColor = AppColors.orange,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final IconData icon;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 62,
      width: double.infinity,
      child: FilledButton(
        onPressed: busy ? null : onPressed,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.all(6),
          backgroundColor: backgroundColor,
          foregroundColor: AppColors.ink,
          disabledBackgroundColor: backgroundColor.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: AppColors.ink,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(icon, color: Colors.white, size: 23),
            ),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 50),
          ],
        ),
      ),
    );
  }
}

class PawIconButton extends StatelessWidget {
  const PawIconButton({
    required this.icon,
    required this.onPressed,
    this.semanticLabel,
    this.dark = false,
    super.key,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? semanticLabel;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: dark ? AppColors.ink : AppColors.surface,
            shape: BoxShape.circle,
            border: dark ? null : Border.all(color: AppColors.border),
          ),
          child: Icon(
            icon,
            size: 21,
            color: dark ? Colors.white : AppColors.ink,
          ),
        ),
      ),
    );
  }
}
