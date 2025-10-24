import 'package:equatable/equatable.dart';

class JobVideoSpec extends Equatable {
  final String aspectRatio;
  final String duration;
  final String resolution;
  const JobVideoSpec({
    this.aspectRatio = '9:16',
    this.duration = '5s',
    this.resolution = '720p',
  });
  Map<String, dynamic> toJson() => {
    'aspect_ratio': aspectRatio,
    'duration': duration,
    'resolution': resolution,
  };
  @override
  List<Object?> get props => [aspectRatio, duration, resolution];
}

class SceneOptions {
  final String sceneType;
  final String location;
  final String mood;
  final String cameraStyle;
  final String lighting;
  final String outfit;
  final JobVideoSpec video;
  final NarrationOptions narration;

  const SceneOptions({
    this.sceneType = 'Vlog',
    this.location = '',
    this.mood = '',
    this.cameraStyle = 'SelfieVlog',
    this.lighting = '',
    this.outfit = '',
    this.video = const JobVideoSpec(),
    this.narration = const NarrationOptions(),
  });

  SceneOptions copyWith({
    String? sceneType,
    String? location,
    String? mood,
    String? cameraStyle,
    String? lighting,
    String? outfit,
    JobVideoSpec? video,
    NarrationOptions? narration,
  }) {
    return SceneOptions(
      sceneType: sceneType ?? this.sceneType,
      location: location ?? this.location,
      mood: mood ?? this.mood,
      cameraStyle: cameraStyle ?? this.cameraStyle,
      lighting: lighting ?? this.lighting,
      outfit: outfit ?? this.outfit,
      video: video ?? this.video,
      narration: narration ?? this.narration,
    );
  }

  Map<String, dynamic> toJson() => {
    'sceneType': sceneType,
    'location': location,
    'mood': mood,
    'cameraStyle': cameraStyle,
    'lighting': lighting,
    'outfit': outfit,
    'video': video.toJson(),
    'narration': narration.toJson(),
  };
}

class NarrationOptions extends Equatable {
  final String text;
  final String voiceProfile;
  final String language;
  final double? speed;

  const NarrationOptions({
    this.text = '',
    this.voiceProfile = 'NarrationMale',
    this.language = 'en',
    this.speed,
  });

  NarrationOptions copyWith({
    String? text,
    String? voiceProfile,
    String? language,
    double? speed,
  }) {
    return NarrationOptions(
      text: text ?? this.text,
      voiceProfile: voiceProfile ?? this.voiceProfile,
      language: language ?? this.language,
      speed: speed ?? this.speed,
    );
  }

  Map<String, dynamic> toJson() => {
    'text': text,
    'voice_profile': voiceProfile,
    'language': language,
    if (speed != null) 'speed': speed,
  };

  @override
  List<Object?> get props => [text, voiceProfile, language, speed];
}

class JobSummary {
  final String id;
  final String status;
  final String? thumb;
  final DateTime createdAt;

  JobSummary({
    required this.id,
    required this.status,
    this.thumb,
    required this.createdAt,
  });

  factory JobSummary.fromJson(Map<String, dynamic> j) => JobSummary(
    id: j['id'] ?? j['jobId'] ?? '',
    status: j['status'] ?? 'queued',
    thumb: j['assets']?['image'] ?? j['assets']?['progress_thumb'],
    createdAt: DateTime.fromMillisecondsSinceEpoch(
      (j['created_at'] ?? 0) as int,
    ),
  );
}

class JobDetail {
  final String id;
  final String status;
  final String? error;
  final Map<String, dynamic> assets;
  final Map<String, dynamic>? narrationPlan;

  JobDetail({
    required this.id,
    required this.status,
    required this.assets,
    this.error,
    this.narrationPlan,
  });

  factory JobDetail.fromJson(Map<String, dynamic> j) => JobDetail(
    id: j['id'] ?? '',
    status: j['status'] ?? 'queued',
    error: j['error']?['message'],
    assets: (j['assets'] ?? {}) as Map<String, dynamic>,
    narrationPlan: j['narration_plan'] as Map<String, dynamic>?,
  );
}
