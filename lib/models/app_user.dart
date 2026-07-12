/// Supabase'deki `profiles` satırını temsil eder.
class AppUser {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final String username;
  final String preferredLanguage;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.username,
    required this.preferredLanguage,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: (map['id'] ?? '') as String,
      name: (map['name'] ?? '') as String,
      email: (map['email'] ?? '') as String,
      photoUrl: map['photo_url'] as String?,
      username: (map['username'] ?? '') as String,
      preferredLanguage: (map['preferred_language'] ?? 'en') as String,
    );
  }
}
