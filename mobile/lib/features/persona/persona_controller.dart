import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:image_picker/image_picker.dart';
import 'package:leadrole/features/auth/auth_controller.dart';

import 'persona_model.dart';
import 'persona_repository.dart';

final personaRepositoryProvider = Provider<PersonaRepository>(
  (ref) => PersonaRepository(),
);

class PersonaFormState {
  final String userId;
  final String? displayName;
  final String gender;
  final String? ageRange;
  final String? ethnicity;
  final String? hair;
  final String? style;
  final File? selfieFile;
  final String? selfieUrl;
  final bool consent;
  final AsyncValue<void> submitting;

  const PersonaFormState({
    required this.userId,
    required this.gender,
    required this.consent,
    this.displayName,
    this.ageRange,
    this.ethnicity,
    this.hair,
    this.style,
    this.selfieFile,
    this.selfieUrl,
    this.submitting = const AsyncData(null),
  });

  String? get error => submitting is AsyncError
      ? (submitting as AsyncError).error.toString()
      : null;

  PersonaFormState copyWith({
    String? userId,
    String? displayName,
    String? gender,
    String? ageRange,
    String? ethnicity,
    String? hair,
    String? style,
    File? selfieFile,
    String? selfieUrl,
    bool? consent,
    AsyncValue<void>? submitting,
  }) {
    return PersonaFormState(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      gender: gender ?? this.gender,
      ageRange: ageRange ?? this.ageRange,
      ethnicity: ethnicity ?? this.ethnicity,
      hair: hair ?? this.hair,
      style: style ?? this.style,
      selfieFile: selfieFile ?? this.selfieFile,
      selfieUrl: selfieUrl ?? this.selfieUrl,
      consent: consent ?? this.consent,
      submitting: submitting ?? this.submitting,
    );
  }
}

final personaFormProvider =
    StateNotifierProvider<PersonaFormController, PersonaFormState>((ref) {
      final authState = ref.watch(authProvider);
      return PersonaFormController(
        ref,
        PersonaFormState(
          userId: authState.user!.id,
          gender: 'male',
          consent: false,
        ),
      );
    });

class PersonaFormController extends StateNotifier<PersonaFormState> {
  final Ref ref;
  final _picker = ImagePicker();

  PersonaFormController(this.ref, PersonaFormState state) : super(state);

  // --- setters
  void setDisplayName(String v) => state = state.copyWith(displayName: v);
  void setGender(String v) => state = state.copyWith(gender: v);
  void setAgeRange(String? v) => state = state.copyWith(ageRange: v);
  void setEthnicity(String? v) => state = state.copyWith(ethnicity: v);
  void setHair(String? v) => state = state.copyWith(hair: v);
  void setStyle(String? v) => state = state.copyWith(style: v);
  void setConsent(bool v) => state = state.copyWith(consent: v);
  void setSelfie(File? f) => state = state.copyWith(selfieFile: f);

  Future<void> pickFromGallery() async {
    final x = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 92,
    );
    if (x != null) setSelfie(File(x.path));
  }

  Future<void> pickFromCamera() async {
    final x = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 92,
    );
    if (x != null) setSelfie(File(x.path));
  }

  void clearSelfie() => setSelfie(null);

  Future<void> submit() async {
    if (!state.consent) {
      throw Exception('consent_required');
    }
    if (state.selfieFile == null) {
      throw Exception('selfie_required');
    }

    state = state.copyWith(submitting: const AsyncLoading());

    try {
      final repo = ref.read(personaRepositoryProvider);

      // 1) Upload selfie -> URL
      final selfieUrl = await repo.uploadSelfieToCloudinary(state.selfieFile!);
      state = state.copyWith(selfieUrl: selfieUrl);

      // 2) Save persona to backend
      final persona = Persona(
        userId: state.userId,
        displayName: state.displayName,
        gender: state.gender,
        ageRange: state.ageRange,
        ethnicity: state.ethnicity,
        hair: state.hair,
        style: state.style,
        faceKitURL: selfieUrl,
        consent: state.consent,
      );

      await repo.savePersona(persona);
      state = state.copyWith(submitting: const AsyncData(null));
    } catch (e, st) {
      state = state.copyWith(submitting: AsyncError(e, st));
      rethrow;
    }
  }
}
