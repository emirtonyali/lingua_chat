/// Supabase'deki `chats` satırı.
/// id, iki uid'nin alfabetik sırayla "_" ile birleşimidir.
class Chat {
  final String id;
  final List<String> members;
  final String lastMessageText;
  final DateTime? lastMessageAt;

  Chat({
    required this.id,
    required this.members,
    required this.lastMessageText,
    required this.lastMessageAt,
  });

  factory Chat.fromMap(Map<String, dynamic> map) {
    final a = (map['member_a'] ?? '') as String;
    final b = (map['member_b'] ?? '') as String;
    return Chat(
      id: (map['id'] ?? '') as String,
      members: [a, b],
      lastMessageText: (map['last_message_text'] ?? '') as String,
      lastMessageAt: map['last_message_at'] != null
          ? DateTime.tryParse(map['last_message_at'].toString())
          : null,
    );
  }

  /// İki uid'den tutarlı bir chatId üretir.
  static String chatIdFor(String a, String b) {
    final ids = [a, b]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  /// Bu sohbette karşıdaki kişinin uid'sini döndürür.
  String otherMember(String myUid) {
    return members.firstWhere((m) => m != myUid, orElse: () => myUid);
  }
}
