/// Supabase'deki `messages` satırı.
class Message {
  final String id;
  final String senderId;
  final String text;
  final String originalLanguage;
  final DateTime? createdAt;

  /// Çeviri cache'i: { "en": "Hello", "de": "Hallo" }
  final Map<String, String> translations;

  Message({
    required this.id,
    required this.senderId,
    required this.text,
    required this.originalLanguage,
    required this.createdAt,
    required this.translations,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    final rawTranslations = (map['translations'] as Map?) ?? {};
    return Message(
      id: (map['id'] ?? '') as String,
      senderId: (map['sender_id'] ?? '') as String,
      text: (map['text'] ?? '') as String,
      originalLanguage: (map['original_language'] ?? 'en') as String,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      translations: rawTranslations
          .map((k, v) => MapEntry(k.toString(), v.toString())),
    );
  }
}
