import 'dart:io';
import 'package:flutter/material.dart';
import '../../../shared/colors.dart';

class NeonGlowAvatar extends StatelessWidget {
  final File? file;
  final double radius;
  final VoidCallback? onTapPreview;
  final VoidCallback? onRetake;
  const NeonGlowAvatar({
    super.key,
    required this.file,
    this.radius = 62,
    this.onTapPreview,
    this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    final hasImg = file != null;
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: (radius * 2) + 18,
          height: (radius * 2) + 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.neon.withOpacity(0.22),
                blurRadius: 28,
                spreadRadius: 6,
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: hasImg ? onTapPreview : null,
          child: CircleAvatar(
            radius: radius,
            backgroundColor: AppColors.neon.withOpacity(0.18),
            backgroundImage: hasImg ? FileImage(file!) : null,
            child: hasImg
                ? null
                : Icon(
                    Icons.person,
                    size: radius,
                    color: Colors.black.withOpacity(0.55),
                  ),
          ),
        ),
        if (hasImg && onRetake != null)
          Positioned(
            right: 6,
            bottom: 6,
            child: Tooltip(
              message: 'Retake',
              child: InkWell(
                onTap: onRetake,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.neon,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.neon.withOpacity(0.35),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.refresh,
                    size: 16,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
