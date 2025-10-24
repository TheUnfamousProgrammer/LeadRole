import 'package:flutter/material.dart';
import '../../../shared/colors.dart';

class WizardHeader extends StatelessWidget {
  final int scene;
  const WizardHeader({super.key, required this.scene});

  @override
  Widget build(BuildContext context) {
    final steps = const ['Face Kit', 'Appearance', 'Consent'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: List.generate(3, (i) {
              final active = i <= scene;
              return Expanded(
                child: Container(
                  height: 5,
                  margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.neon
                        : AppColors.neon.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(3, (i) {
              final active = i == scene;
              return Expanded(
                child: Text(
                  steps[i],
                  textAlign: i == 0
                      ? TextAlign.left
                      : i == 1
                      ? TextAlign.center
                      : TextAlign.right,
                  style: TextStyle(
                    color: active ? Colors.white : AppColors.textMuted,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
