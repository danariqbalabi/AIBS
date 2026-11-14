import 'dart:convert';

class AppConfig {
  const AppConfig({
    this.apiBaseUrl = const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:8000',
    ),
    this.supabaseUrl = const String.fromEnvironment('SUPABASE_URL'),
    this.publishableKey = const String.fromEnvironment(
      'SUPABASE_PUBLISHABLE_KEY',
    ),
  });

  final String apiBaseUrl;
  final String supabaseUrl;
  final String publishableKey;

  String? get error {
    if (supabaseUrl.isEmpty || publishableKey.isEmpty) {
      return 'Konfigurasi Supabase belum diisi. Jalankan dengan config/local.json.';
    }
    if (publishableKey.startsWith('sb_secret_')) {
      return 'Gunakan publishable key, bukan key server.';
    }
    if (publishableKey.split('.').length == 3) {
      try {
        final claims = jsonDecode(
          utf8.decode(
            base64Url.decode(base64Url.normalize(publishableKey.split('.')[1])),
          ),
        ) as Map<String, dynamic>;
        if (claims['role'] != 'anon') {
          return 'Gunakan key client, bukan key server.';
        }
      } catch (_) {
        return 'Key client tidak valid.';
      }
    }
    for (final url in [apiBaseUrl, supabaseUrl]) {
      final parsed = Uri.tryParse(url);
      if (parsed == null ||
          !['http', 'https'].contains(parsed.scheme) ||
          parsed.host.isEmpty) {
        return 'Alamat API atau Supabase tidak valid.';
      }
    }
    return null;
  }
}
