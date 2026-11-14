import 'package:supabase_flutter/supabase_flutter.dart';

import 'api_client.dart';
import 'app_config.dart';
import 'profile_repository.dart';
import 'session_identity.dart';
import '../pages/profile_setup_flow.dart';

class AppServices {
  AppServices(this.api, this.auth, {this.setupError, SessionIdentity? identity})
    : profiles = ProfileRepository(api),
      identity = identity ?? SupabaseSessionIdentity(auth, setupError);

  final ApiClient api;
  final SupabaseClient? auth;
  final String? setupError;
  final ProfileRepository profiles;
  final SessionIdentity identity;

  static Future<AppServices> create(AppConfig config) async {
    SupabaseClient? client;
    var error = config.error;
    if (error == null) {
      try {
        await Supabase.initialize(
          url: config.supabaseUrl,
          publishableKey: config.publishableKey,
          debug: false,
        );
        client = Supabase.instance.client;
      } catch (_) {
        error =
            'Sesi Supabase belum bisa dipulihkan. Coba buka ulang aplikasi.';
      }
    }
    final api = ApiClient(
      baseUrl: config.apiBaseUrl,
      accessToken: () async {
        if (client == null) {
          throw ApiFailure(error ?? 'Konfigurasi Supabase belum tersedia.');
        }
        return client.auth.currentSession?.accessToken;
      },
      refreshSession: () async {
        try {
          await client?.auth.refreshSession();
        } catch (_) {
          throw const ApiFailure(
            'Sesi berakhir. Silakan masuk kembali.',
            status: 401,
          );
        }
      },
    );
    return AppServices(api, client, setupError: error);
  }

  SupabaseClient get client {
    if (auth == null) {
      throw ApiFailure(setupError ?? 'Konfigurasi Supabase belum diisi.');
    }
    return auth!;
  }

  Future<void> sendCode(String email) =>
      client.auth.signInWithOtp(email: email);

  Future<void> verifyCode(String email, String code) async {
    await client.auth.verifyOTP(email: email, token: code, type: OtpType.email);
  }

  String? _linkingSubject;

  Future<void> beginEmailLink(String email) async {
    if (!identity.hasSession || !identity.isAnonymous) {
      throw const ApiFailure(
        'Gunakan sesi demo aktif untuk menghubungkan email.',
      );
    }
    _linkingSubject = client.auth.currentUser!.id;
    await client.auth.updateUser(UserAttributes(email: email.trim()));
  }

  Future<ProfileSetupAnswers> confirmEmailLink(
    String email,
    String code,
  ) async {
    final subject = _linkingSubject;
    if (subject == null || client.auth.currentUser?.id != subject) {
      throw const ApiFailure('Sesi berubah. Mulai hubungkan email kembali.');
    }
    await client.auth.verifyOTP(
      email: email.trim(),
      token: code,
      type: OtpType.emailChange,
    );
    await client.auth.refreshSession();
    if (client.auth.currentUser?.id != subject || identity.isAnonymous) {
      throw const ApiFailure(
        'Email belum terverifikasi. Catatan tetap berada di sesi sebelumnya.',
      );
    }
    final profile = await profiles.restore(identity.email);
    if (profile == null) {
      throw const ApiFailure(
        'Profil belum bisa dimuat. Coba buka ulang aplikasi.',
      );
    }
    _linkingSubject = null;
    return profile;
  }

  Future<void> signOut() async {
    await identity.signOut();
    profiles.clear();
  }

  Future<ProfileSetupAnswers> openDemo(String template) async {
    if (identity.hasSession) {
      if (!identity.isAnonymous) {
        throw const ApiFailure(
          'Keluar dari akun saat ini sebelum mencoba demo.',
        );
      }
      final existing = await profiles.restore(identity.email);
      if (existing != null) {
        if (profiles.rawProfile?['demo_template'] != template) {
          throw const ApiFailure(
            'Sesi demo lain masih aktif. Keluar terlebih dahulu untuk mengganti profil.',
          );
        }
        return existing;
      }
    } else {
      profiles.clear();
      await identity.signInAnonymously();
    }
    await api.request(
      'POST',
      '/api/v1/demo/sessions',
      body: {'template': template},
    );
    final profile = await profiles.restore(identity.email);
    if (profile == null) {
      throw const ApiFailure('Profil demo belum bisa dimuat. Coba lagi.');
    }
    return profile;
  }

  static String message(Object error) => switch (error) {
    ApiFailure() => error.message,
    AuthException() => switch (error.code) {
      'otp_expired' =>
        'Kode salah atau kedaluwarsa. Periksa kode atau kirim ulang.',
      'over_email_send_rate_limit' || 'over_request_rate_limit' =>
        'Terlalu banyak permintaan. Tunggu sebelum mengirim kode lagi.',
      'email_exists' || 'user_already_exists' => 'Email sudah digunakan akun lain. Masuk menggunakan email tersebut; catatan demo tidak digabung otomatis.',
      _ => 'Login belum berhasil. Periksa kode, koneksi, atau coba lagi.',
    },
    _ => 'Permintaan belum berhasil. Input kamu tetap tersedia.',
  };
}
