import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter/cupertino.dart';
import '../../shared/colors.dart';

const _dummyVideos = <String>[
  'https://customer-gjxf746dssxs437i.cloudflarestream.com/5e3edfb8545894be984e2f17e4afbd14/downloads/default.mp4',

  'https://customer-gjxf746dssxs437i.cloudflarestream.com/908ce6d222b95dd1be2ea3b7fbac85ff/downloads/default.mp4',
];

class DiscoverTab extends StatefulWidget {
  const DiscoverTab({super.key});
  @override
  State<DiscoverTab> createState() => _DiscoverTabState();
}

class _DiscoverTabState extends State<DiscoverTab> {
  final _ctrls = <int, VideoPlayerController>{};
  final _page = PageController();

  @override
  void initState() {
    super.initState();
    _preload(0);
  }

  void _preload(int index) async {
    if (index < 0 || index >= _dummyVideos.length) return;
    if (_ctrls[index] != null) return;

    final file = await DefaultCacheManager().getSingleFile(_dummyVideos[index]);
    final controller = VideoPlayerController.file(file);
    controller.setLooping(true);
    controller.initialize().then((_) {
      setState(() {});
      controller.play();
    });
    _ctrls[index] = controller;
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _page,
      scrollDirection: Axis.vertical,
      itemCount: _dummyVideos.length,
      onPageChanged: (i) => _preload(i + 1),
      itemBuilder: (_, i) {
        final c = _ctrls[i];
        return Container(
          color: Colors.black,
          child: Stack(
            children: [
              if (c != null && c.value.isInitialized)
                Center(
                  child: AspectRatio(
                    aspectRatio: c.value.aspectRatio,
                    child: VideoPlayer(c),
                  ),
                )
              else
                const Center(child: CupertinoActivityIndicator()),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.black54],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          _StubBadge(text: '@leadrole_user'),
                          SizedBox(height: 8),
                          _StubBadge(text: 'Cinematic vlog • Tokyo'),
                        ],
                      ),
                      Column(
                        children: const [
                          _StubIcon(icon: Icons.favorite, label: '1.2k'),
                          SizedBox(height: 12),
                          _StubIcon(icon: Icons.mode_comment, label: '112'),
                          SizedBox(height: 12),
                          _StubIcon(icon: Icons.share, label: 'Share'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StubBadge extends StatelessWidget {
  final String text;
  const _StubBadge({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.neon.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _StubIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StubIcon({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.neon, size: 32),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
