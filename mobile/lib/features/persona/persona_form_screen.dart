import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:leadrole/features/persona/scenes/appearance.dart';
import 'package:leadrole/features/persona/scenes/consent.dart';
import 'package:leadrole/features/persona/scenes/face_kit.dart';

import '../../shared/colors.dart';
import 'persona_controller.dart';
import 'widgets/wizard_header.dart';
import 'widgets/wizard_footer.dart';

class PersonaFormScreen extends ConsumerStatefulWidget {
  const PersonaFormScreen({super.key});

  @override
  ConsumerState<PersonaFormScreen> createState() => _PersonaFormScreenState();
}

class _PersonaFormScreenState extends ConsumerState<PersonaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  int _scene = 0;

  bool _hasSelfie(File? f) => f != null;

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(personaFormProvider);
    final ctrl = ref.read(personaFormProvider.notifier);

    final loading = st.submitting is AsyncLoading;
    final error = st.submitting is AsyncError
        ? (st.submitting as AsyncError).error.toString()
        : null;

    final canNext = switch (_scene) {
      0 => _hasSelfie(st.selfieFile),
      1 => true,
      _ => true,
    };

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: const Text('LeadRole - Casting Prep'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 8),
              WizardHeader(scene: _scene),
              const SizedBox(height: 8),

              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, anim) =>
                      FadeTransition(opacity: anim, child: child),
                  child: SingleChildScrollView(
                    key: ValueKey(_scene),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    child: switch (_scene) {
                      0 => SceneFaceKit(
                        file: st.selfieFile,
                        onPickGallery: ctrl.pickFromGallery,
                        onPickCamera: ctrl.pickFromCamera,
                        onRetake: ctrl.clearSelfie,
                        onPreview: () => _openPreview(context, st.selfieFile!),
                      ),
                      1 => SceneAppearance(
                        displayName: st.displayName,
                        onDisplayName: ctrl.setDisplayName,
                        gender: st.gender,
                        onGender: ctrl.setGender,
                        ageRange: st.ageRange,
                        onAgeRange: ctrl.setAgeRange,
                        ethnicity: st.ethnicity,
                        onEthnicity: ctrl.setEthnicity,
                        hair: st.hair,
                        onHair: ctrl.setHair,
                        style: st.style,
                        onStyle: ctrl.setStyle,
                      ),
                      _ => SceneConsent(
                        consent: st.consent,
                        onConsent: ctrl.setConsent,
                        error: error,
                      ),
                    },
                  ),
                ),
              ),

              WizardFooter(
                loading: loading,
                canNext: canNext,
                scene: _scene,
                onBack: _scene == 0
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        setState(() => _scene -= 1);
                      },
                onNext: loading
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        if (_scene == 0 && !_hasSelfie(st.selfieFile)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please add a headshot to continue.',
                              ),
                            ),
                          );
                          return;
                        }
                        if (_scene < 2) {
                          setState(() => _scene += 1);
                        } else {
                          _submit(ctrl);
                        }
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit(PersonaFormController ctrl) async {
    try {
      await ctrl.submit();
      if (!mounted) return;
      context.goNamed('dashboard');
    } catch (_) {
      if (!mounted) return;
      final msg = ref.read(personaFormProvider).error ?? 'Something went wrong';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  void _openPreview(BuildContext context, File file) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4.0,
          child: Dialog(
            insetPadding: const EdgeInsets.all(20),
            backgroundColor: Colors.black,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(file, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}
