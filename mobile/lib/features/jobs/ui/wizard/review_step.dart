import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leadrole/shared/colors.dart';
import '../../logic/job_wizard_providers.dart';
import 'package:go_router/go_router.dart';

class ReviewStepScreen extends ConsumerWidget {
  const ReviewStepScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(jobWizardProvider);
    final ctrl = ref.read(jobWizardProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Review & Roll Camera'),
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Column(
          children: [
            _CardRow(label: 'Scene', value: st.options.sceneType),
            _CardRow(label: 'Camera', value: st.options.cameraStyle),
            _CardRow(
              label: 'Location',
              value: st.options.location.isEmpty ? '—' : st.options.location,
            ),
            _CardRow(
              label: 'Mood',
              value: st.options.mood.isEmpty ? '—' : st.options.mood,
            ),
            _CardRow(
              label: 'Lighting',
              value: st.options.lighting.isEmpty ? '—' : st.options.lighting,
            ),
            _CardRow(
              label: 'Wardrobe',
              value: st.options.outfit.isEmpty ? '—' : st.options.outfit,
            ),
            _CardRow(label: 'Aspect', value: st.options.video.aspectRatio),
            _CardRow(label: 'Duration', value: st.options.video.duration),
            const SizedBox(height: 8),
            _CardRow(
              label: 'Narration',
              value: st.options.narration.text.isEmpty ? '—' : 'Provided',
            ),
            _CardRow(label: 'Voice', value: st.options.narration.voiceProfile),
            const Spacer(),
            if (st.error != null) ...[
              Text(
                _extractErrorMessage(st.error!),
                style: const TextStyle(color: Colors.redAccent),
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: st.submitting
                    ? null
                    : () async {
                        try {
                          final id = await ctrl.submit();
                          if (context.mounted) context.go('/jobs/$id');
                        } catch (_) {}
                      },
                child: st.submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Lights, Camera, Action!'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _extractErrorMessage(String error) {
    final errorMatch = RegExp(
      r'error:\s*(.+)',
      caseSensitive: false,
    ).firstMatch(error);
    return errorMatch?.group(1) ?? 'An error occurred';
  }
}

class _CardRow extends StatelessWidget {
  final String label;
  final String value;
  const _CardRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neon.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.white70)),
          ),
          Text(value, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
