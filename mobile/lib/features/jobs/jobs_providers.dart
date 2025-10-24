import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:leadrole/features/auth/auth_controller.dart';
import 'package:leadrole/features/auth/logic/auth_providers.dart';

import '../../../shared/api_client.dart';

class JobCard {
  final String id;
  final String status;
  final DateTime updatedAt;
  final String? thumbUrl;
  final bool blurred;
  final Map<String, dynamic> raw;

  JobCard({
    required this.id,
    required this.status,
    required this.updatedAt,
    required this.thumbUrl,
    required this.blurred,
    required this.raw,
  });
}

class JobsState {
  final bool loading;
  final String? error;
  final List<JobCard> items;
  final String? nextCursor;
  final bool loadingMore;
  final bool hasActiveJob;

  const JobsState({
    this.loading = false,
    this.error,
    this.items = const [],
    this.nextCursor,
    this.loadingMore = false,
    this.hasActiveJob = false,
  });

  JobsState copyWith({
    bool? loading,
    String? error,
    List<JobCard>? items,
    String? nextCursor,
    bool? loadingMore,
    bool? hasActiveJob,
  }) {
    return JobsState(
      loading: loading ?? this.loading,
      error: error,
      items: items ?? this.items,
      nextCursor: nextCursor ?? this.nextCursor,
      loadingMore: loadingMore ?? this.loadingMore,
      hasActiveJob: hasActiveJob ?? this.hasActiveJob,
    );
  }
}

final jobsControllerProvider = StateNotifierProvider<JobsController, JobsState>(
  (ref) {
    return JobsController(ref)..init();
  },
);

class JobsController extends StateNotifier<JobsState> {
  final Ref ref;
  Timer? _pollTimer;

  JobsController(this.ref) : super(const JobsState());

  ApiClient get _api => ref.read(apiClientProvider);

  String? _userId() => ref.read(authProvider).user?.id;

  void init() {
    _startPolling();
    refresh();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> refresh() async {
    final uid = _userId();
    if (uid == null) {
      state = state.copyWith(
        loading: false,
        error: null,
        items: [],
        nextCursor: null,
        hasActiveJob: false,
      );
      return;
    }
    state = state.copyWith(loading: true, error: null);
    try {
      final res = await _getJobs(uid, limit: 20);
      final cards = res.items.map(_toCard).toList();
      state = state.copyWith(
        loading: false,
        items: cards,
        nextCursor: res.nextCursor,
        hasActiveJob: _hasActive(cards),
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.loadingMore || state.nextCursor == null) return;
    final uid = _userId();
    if (uid == null) return;
    state = state.copyWith(loadingMore: true, error: null);
    try {
      final res = await _getJobs(uid, limit: 20, cursor: state.nextCursor);
      final more = res.items.map(_toCard).toList();
      final merged = [...state.items, ...more];
      state = state.copyWith(
        loadingMore: false,
        items: merged,
        nextCursor: res.nextCursor,
        hasActiveJob: _hasActive(merged),
      );
    } catch (e) {
      state = state.copyWith(loadingMore: false, error: e.toString());
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (!state.hasActiveJob) return;
      final uid = _userId();
      if (uid == null) return;

      try {
        final res = await _getJobs(
          uid,
          limit: state.items.length.clamp(10, 40),
        );
        final fresh = res.items.map(_toCard).toList();

        state = state.copyWith(items: fresh, hasActiveJob: _hasActive(fresh));
      } catch (_) {}
    });
  }

  bool _hasActive(List<JobCard> items) {
    return items.any((j) => !_isTerminal(j.status));
  }

  bool _isTerminal(String status) => status == 'done' || status == 'failed';

  JobCard _toCard(Map<String, dynamic> j) {
    String? url =
        j['assets']?['final_url'] ??
        j['assets']?['lipsync_url'] ??
        j['assets']?['faceswap_url'] ??
        j['assets']?['base_video_url'];

    final status = (j['status'] as String?) ?? 'queued';
    final blurred = status != 'done';

    final updatedMs =
        (j['updated_at'] as num?)?.toInt() ??
        (j['created_at'] as num?)?.toInt() ??
        DateTime.now().millisecondsSinceEpoch;

    return JobCard(
      id: (j['id'] as String?) ?? (j['jobId'] as String?) ?? '',
      status: status,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedMs),
      thumbUrl: url,
      blurred: blurred,
      raw: j,
    );
  }

  Future<_JobsResponse> _getJobs(
    String userId, {
    int limit = 20,
    String? cursor,
  }) async {
    final uri = _api.uri('/api/jobs/list/$userId', {
      'limit': '$limit',
      if (cursor != null) 'cursor': cursor,
    });

    final res = await _httpGet(uri);
    if (res.$1 < 200 || res.$1 >= 300) {
      throw Exception('jobs_${res.$1}');
    }
    final json = jsonDecode(res.$2) as Map<String, dynamic>;
    final items = (json['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final nextCursor = json['nextCursor'] as String?;
    return _JobsResponse(items: items, nextCursor: nextCursor);
  }

  Future<(int, String)> _httpGet(Uri uri) async {
    final client = HttpClient();
    try {
      final req = await client.getUrl(uri);
      final resp = await req.close();
      final body = await resp.transform(const Utf8Decoder()).join();
      return (resp.statusCode, body);
    } finally {
      client.close(force: true);
    }
  }
}

class _JobsResponse {
  final List<Map<String, dynamic>> items;
  final String? nextCursor;
  _JobsResponse({required this.items, required this.nextCursor});
}
