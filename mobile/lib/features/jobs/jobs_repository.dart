import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:leadrole/features/auth/logic/auth_providers.dart';
import 'package:leadrole/features/jobs/data/job_models.dart';
import '../../../shared/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final jobRepositoryProvider = Provider<JobRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return JobRepository(api);
});

class JobRepository {
  final ApiClient api;
  JobRepository(this.api);

  Future<String> createJob({
    required String userId,
    required SceneOptions options,
    String? userPrompt,
  }) async {
    final idem = api.makeIdempotencyKey();
    final res = await http.post(
      api.uri('/api/jobs/create'),
      headers: {'Content-Type': 'application/json', 'Idempotency-Key': idem},
      body: jsonEncode({
        'userId': userId,
        'prompt': userPrompt ?? '',
        'options': options.toJson(),
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('create_job_${res.statusCode}_${res.body}');
    }
    final j = jsonDecode(res.body);
    return j['jobId'] as String;
  }

  Future<JobDetail> getJob(String jobId) async {
    final res = await http.get(api.uri('/api/jobs/$jobId'));
    if (res.statusCode != 200) {
      throw Exception('get_job_${res.statusCode}');
    }
    return JobDetail.fromJson(jsonDecode(res.body));
  }

  Stream<JobDetail> pollJob(
    String jobId, {
    Duration interval = const Duration(seconds: 3),
  }) async* {
    while (true) {
      final detail = await getJob(jobId);
      yield detail;
      if (detail.status == 'done' || detail.status == 'failed') break;
      await Future.delayed(interval);
    }
  }
}
