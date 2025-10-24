import 'package:flutter/material.dart';
import 'package:leadrole/shared/colors.dart';
import '../widgets/film_notes.dart';

class SceneConsent extends StatelessWidget {
  final bool consent;
  final ValueChanged<bool> onConsent;
  final String? error;

  const SceneConsent({
    super.key,
    required this.consent,
    required this.onConsent,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return _CardFrame(
      title: 'Scene 3 - Release Form',
      subtitle:
          'Grant permission to generate short demo clips with your likeness.',
      child: Column(
        children: [
          SwitchListTile.adaptive(
            value: consent,
            activeColor: Colors.black,
            activeTrackColor: AppColors.neon,
            onChanged: onConsent,
            title: const Text(
              'I grant consent to use my likeness for AI previews.',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'No public posting; demo use only.',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          if (error != null && error!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.redAccent.withOpacity(0.12),
                border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
              ),
              child: Text(
                error!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
          const SizedBox(height: 8),
          const FilmNotes(
            points: [
              'You’re the star - you’re in control.',
              'You can update or delete your Persona anytime.',
            ],
          ),
        ],
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
