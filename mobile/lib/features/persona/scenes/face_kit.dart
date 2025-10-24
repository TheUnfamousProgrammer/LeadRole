import 'dart:io';
import 'package:flutter/material.dart';
import 'package:leadrole/shared/colors.dart';
import '../widgets/neon_glow_avatar.dart';
import '../widgets/film_notes.dart';

class SceneFaceKit extends StatelessWidget {
  final File? file;
  final VoidCallback onPickGallery;
  final VoidCallback onPickCamera;
  final VoidCallback onRetake;
  final VoidCallback onPreview;

  const SceneFaceKit({
    super.key,
    required this.file,
    required this.onPickGallery,
    required this.onPickCamera,
    required this.onRetake,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    return _CardFrame(
      title: 'Scene 1 - Face Kit (Headshots)',
      subtitle:
          'You’re the Lead. Upload a clean, front-facing headshot - think casting call: no masks, no hats, minimal glasses glare.',
      child: Column(
        children: [
          NeonGlowAvatar(
            file: file,
            onTapPreview: file != null ? onPreview : null,
            onRetake: file != null ? onRetake : null,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              _ghostButton(
                icon: Icons.photo,
                label: 'Gallery',
                onPressed: onPickGallery,
              ),
              _ghostButton(
                icon: Icons.photo_camera,
                label: 'Camera',
                onPressed: onPickCamera,
              ),
            ],
          ),
          const SizedBox(height: 10),
          const FilmNotes(
            points: [
              'Face centered & well lit',
              'Neutral or slight smile',
              'Avoid heavy sunglasses/occlusions',
              'One selfie is enough for the demo',
            ],
          ),
        ],
      ),
    );
  }

  static Widget _ghostButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.neon,
        side: BorderSide(color: AppColors.neon.withOpacity(0.6)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _CardFrame extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  const _CardFrame({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neon.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: AppColors.neon.withOpacity(0.05),
            blurRadius: 22,
            spreadRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.textMuted, height: 1.3),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
