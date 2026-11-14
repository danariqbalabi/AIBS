import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiFailure implements Exception {
  const ApiFailure(this.message, {this.status, this.code});
  final String message;
  final int? status;
  final String? code;
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({
    required this.baseUrl,
    required this.accessToken,
    this.refreshSession,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final Future<String?> Function() accessToken;
  final Future<void> Function()? refreshSession;
  final http.Client _client;

  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    String? idempotencyKey,
  }) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      final token = await accessToken();
      if (token == null || token.isEmpty) {
        throw const ApiFailure('Silakan masuk terlebih dahulu.', status: 401);
      }
      final request = http.Request(
        method,
        Uri.parse('${baseUrl.replaceFirst(RegExp(r'/+$'), '')}$path'),
      );
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Idempotency-Key': ?idempotencyKey,
      });
      if (body != null) request.body = jsonEncode(body);
      http.Response response;
      try {
        response = await http.Response.fromStream(
          await _client.send(request).timeout(const Duration(seconds: 20)),
        ).timeout(const Duration(seconds: 20));
      } on TimeoutException {
        throw const ApiFailure(
          'Koneksi terlalu lama. Input kamu tetap tersedia.',
        );
      } on http.ClientException {
        throw const ApiFailure('Backend belum bisa dihubungi. Coba lagi.');
      }
      if (response.statusCode == 401 &&
          attempt == 0 &&
          refreshSession != null) {
        await refreshSession!();
        continue;
      }
      Map<String, dynamic> decoded = {};
      try {
        if (response.body.isNotEmpty) {
          decoded = jsonDecode(response.body) as Map<String, dynamic>;
        }
      } on FormatException {
        throw const ApiFailure('Respons backend belum bisa dibaca.');
      } on TypeError {
        throw const ApiFailure('Respons backend belum bisa dibaca.');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final error = decoded['error'];
        throw ApiFailure(
          error is Map
              ? error['message'] as String? ?? 'Permintaan belum berhasil.'
              : 'Permintaan belum berhasil.',
          status: response.statusCode,
          code: error is Map ? error['code'] as String? : null,
        );
      }
      return decoded;
    }
    throw const ApiFailure(
      'Sesi berakhir. Silakan masuk kembali.',
      status: 401,
    );
  }

  void close() => _client.close();
}
