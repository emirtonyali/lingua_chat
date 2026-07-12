import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase Auth işlemleri (Google + e-posta).
class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

  /// Oturum değişikliklerini dinler (giriş/çıkış).
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Google ile giriş. Web'de popup/redirect, mobilde tarayıcı akışı açılır.
  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      // Mobilde geri dönüş için derin bağlantı; web'de gerekmez.
      redirectTo: kIsWeb ? null : 'io.linguachat://login-callback',
    );
  }

  Future<AuthResponse> signInWithEmail(String email, String password) {
    return _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<AuthResponse> registerWithEmail(String email, String password) {
    return _client.auth.signUp(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() => _client.auth.signOut();
}
