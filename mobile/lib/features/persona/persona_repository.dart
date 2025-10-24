import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:leadrole/shared/constants.dart';

import 'persona_model.dart';

class PersonaRepository {
  static const String _baseUrl = String.fromEnvironment(
    'LEADROLE_API_BASE',
    defaultValue: 'http://localhost:3000',
  );
  Future<String> uploadSelfieToCloudinary(File file) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/${AppConfig.cloudinaryCloudName}/image/upload',
    );
    final req = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = AppConfig.cloudinaryUnsignedPreset
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final resp = await req.send();
    final body = await resp.stream.bytesToString();

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final url = json['secure_url'] as String?;
      if (url == null) throw Exception('cloudinary_missing_secure_url');
      return url;
    } else {
      throw Exception('cloudinary_upload_failed_${resp.statusCode}_$body');
    }
  }

  Future<void> savePersona(Persona p) async {
    final uri = Uri.parse('$_baseUrl/api/persona/put');
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(p.toJson()),
    );
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return;
    } else {
      throw Exception('save_persona_failed_${resp.statusCode}_${resp.body}');
    }
  }
}
