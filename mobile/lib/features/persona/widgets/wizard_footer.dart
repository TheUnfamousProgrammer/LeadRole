import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../shared/colors.dart';

class WizardFooter extends StatelessWidget {
  final bool loading;
  final bool canNext;
  final int scene;
  final VoidCallback? onBack;
  final VoidCallback? onNext;

  const WizardFooter({
    super.key,
    required this.loading,
    required this.canNext,
    required this.scene,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final primaryLabel = switch (scene) {
      0 => 'Lock Headshot',
      1 => 'Mark Appearance',
      _ => 'Sign & Save',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onBack,
              style: OutlinedButton.styleFrom(
                foregroundColor: onBack == null
                    ? Colors.white24
                    : AppColors.neon,
                side: BorderSide(
                  color: onBack == null
                      ? Colors.white12
                      : AppColors.neon.withOpacity(0.6),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Back'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: canNext ? onNext : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canNext
                    ? AppColors.neon
                    : AppColors.neon.withOpacity(0.35),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: canNext ? 2 : 0,
              ),
              child: loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CupertinoActivityIndicator(
                        color: Colors.black,
                        radius: 10,
                      ),
                    )
                  : Text(
                      primaryLabel,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
