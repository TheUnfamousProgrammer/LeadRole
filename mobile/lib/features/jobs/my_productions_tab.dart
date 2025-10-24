import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:leadrole/features/jobs/jobs_providers.dart';

import '../../../shared/colors.dart';

class MyProductionTab extends ConsumerStatefulWidget {
  const MyProductionTab({super.key});

  @override
  ConsumerState<MyProductionTab> createState() => _MyProductionTabState();
}

class _MyProductionTabState extends ConsumerState<MyProductionTab> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    final st = ref.read(jobsControllerProvider);
    if (_scrollCtrl.position.pixels >
            _scrollCtrl.position.maxScrollExtent - 400 &&
        !st.loadingMore &&
        st.nextCursor != null) {
      ref.read(jobsControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(jobsControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.neon,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.movie_creation_outlined),
        label: const Text('New Production'),
        onPressed: st.hasActiveJob
            ? null
            : () {
                context.push('/produce');
              },
      ),
      body: RefreshIndicator(
        color: AppColors.neon,
        onRefresh: () => ref.read(jobsControllerProvider.notifier).refresh(),
        child: Builder(
          builder: (_) {
            if (st.loading && st.items.isEmpty) {
              return const _CenterLoader(label: 'Fetching your productions...');
            }
            if (st.error != null && st.items.isEmpty) {
              return _ErrorView(
                message: st.error!,
                onRetry: () =>
                    ref.read(jobsControllerProvider.notifier).refresh(),
              );
            }
            if (st.items.isEmpty) {
              return _EmptyView(
                hasActive: st.hasActiveJob,
                onNew: st.hasActiveJob ? null : () => context.push('/produce'),
              );
            }

            return ListView.separated(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: st.items.length + (st.loadingMore ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index >= st.items.length) {
                  return const _ListLoader();
                }
                final job = st.items[index];
                return _JobCard(
                  job: job,
                  onTap: () => context.push('/jobs/${job.id}'),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// --- widgets ---

class _JobCard extends StatelessWidget {
  final JobCard job;
  final VoidCallback onTap;

  const _JobCard({required this.job, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusChip = _StatusChip(status: job.status);
    final thumb = job.thumbUrl;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F1F),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.neon.withOpacity(0.12)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: SizedBox(
                width: 120,
                height: 160,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (thumb != null)
                      Image.network(
                        thumb,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _thumbFallback(),
                      )
                    else
                      _thumbFallback(),
                    if (job.blurred)
                      BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                        child: Container(color: Colors.black.withOpacity(0)),
                      ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Icon(
                        job.status == 'done'
                            ? Icons.play_circle_outline
                            : Icons.timelapse,
                        color: Colors.white.withOpacity(0.9),
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    statusChip,
                    const SizedBox(height: 8),
                    Text(
                      _titleFor(job.status),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _subtitleFor(job.status),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _ago(job.updatedAt),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbFallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.neon.withOpacity(0.2), const Color(0xFF2A2A2A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  String _titleFor(String status) {
    switch (status) {
      case 'queued':
      case 'validating_inputs':
        return 'Queued for Studio';
      case 'generating_base_video':
        return 'Shooting Your Scene (Luma)';
      case 'faceswap':
        return 'Casting Face to Lead';
      case 'tts_generating':
        return 'Recording Voiceover';
      case 'lipsync':
        return 'Lip-Syncing Performance';
      case 'watermarking':
        return 'Final Touch: Badge';
      case 'done':
        return 'Premiere Ready';
      case 'failed':
      default:
        return 'Production Halted';
    }
  }

  String _subtitleFor(String status) {
    switch (status) {
      case 'queued':
        return 'Your production is lined up.';
      case 'validating_inputs':
        return 'Checking script and headshots.';
      case 'generating_base_video':
        return 'Camera’s rolling. Keep your seat.';
      case 'faceswap':
        return 'Integrating your headshot into the take.';
      case 'tts_generating':
        return 'Narrator in the booth.';
      case 'lipsync':
        return 'Matching lips to lines.';
      case 'watermarking':
        return 'Branding the final cut.';
      case 'done':
        return 'Tap to view your scene.';
      case 'failed':
      default:
        return 'Tap to see error & retry options.';
    }
  }

  String _ago(DateTime dt) {
    final s = DateTime.now().difference(dt).inSeconds;
    if (s < 60) return '${s}s ago';
    final m = (s / 60).floor();
    if (m < 60) return '${m}m ago';
    final h = (m / 60).floor();
    if (h < 24) return '${h}h ago';
    final d = (h / 24).floor();
    return '${d}d ago';
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = _map(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 11.5,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  (Color, Color, String) _map(String s) {
    switch (s) {
      case 'done':
        return (const Color(0xFF0F5132), const Color(0xFF7CF5B9), 'FINAL CUT');
      case 'failed':
        return (const Color(0xFF4B1D1D), const Color(0xFFFF8A8A), 'HALTED');
      case 'queued':
      case 'validating_inputs':
        return (const Color(0xFF2A2A2A), AppColors.neon, 'QUEUED');
      case 'generating_base_video':
        return (const Color(0xFF11212A), const Color(0xFF77E1FF), 'SHOOTING');
      case 'faceswap':
        return (const Color(0xFF1F1530), const Color(0xFFB794F4), 'CASTING');
      case 'tts_generating':
        return (const Color(0xFF1E2B1E), const Color(0xFFB9FF66), 'VOICEOVER');
      case 'lipsync':
        return (const Color(0xFF282018), const Color(0xFFFFD27A), 'LIP SYNC');
      case 'watermarking':
        return (const Color(0xFF222222), const Color(0xFFE2E2E2), 'BRANDING');
      default:
        return (const Color(0xFF2A2A2A), Colors.white70, s.toUpperCase());
    }
  }
}

class _CenterLoader extends StatelessWidget {
  final String label;
  const _CenterLoader({required this.label});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CupertinoActivityIndicator(radius: 16, color: AppColors.neon),
          const SizedBox(height: 14),
          Text(label, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _ListLoader extends StatelessWidget {
  const _ListLoader();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: CupertinoActivityIndicator(radius: 16, color: AppColors.neon),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final bool hasActive;
  final VoidCallback? onNew;
  const _EmptyView({required this.hasActive, required this.onNew});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 120),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                AppColors.neon.withOpacity(0.18),
                const Color(0xFF2B2B2B),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: AppColors.neon.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.movie_filter_outlined,
                size: 56,
                color: Colors.white,
              ),
              const SizedBox(height: 12),
              const Text(
                'No productions yet',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                hasActive
                    ? 'A scene is currently in production. You’ll see it here soon.'
                    : 'Kick off your first scene. We’ll guide you like a director would.',
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onNew,
                icon: const Icon(Icons.add),
                label: const Text('Start a New Production'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neon,
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 120),
      children: [
        Text(
          'Error: $message',
          style: const TextStyle(color: Colors.redAccent),
        ),
        const SizedBox(height: 10),
        ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
  }
}
