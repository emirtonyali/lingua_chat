import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/chat.dart';
import '../models/message.dart';

/// `chats` ve `messages` tablolarını yönetir.
class ChatService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Giriş yapan kullanıcının sohbetlerini dinler.
  /// RLS sayesinde stream yalnızca kullanıcının üyesi olduğu sohbetleri döndürür.
  Stream<List<Chat>> watchChats(String myUid) {
    return _client
        .from('chats')
        .stream(primaryKey: ['id'])
        .map((rows) {
          final chats = rows.map((r) => Chat.fromMap(r)).toList();
          chats.sort((a, b) {
            final ad = a.lastMessageAt ?? DateTime(0);
            final bd = b.lastMessageAt ?? DateTime(0);
            return bd.compareTo(ad); // en yeni üstte
          });
          return chats;
        });
  }

  /// İki kişi arası sohbeti (yoksa) oluşturur ve chatId döndürür.
  Future<String> ensureChat(String myUid, String otherUid) async {
    final chatId = Chat.chatIdFor(myUid, otherUid);
    final existing =
        await _client.from('chats').select('id').eq('id', chatId).maybeSingle();
    if (existing == null) {
      final sorted = [myUid, otherUid]..sort();
      await _client.from('chats').insert({
        'id': chatId,
        'member_a': sorted[0],
        'member_b': sorted[1],
        'last_message_text': '',
        'last_message_at': DateTime.now().toIso8601String(),
      });
    }
    return chatId;
  }

  /// Bir sohbetteki mesajları eskiden yeniye dinler.
  Stream<List<Message>> watchMessages(String chatId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at', ascending: true)
        .map((rows) => rows.map((r) => Message.fromMap(r)).toList());
  }

  /// Mesaj gönderir ve sohbetin son mesaj özetini günceller.
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
    required String originalLanguage,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    await _client.from('messages').insert({
      'chat_id': chatId,
      'sender_id': senderId,
      'text': trimmed,
      'original_language': originalLanguage,
      'translations': <String, dynamic>{},
    });

    await _client.from('chats').update({
      'last_message_text': trimmed,
      'last_message_at': DateTime.now().toIso8601String(),
    }).eq('id', chatId);
  }
}
