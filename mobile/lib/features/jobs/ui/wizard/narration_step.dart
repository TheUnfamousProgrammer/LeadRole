import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leadrole/shared/colors.dart';
import '../../logic/job_wizard_providers.dart';
import 'package:go_router/go_router.dart';

class NarrationStepScreen extends ConsumerWidget {
  const NarrationStepScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(jobWizardProvider);
    final ctrl = ref.read(jobWizardProvider.notifier);

    final voices = const [
      'NarrationMale',
      'NarrationFemale',
      'StoryMale',
      'StoryFemale',
    ];

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Narration · LeadRole'),
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BannerText(
              text:
                  '🎙️ Voiceover — Your line, your vibe. Keep it tight to fit 5–9s.',
            ),
            const SizedBox(height: 16),

            TextField(
              maxLines: 4,
              onChanged: ctrl.setNarrationText,
              decoration: _dec('Your line (required)'),
            ),
            const SizedBox(height: 12),

            _Label('Voice'),
            Wrap(
              spacing: 8,
              children: voices.map((v) {
                final sel = st.options.narration.voiceProfile == v;
                return ChoiceChip(
                  label: Text(v),
                  selected: sel,
                  onSelected: (_) => ctrl.setVoiceProfile(v),
                  selectedColor: AppColors.neon,
                  labelStyle: TextStyle(
                    color: sel ? Colors.black : Colors.white,
                  ),
                  backgroundColor: const Color(0xFF252525),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            _Label('Language'),
            Row(
              children: [
                _LangChip(
                  code: 'en',
                  current: st.options.narration.language,
                  onPick: ctrl.setLanguage,
                ),
                const SizedBox(width: 8),
                _LangChip(
                  code: 'ur',
                  current: st.options.narration.language,
                  onPick: ctrl.setLanguage,
                ),
              ],
            ),

            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: st.options.narration.text.trim().isEmpty
                    ? null
                    : () => context.push('/wizard/review'),
                child: const Text('Next · Review'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _dec(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.white70),
    filled: true,
    fillColor: const Color(0xFF222222),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: AppColors.neon.withOpacity(0.35)),
      borderRadius: BorderRadius.circular(14),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: AppColors.neon, width: 1.6),
      borderRadius: BorderRadius.circular(14),
    ),
    contentPadding: const EdgeInsets.all(14),
  );
}

class _BannerText extends StatelessWidget {
  final String text;
  const _BannerText({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.neon.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white)),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: const TextStyle(color: Colors.white70)),
  );
}

class _LangChip extends StatelessWidget {
  final String code;
  final String current;
  final void Function(String) onPick;
  const _LangChip({
    required this.code,
    required this.current,
    required this.onPick,
  });
  @override
  Widget build(BuildContext context) {
    final sel = code == current;
    return ChoiceChip(
      label: Text(code.toUpperCase()),
      selected: sel,
      onSelected: (_) => onPick(code),
      selectedColor: AppColors.neon,
      labelStyle: TextStyle(color: sel ? Colors.black : Colors.white),
      backgroundColor: const Color(0xFF252525),
    );
  }
}
