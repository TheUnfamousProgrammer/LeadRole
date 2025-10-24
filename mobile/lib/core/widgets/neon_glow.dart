import 'package:flutter/material.dart';
import '../../shared/colors.dart';

class NeonGlow extends StatelessWidget {
  final Widget child;
  final double spread;
  final double blur;

  const NeonGlow({
    super.key,
    required this.child,
    this.spread = 0.0,
    this.blur = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AppColors.neon.withOpacity(0.45),
            blurRadius: blur,
            spreadRadius: spread,
          ),
          BoxShadow(
            color: AppColors.neon.withOpacity(0.25),
            blurRadius: blur * 1.6,
            spreadRadius: spread,
          ),
        ],
      ),
      child: child,
    );
  }
}
