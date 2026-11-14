import 'package:supabase_flutter/supabase_flutter.dart';

import 'api_client.dart';

abstract interface class SessionIdentity {
  bool get hasSession;
  bool get isAnonymous;
  String get email;
  Future<void> signInAnonymously();
  Future<void> signOut();
}

class SupabaseSessionIdentity implements SessionIdentity {
  SupabaseSessionIdentity(this.client, this.setupError);
  final SupabaseClient? client;
  final String? setupError;
  SupabaseClient get _client =>
      client ??
      (throw ApiFailure(setupError ?? 'Konfigurasi Supabase belum tersedia.'));
  @override
  bool get hasSession => client?.auth.currentSession != null;
  @override
  bool get isAnonymous => client?.auth.currentUser?.isAnonymous ?? false;
  @override
  String get email => client?.auth.currentUser?.email ?? '';
  @override
  Future<void> signInAnonymously() async {
    await _client.auth.signInAnonymously();
  }

  @override
  Future<void> signOut() => _client.auth.signOut(scope: SignOutScope.local);
}
