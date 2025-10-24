import 'package:flutter/material.dart';
import 'package:leadrole/shared/colors.dart';
import '../widgets/film_notes.dart';
import '../widgets/inputs.dart';

class SceneAppearance extends StatelessWidget {
  final String? displayName;
  final ValueChanged<String> onDisplayName;
  final String gender;
  final ValueChanged<String> onGender;
  final String? ageRange;
  final ValueChanged<String?> onAgeRange;
  final String? ethnicity;
  final ValueChanged<String> onEthnicity;
  final String? hair;
  final ValueChanged<String> onHair;
  final String? style;
  final ValueChanged<String> onStyle;

  const SceneAppearance({
    super.key,
    required this.displayName,
    required this.onDisplayName,
    required this.gender,
    required this.onGender,
    required this.ageRange,
    required this.onAgeRange,
    required this.ethnicity,
    required this.onEthnicity,
    required this.hair,
    required this.onHair,
    required this.style,
    required this.onStyle,
  });

  @override
  Widget build(BuildContext context) {
    return _CardFrame(
      title: 'Scene 2 - Appearance Notes',
      subtitle:
          'These notes help our Director craft a shot list that looks like you so Face Swap is seamless.',
      child: Column(
        children: [
          _textField('Stage name (optional)', displayName, onDisplayName),
          const SizedBox(height: 12),
          GenderRow(value: gender, onChanged: onGender),
          const SizedBox(height: 12),
          NeonDropdown<String>(
            label: 'Age range',
            value: ageRange,
            items: const ['18-24', '25-34', '35-44', '45-54', '55+'],
            onChanged: onAgeRange,
          ),
          const SizedBox(height: 12),
          _textField(
            'Ethnicity (e.g., South Asian / Pakistani)',
            ethnicity,
            onEthnicity,
          ),
          const SizedBox(height: 12),
          _textField('Hair (e.g., short wavy black)', hair, onHair),
          const SizedBox(height: 12),
          _textField('Wardrobe vibe (e.g., casual black tee)', style, onStyle),
          const SizedBox(height: 10),
          const FilmNotes(
            points: [
              'Keep it real-this guides the AI casting.',
              'We auto-lock the framing on your face for cinematic vlog shots.',
            ],
          ),
        ],
      ),
    );
  }

  Widget _textField(
    String label,
    String? initial,
    ValueChanged<String> onChanged,
  ) {
    return TextFormField(
      initialValue: initial,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textMuted),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.neon.withOpacity(0.35)),
          borderRadius: BorderRadius.circular(14),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.neon, width: 1.6),
          borderRadius: BorderRadius.circular(14),
        ),
        filled: true,
        fillColor: const Color(0xFF222222),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
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
