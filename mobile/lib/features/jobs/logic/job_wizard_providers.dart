import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:leadrole/features/auth/auth_controller.dart';
import 'package:leadrole/features/jobs/jobs_repository.dart';
import '../../auth/logic/auth_providers.dart';
import '../data/job_models.dart';

class JobWizardState {
  final SceneOptions options;
  final String userPrompt;
  final bool submitting;
  final String? jobId;
  final String? error;

  JobWizardState({
    this.options = const SceneOptions(),
    this.userPrompt = '',
    this.submitting = false,
    this.jobId,
    this.error,
  });

  JobWizardState copyWith({
    SceneOptions? options,
    String? userPrompt,
    bool? submitting,
    String? jobId,
    String? error,
  }) {
    return JobWizardState(
      options: options ?? this.options,
      userPrompt: userPrompt ?? this.userPrompt,
      submitting: submitting ?? this.submitting,
      jobId: jobId ?? this.jobId,
      error: error,
    );
  }
}

final jobWizardProvider =
    StateNotifierProvider<JobWizardController, JobWizardState>((ref) {
      return JobWizardController(ref);
    });

class JobWizardController extends StateNotifier<JobWizardState> {
  final Ref ref;
  JobWizardController(this.ref) : super(JobWizardState());

  void setSceneType(String v) =>
      state = state.copyWith(options: state.options.copyWith(sceneType: v));
  void setLocation(String v) =>
      state = state.copyWith(options: state.options.copyWith(location: v));
  void setMood(String v) =>
      state = state.copyWith(options: state.options.copyWith(mood: v));
  void setCameraStyle(String v) =>
      state = state.copyWith(options: state.options.copyWith(cameraStyle: v));
  void setLighting(String v) =>
      state = state.copyWith(options: state.options.copyWith(lighting: v));
  void setOutfit(String v) =>
      state = state.copyWith(options: state.options.copyWith(outfit: v));
  void setVideoSpec({String? aspect, String? dur, String? res}) {
    state = state.copyWith(
      options: state.options.copyWith(
        video: JobVideoSpec(
          aspectRatio: aspect ?? state.options.video.aspectRatio,
          duration: dur ?? state.options.video.duration,
          resolution: res ?? state.options.video.resolution,
        ),
      ),
    );
  }

  void setPrompt(String v) => state = state.copyWith(userPrompt: v);

  // Narration is mandatory
  void setNarrationText(String v) => state = state.copyWith(
    options: state.options.copyWith(
      narration: state.options.narration.copyWith(text: v),
    ),
  );
  void setVoiceProfile(String v) => state = state.copyWith(
    options: state.options.copyWith(
      narration: state.options.narration.copyWith(voiceProfile: v),
    ),
  );
  void setLanguage(String v) => state = state.copyWith(
    options: state.options.copyWith(
      narration: state.options.narration.copyWith(language: v),
    ),
  );

  Future<String> submit() async {
    final user = ref.read(authProvider).user;
    if (user == null) throw Exception('auth_required');

    if (state.options.narration.text.trim().isEmpty) {
      throw Exception('narration_required');
    }
    state = state.copyWith(submitting: true, error: null);
    try {
      final repo = ref.read(jobRepositoryProvider);
      final id = await repo.createJob(
        userId: user.id,
        options: state.options,
        userPrompt: state.userPrompt,
      );
      state = state.copyWith(submitting: false, jobId: id);
      return id;
    } catch (e) {
      state = state.copyWith(submitting: false, error: e.toString());
      rethrow;
    }
  }
}
