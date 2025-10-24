import 'dart:convert';
import 'dart:math';

const String kDefaultBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:3000',
);

class ApiClient {
  final String baseUrl;
  const ApiClient({this.baseUrl = kDefaultBaseUrl});

  Uri uri(String path, [Map<String, dynamic>? query]) {
    final norm = path.startsWith('/') ? path : '/$path';
    return Uri.parse(baseUrl).replace(path: norm, queryParameters: query);
  }

  String makeIdempotencyKey() {
    final rand = Random();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }
}
