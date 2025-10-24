import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:leadrole/shared/colors.dart';

import '../../logic/job_wizard_providers.dart';

class SceneStepScreen extends ConsumerWidget {
  const SceneStepScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(jobWizardProvider);
    final ctrl = ref.read(jobWizardProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Scene Setup'),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          _Card(
            title: '🎬 Your Shot',
            subtitle:
                'Pick a vibe. We\'ll keep your face front-and-center for perfect swaps.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ChipGroup<String>(
                  label: 'Scene type',
                  value: st.options.sceneType,
                  items: const ['Vlog', 'Cinematic', 'Story', 'Interview'],
                  onPick: ctrl.setSceneType,
                ),
                const SizedBox(height: 12),
                _ChipGroup<String>(
                  label: 'Mood',
                  value: st.options.mood?.isNotEmpty == true
                      ? st.options.mood!
                      : 'energetic',
                  items: const ['energetic', 'moody', 'calm', 'playful'],
                  onPick: (v) => ctrl.setMood(v),
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: ctrl.setLocation,
                  decoration: _dec('Location (e.g., Shinjuku neon street)'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tip: short and specific places work great (alley, rooftop, arcade).',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),

          _Card(
            title: '✨ Style & Camera',
            subtitle: 'Minimal defaults. Tweak only if you want.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ChipGroup<String>(
                  label: 'Camera',
                  value: st.options.cameraStyle,
                  items: const ['SelfieVlog', 'Handheld', 'Tripod'],
                  onPick: ctrl.setCameraStyle,
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: ctrl.setOutfit,
                  decoration: _dec('Wardrobe (optional, e.g., black tee)'),
                ),
                const SizedBox(height: 12),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  collapsedIconColor: AppColors.neon,
                  iconColor: AppColors.neon,
                  title: const Text(
                    'Advanced 🎛️',
                    style: TextStyle(color: Colors.white),
                  ),
                  childrenPadding: EdgeInsets.zero,
                  children: [
                    const SizedBox(height: 8),
                    TextField(
                      onChanged: ctrl.setLighting,
                      decoration: _dec(
                        'Lighting (e.g., neon spill / golden hour)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _DropCompact(
                          label: 'Aspect',
                          value: st.options.video.aspectRatio,
                          items: const ['9:16', '16:9'],
                          onChanged: (v) => ctrl.setVideoSpec(aspect: v),
                        ),
                        const SizedBox(width: 8),
                        _DropCompact(
                          label: 'Length',
                          value: st.options.video.duration,
                          items: const ['5s', '9s'],
                          onChanged: (v) => ctrl.setVideoSpec(dur: v),
                        ),
                        const SizedBox(width: 8),
                        _DropCompact(
                          label: 'Res',
                          value: st.options.video.resolution,
                          items: const ['720p'],
                          onChanged: (v) => ctrl.setVideoSpec(res: v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ],
            ),
          ),

          _Card(
            title: '📐 Director’s Note (optional)',
            subtitle: 'One-liner to steer the vibe. Keep it simple.',
            child: TextField(
              maxLines: 3,
              minLines: 2,
              onChanged: ctrl.setPrompt,
              decoration: _dec('e.g., “late-night vlog with neon reflections”'),
            ),
          ),

          const SizedBox(height: 100),
        ],
      ),

      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () => context.push('/wizard/narration'),
            child: const Text('Next · Narration'),
          ),
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
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );
}

// ---------- widgets ----------

class _Card extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  const _Card({required this.title, this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neon.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: const TextStyle(color: Colors.white60, fontSize: 12.5),
            ),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ChipGroup<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final void Function(T) onPick;

  const _ChipGroup({
    required this.label,
    required this.value,
    required this.items,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label', style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((e) {
            final sel = e == value;
            return ChoiceChip(
              label: Text('$e'),
              selected: sel,
              onSelected: (_) => onPick(e),
              selectedColor: AppColors.neon,
              labelStyle: TextStyle(color: sel ? Colors.black : Colors.white),
              backgroundColor: const Color(0xFF252525),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _DropCompact extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropCompact({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InputDecorator(
        decoration: InputDecoration(
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 6,
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            dropdownColor: const Color(0xFF1E1E1E),
            items: items
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}
