import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_user.dart';

/// `profiles` tablosunu yönetir.
class UserService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<AppUser?> getUser(String uid) async {
    final data =
        await _client.from('profiles').select().eq('id', uid).maybeSingle();
    if (data == null) return null;
    return AppUser.fromMap(data);
  }

  /// Profil satırını canlı dinler (ör. dil değişince güncellensin).
  Stream<AppUser?> watchUser(String uid) {
    return _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', uid)
        .map((rows) => rows.isEmpty ? null : AppUser.fromMap(rows.first));
  }

  Future<bool> isUsernameTaken(String username) async {
    final data = await _client
        .from('profiles')
        .select('id')
        .eq('username', username.toLowerCase())
        .maybeSingle();
    return data != null;
  }

  /// İlk giriş: profil satırını oluşturur (kullanıcı adı benzersiz olmalı).
  Future<void> createProfile({
    required String uid,
    required String name,
    required String email,
    required String? photoUrl,
    required String username,
    required String preferredLanguage,
  }) async {
    await _client.from('profiles').upsert({
      'id': uid,
      'name': name,
      'email': email,
      'photo_url': photoUrl,
      'username': username.toLowerCase(),
      'preferred_language': preferredLanguage,
    });
  }

  Future<void> updatePreferredLanguage(String uid, String languageCode) async {
    await _client
        .from('profiles')
        .update({'preferred_language': languageCode}).eq('id', uid);
  }

  /// Kullanıcı adıyla tam eşleşme arar.
  Future<AppUser?> findByUsername(String username) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('username', username.toLowerCase())
        .maybeSingle();
    if (data == null) return null;
    return AppUser.fromMap(data);
  }
}
