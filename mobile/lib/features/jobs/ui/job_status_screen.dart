import 'dart:io';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import 'package:leadrole/features/jobs/jobs_repository.dart';
import 'package:leadrole/features/jobs/data/job_models.dart';
import 'package:leadrole/shared/colors.dart';

class JobStatusScreen extends ConsumerStatefulWidget {
  final String jobId;
  const JobStatusScreen({super.key, required this.jobId});

  @override
  ConsumerState<JobStatusScreen> createState() => _JobStatusScreenState();
}

class _JobStatusScreenState extends ConsumerState<JobStatusScreen> {
  late final Stream<JobDetail> _stream;

  @override
  void initState() {
    super.initState();
    _stream = ref.read(jobRepositoryProvider).pollJob(widget.jobId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => context.pushReplacement('/dashboard'),
        ),
        title: const Text('Production Monitor'),
      ),
      body: StreamBuilder<JobDetail>(
        stream: _stream,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const _LoadingState();
          }

          final job = snap.data!;
          final status = job.status;
          final hasFinal = job.assets['final_url'] != null || status == 'done';
          final playableUrl =
              job.assets['final_url'] ??
              job.assets['lipsync_url'] ??
              job.assets['faceswap_url'];

          final showProgressReel =
              !hasFinal &&
              (job.assets['progress_video_url'] != null ||
                  job.assets['progress_thumb_url'] != null ||
                  job.assets['image'] != null);

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Header(jobId: job.id, status: status),
                      const SizedBox(height: 12),
                      _DirectorLog(status: status, job: job),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // Progress reel (video/image) — only visible while pipeline is running
              if (showProgressReel)
                SliverToBoxAdapter(
                  child: _ProgressReel(
                    job: job,
                    blur: true,
                    targetHeight: MediaQuery.of(context).size.height * 0.36,
                  ),
                ),

              // Optional image dailies strip during base gen
              if (!hasFinal) SliverToBoxAdapter(child: _DailiesStrip(job: job)),

              // Timeline with current step highlighted + done steps green
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: _Timeline(job: job),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (status == 'failed' && job.error != null)
                        _ErrorCard(message: job.error!),

                      if (status == 'done' && playableUrl != null) ...[
                        _InlinePlayer(url: playableUrl),
                        const SizedBox(height: 12),
                        _DownloadRow(
                          url: playableUrl,
                          fileName: 'leadrole-${job.id}.mp4',
                        ),
                      ] else if (status != 'failed') ...[
                        _WaitingCut(status: status),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String jobId;
  final String status;
  const _Header({required this.jobId, required this.status});

  @override
  Widget build(BuildContext context) {
    final label = _statusLabel(status);
    return Row(
      children: [
        Expanded(
          child: Text(
            'Director’s Monitor',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 22,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.neon.withOpacity(0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.neon.withOpacity(0.45)),
          ),
          child: Text(label, style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'queued':
      case 'generating_base_video':
      case 'luma_generating':
      case 'luma_polling':
        return 'Shooting Base 🎥';
      case 'base_ready':
        return 'Base Ready ✅';
      case 'faceswap_running':
      case 'faceswap':
        return 'Casting & Face Swap 🎭';
      case 'faceswap_done':
        return 'Face Swap Done ✅';
      case 'tts_generating':
        return 'Recording VO 🎙️';
      case 'tts_done':
        return 'VO Ready ✅';
      case 'lipsync_running':
      case 'lipsync':
        return 'ADR & Lip Sync 🔊';
      case 'lipsync_done':
        return 'ADR Done ✅';
      case 'watermarking':
        return 'Final Touches ✨';
      case 'done':
        return 'Picture Lock ✅';
      case 'failed':
        return 'Production Halted ❌';
      default:
        return s;
    }
  }
}

class _DirectorLog extends StatelessWidget {
  final String status;
  final JobDetail job;
  const _DirectorLog({required this.status, required this.job});

  @override
  Widget build(BuildContext context) {
    final copy = _friendly(status, job);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.neon.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(copy, style: const TextStyle(color: Colors.white)),
    );
  }

  String _friendly(String s, JobDetail j) {
    switch (s) {
      case 'queued':
        return '🎬 Slate is up. Your scene is queued — lights, camera, vibes.';
      case 'generating_base_video':
      case 'luma_generating':
      case 'luma_polling':
        return '🎥 Shooting the master shot with our virtual crew. Dailies appear below.';
      case 'base_ready':
        return '✅ Base reel is in the can. Moving your star to the front with face casting.';
      case 'faceswap_running':
      case 'faceswap':
        return '🎭 Casting underway — applying your headshots to the hero in frame.';
      case 'faceswap_done':
        return '✅ Casting locked. If narration is set, we’re heading to VO.';
      case 'tts_generating':
        return '🎙️ VO session in progress — tone, pace, presence.';
      case 'tts_done':
        return '✅ VO approved. ADR next (lip sync to performance).';
      case 'lipsync_running':
      case 'lipsync':
        return '🔊 ADR pass running — aligning lips & micro-expressions.';
      case 'lipsync_done':
        return '✅ ADR pass approved. Final watermark & export incoming.';
      case 'watermarking':
        return '✨ Final color + branding pass. Prepping a streamable master.';
      case 'done':
        return '🏁 Picture lock! Your reel is ready to screen & share.';
      case 'failed':
        final msg = j.error ?? 'Unexpected production halt.';
        return '❌ Production halted. Floor note: $msg';
      default:
        return '🎞️ Processing your reel...';
    }
  }
}

/// -------------------------------------------
/// Progress Reel (video or poster), blurred.
/// Fit-height layout; disappears when final is ready.
/// -------------------------------------------
class _ProgressReel extends StatefulWidget {
  final JobDetail job;
  final bool blur;
  final double targetHeight; // e.g. MediaQuery.height * 0.36

  const _ProgressReel({
    required this.job,
    required this.blur,
    this.targetHeight = 260,
  });

  @override
  State<_ProgressReel> createState() => _ProgressReelState();
}

class _ProgressReelState extends State<_ProgressReel> {
  VideoPlayerController? _vc;
  bool _ready = false;

  String? get _videoUrl =>
      (widget.job.assets['progress_video_url'] as String?) ?? null;

  String? get _thumbUrl =>
      (widget.job.assets['progress_thumb_url'] as String?) ??
      (widget.job.assets['image'] as String?);

  @override
  void initState() {
    super.initState();
    _maybeInit();
  }

  @override
  void didUpdateWidget(covariant _ProgressReel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_vc == null && _videoUrl != null) _maybeInit();
  }

  void _maybeInit() {
    final url = _videoUrl;
    if (url != null && url.toLowerCase().endsWith('.mp4')) {
      _vc = VideoPlayerController.networkUrl(Uri.parse(url))
        ..setLooping(true)
        ..setVolume(0)
        ..initialize().then((_) {
          _vc?.play();
          if (mounted) setState(() => _ready = true);
        });
    }
  }

  @override
  void dispose() {
    _vc?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Nothing to show
    if (_videoUrl == null && _thumbUrl == null) {
      return const SizedBox.shrink();
    }

    // Compute width from target height using aspect ratio
    final ar = (_ready && _vc != null && _vc!.value.isInitialized)
        ? _vc!.value.aspectRatio
        : (9 / 16);
    final h = widget.targetHeight;
    final w = h * ar;

    final media = SizedBox(
      height: h,
      width: w,
      child: _videoUrl != null
          ? (_ready
                ? VideoPlayer(_vc!)
                : const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ))
          : ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                _thumbUrl!,
                height: h,
                width: w,
                fit: BoxFit.fitHeight,
              ),
            ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              SizedBox(height: h, width: w, child: media),
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: true,
                  child: ImageFiltered(
                    imageFilter: widget.blur
                        ? ImageFilter.blur(sigmaX: 10, sigmaY: 10)
                        : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                    child: const SizedBox.shrink(),
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Text(
                    'Dailies (blurred)',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// -------------------------------------------
/// Optional dailies strip (images) during base gen
/// -------------------------------------------
class _DailiesStrip extends StatelessWidget {
  final JobDetail job;
  const _DailiesStrip({required this.job});

  @override
  Widget build(BuildContext context) {
    final progressList =
        (job.assets['luma_progress'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>() ??
        const [];

    final images = <String>[];
    for (final p in progressList) {
      final img = p['image'] as String?;
      if (img != null) images.add(img);
    }
    final fallback = job.assets['image'] as String?;
    if (images.isEmpty && fallback != null) images.add(fallback);

    if (images.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 110,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (ctx, i) {
          final url = images[i];
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                SizedBox(
                  width: 180,
                  height: 110,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Image.network(url, fit: BoxFit.cover),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white12),
                        color: Colors.black.withOpacity(0.05),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// -------------------------------------------
/// Timeline — highlights current step (spinner),
/// done steps green, pending grey
/// -------------------------------------------
class _Timeline extends StatelessWidget {
  final JobDetail job;
  const _Timeline({required this.job});

  @override
  Widget build(BuildContext context) {
    final steps = _buildSteps(job);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neon.withOpacity(0.2)),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(14),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: steps.length,
        separatorBuilder: (_, __) => Divider(color: Colors.white10, height: 20),
        itemBuilder: (_, i) => _TimelineRow(step: steps[i]),
      ),
    );
  }

  List<_Step> _buildSteps(JobDetail j) {
    final s = j.status;

    _StepState tagState(String tag) {
      // “running” if it exactly matches
      if (s == tag) return _StepState.running;

      // simplify a few grouped tags
      final groups = <String, List<String>>{
        'luma_block': [
          'generating_base_video',
          'luma_generating',
          'luma_polling',
        ],
        'faceswap_block': ['faceswap_running', 'faceswap'],
        'lipsync_block': ['lipsync_running', 'lipsync'],
      };

      bool isIn(String label) => groups[label]?.contains(s) ?? false;

      switch (tag) {
        case 'luma_block':
          if (isIn('luma_block')) return _StepState.running;
          if (_after(s, 'base_ready')) return _StepState.done;
          return _StepState.pending;
        case 'base_ready':
          if (s == 'base_ready') return _StepState.running;
          if (_after(s, 'base_ready')) return _StepState.done;
          return _StepState.pending;
        case 'faceswap_done':
          if (isIn('faceswap_block')) return _StepState.running;
          if (_after(s, 'faceswap_done')) return _StepState.done;
          return _StepState.pending;
        case 'tts_done':
          if (s == 'tts_generating') return _StepState.running;
          if (_after(s, 'tts_done')) return _StepState.done;
          return _StepState.pending;
        case 'lipsync_done':
          if (isIn('lipsync_block')) return _StepState.running;
          if (_after(s, 'lipsync_done')) return _StepState.done;
          return _StepState.pending;
        case 'watermarking':
          if (s == 'watermarking') return _StepState.running;
          if (_after(s, 'watermarking') || _after(s, 'done'))
            return _StepState.done;
          return _StepState.pending;
        case 'done':
          return s == 'done' ? _StepState.done : _StepState.pending;
        default:
          return _StepState.pending;
      }
    }

    return [
      _Step(
        icon: '🎥',
        title: 'Master Shot (Luma)',
        tag: 'luma_block',
        state: tagState('luma_block'),
        blurb: 'We film your base scene — composition, motion, and light.',
      ),
      _Step(
        icon: '📤',
        title: 'Upload Base',
        tag: 'base_ready',
        state: tagState('base_ready'),
        blurb: 'We archive a stable copy for the studio preview.',
      ),
      _Step(
        icon: '🎭',
        title: 'Casting (Face Swap)',
        tag: 'faceswap_done',
        state: tagState('faceswap_done'),
        blurb: 'Your headshot becomes the star of the scene.',
      ),
      _Step(
        icon: '🎙️',
        title: 'Voiceover (TTS)',
        tag: 'tts_done',
        state: tagState('tts_done'),
        blurb: 'We record narration with your chosen voice & pacing.',
      ),
      _Step(
        icon: '🔊',
        title: 'ADR (Lip Sync)',
        tag: 'lipsync_done',
        state: tagState('lipsync_done'),
        blurb: 'We align lips & micro-expressions to the VO.',
      ),
      _Step(
        icon: '✨',
        title: 'Final Cut (Watermark)',
        tag: 'watermarking',
        state: tagState('watermarking'),
        blurb: 'Tasteful branding + fast-start export.',
      ),
      _Step(
        icon: '🏁',
        title: 'Picture Lock',
        tag: 'done',
        state: tagState('done'),
        blurb: 'Your reel is ready to screen & share.',
      ),
    ];
  }

  // Rank order for “after” calculation
  bool _after(String status, String tag) {
    const order = [
      'queued',
      'generating_base_video',
      'luma_generating',
      'luma_polling',
      'base_ready',
      'faceswap_running',
      'faceswap',
      'faceswap_done',
      'tts_generating',
      'tts_done',
      'lipsync_running',
      'lipsync',
      'lipsync_done',
      'watermarking',
      'done',
      'failed',
    ];
    int idx(String s) => order.indexOf(s);
    final si = idx(status);
    final ti = idx(tag);
    if (si < 0 || ti < 0) return false;
    return si > ti;
  }
}

enum _StepState { pending, running, done }

class _Step {
  final String icon;
  final String title;
  final String tag;
  final _StepState state;
  final String blurb;

  _Step({
    required this.icon,
    required this.title,
    required this.tag,
    required this.state,
    required this.blurb,
  });
}

class _TimelineRow extends StatelessWidget {
  final _Step step;
  const _TimelineRow({required this.step});

  @override
  Widget build(BuildContext context) {
    final Color dotColor = switch (step.state) {
      _StepState.pending => Colors.white24,
      _StepState.running => AppColors.neon,
      _StepState.done => Colors.greenAccent,
    };

    final Widget trail = switch (step.state) {
      _StepState.running => const SizedBox(
        height: 16,
        width: 16,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      ),
      _StepState.done => const Icon(
        Icons.check_circle,
        color: Colors.greenAccent,
        size: 18,
      ),
      _StepState.pending => const SizedBox.shrink(),
    };

    final String sub = switch (step.state) {
      _StepState.pending => 'In queue...',
      _StepState.running => 'Rolling...',
      _StepState.done => 'Wrapped.',
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // dot
        Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        // titles
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '${step.icon}  ${step.title}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  trail,
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${step.blurb}  $sub',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// -------------------------------------------
/// Inline result player (final or latest playable)
/// -------------------------------------------
class _InlinePlayer extends StatefulWidget {
  final String url;
  const _InlinePlayer({required this.url});

  @override
  State<_InlinePlayer> createState() => _InlinePlayerState();
}

class _InlinePlayerState extends State<_InlinePlayer> {
  late final VideoPlayerController _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (mounted) setState(() => _ready = true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ar = _ready ? _controller.value.aspectRatio : (9 / 16);
    return AspectRatio(
      aspectRatio: ar,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.neon.withOpacity(0.25)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            if (_ready)
              VideoPlayer(_controller)
            else
              const Center(child: CircularProgressIndicator()),
            if (_ready)
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _controller.value.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          _controller.value.isPlaying
                              ? _controller.pause()
                              : _controller.play();
                        });
                      },
                    ),
                    const Spacer(),
                    Text(
                      _format(_controller.value.position) +
                          ' / ' +
                          _format(_controller.value.duration),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _format(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }
}

/// -------------------------------------------
/// Download row with progress + open
/// -------------------------------------------
class _DownloadRow extends ConsumerStatefulWidget {
  final String url;
  final String fileName;
  const _DownloadRow({required this.url, required this.fileName});

  @override
  ConsumerState<_DownloadRow> createState() => _DownloadRowState();
}

class _DownloadRowState extends ConsumerState<_DownloadRow> {
  double _progress = 0;
  bool _downloading = false;
  File? _file;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_downloading)
          LinearProgressIndicator(
            value: _progress,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation(AppColors.neon),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _downloading ? null : _startDownload,
                icon: const Icon(Icons.download),
                label: Text(
                  _downloading
                      ? 'Downloading... ${(_progress * 100).toStringAsFixed(0)}%'
                      : 'Download MP4',
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (_file != null)
              OutlinedButton.icon(
                onPressed: () => OpenFilex.open(_file!.path),
                icon: const Icon(Icons.play_circle_outline),
                label: const Text('Open'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.neon,
                  side: BorderSide(color: AppColors.neon.withOpacity(0.6)),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _startDownload() async {
    setState(() {
      _downloading = true;
      _progress = 0;
    });

    try {
      final dio = Dio();
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/${widget.fileName}';
      await dio.download(
        widget.url,
        path,
        onReceiveProgress: (recv, total) {
          if (total > 0) {
            setState(() => _progress = recv / total);
          }
        },
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (s) => s != null && s < 500,
        ),
      );
      setState(() => _file = File(path));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Download failed: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }
}

class _WaitingCut extends StatelessWidget {
  final String status;
  const _WaitingCut({required this.status});

  @override
  Widget build(BuildContext context) {
    final txt = switch (status) {
      'queued' => 'Queued on the call sheet...',
      'generating_base_video' ||
      'luma_generating' ||
      'luma_polling' => 'Shooting base plates...',
      'faceswap_running' || 'faceswap' => 'Casting your star into the scene...',
      'tts_generating' => 'Recording voiceover...',
      'lipsync_running' || 'lipsync' => 'ADR session in progress...',
      'watermarking' => 'Final polish...',
      _ => 'Working...',
    };
    return Container(
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.neon.withOpacity(0.08),
        border: Border.all(color: AppColors.neon.withOpacity(0.25)),
      ),
      child: Text(txt, style: const TextStyle(color: Colors.white70)),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Production halted: $message',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: const [
          SizedBox(height: 40),
          CupertinoActivityIndicator(radius: 16, color: Colors.white70),
          SizedBox(height: 12),
          Text(
            'Queuing production status...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'In-Depth Details will be available shortly.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
