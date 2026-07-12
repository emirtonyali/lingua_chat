import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_user.dart';
import 'user_service.dart';

/// Arkadaşlık istekleri ve arkadaş listesi.
class FriendService {
  final SupabaseClient _client = Supabase.instance.client;
  final UserService _userService = UserService();

  /// Kullanıcı adına göre istek gönderir.
  Future<void> sendRequestByUsername(AppUser me, String username) async {
    final target = await _userService.findByUsername(username);
    if (target == null) {
      throw FriendException('Bu kullanıcı adı bulunamadı.');
    }
    if (target.uid == me.uid) {
      throw FriendException('Kendine istek gönderemezsin.');
    }

    // Zaten arkadaş mı?
    final sorted = [me.uid, target.uid]..sort();
    final friendship = await _client
        .from('friendships')
        .select('id')
        .eq('user_a', sorted[0])
        .eq('user_b', sorted[1])
        .maybeSingle();
    if (friendship != null) {
      throw FriendException('Zaten arkadaşsınız.');
    }

    // Bekleyen istek var mı? (her iki yön)
    final pending = await _client
        .from('friend_requests')
        .select('id')
        .eq('status', 'pending')
        .or('and(from_user.eq.${me.uid},to_user.eq.${target.uid}),'
            'and(from_user.eq.${target.uid},to_user.eq.${me.uid})');
    if ((pending as List).isNotEmpty) {
      throw FriendException('Zaten bekleyen bir istek var.');
    }

    await _client.from('friend_requests').insert({
      'from_user': me.uid,
      'to_user': target.uid,
      'status': 'pending',
    });
  }

  /// Bana gelen bekleyen istekleri (gönderenin bilgisiyle) dinler.
  Stream<List<FriendRequest>> watchIncomingRequests(String myUid) {
    return _client
        .from('friend_requests')
        .stream(primaryKey: ['id'])
        .eq('to_user', myUid)
        .asyncMap((rows) async {
          final pending =
              rows.where((r) => r['status'] == 'pending').toList();
          final result = <FriendRequest>[];
          for (final r in pending) {
            final from = await _userService.getUser(r['from_user'] as String);
            result.add(FriendRequest(
              id: r['id'] as String,
              fromUserId: r['from_user'] as String,
              fromUsername: from?.username ?? '',
              toUserId: r['to_user'] as String,
              status: r['status'] as String,
            ));
          }
          return result;
        });
  }

  /// İsteği kabul eder: friendship oluşturur, isteği "accepted" yapar.
  Future<void> acceptRequest(FriendRequest req) async {
    final sorted = [req.fromUserId, req.toUserId]..sort();
    await _client.from('friendships').insert({
      'user_a': sorted[0],
      'user_b': sorted[1],
    });
    await _client
        .from('friend_requests')
        .update({'status': 'accepted'}).eq('id', req.id);
  }

  Future<void> rejectRequest(FriendRequest req) async {
    await _client
        .from('friend_requests')
        .update({'status': 'rejected'}).eq('id', req.id);
  }

  /// Arkadaş listesini dinler.
  Stream<List<AppUser>> watchFriends(String myUid) {
    return _client
        .from('friendships')
        .stream(primaryKey: ['id'])
        .asyncMap((rows) async {
          final friends = <AppUser>[];
          for (final r in rows) {
            final a = r['user_a'] as String;
            final b = r['user_b'] as String;
            final otherId = a == myUid ? b : a;
            final user = await _userService.getUser(otherId);
            if (user != null) friends.add(user);
          }
          return friends;
        });
  }
}

class FriendRequest {
  final String id;
  final String fromUserId;
  final String fromUsername;
  final String toUserId;
  final String status;

  FriendRequest({
    required this.id,
    required this.fromUserId,
    required this.fromUsername,
    required this.toUserId,
    required this.status,
  });
}

class FriendException implements Exception {
  final String message;
  FriendException(this.message);
  @override
  String toString() => message;
}
