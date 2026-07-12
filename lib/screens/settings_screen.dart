import 'package:flutter/material.dart';

import '../languages.dart';
import '../models/app_user.dart';
import '../services/app_settings.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'auth_gate.dart';

/// Ayarlar: dil değiştirme, otomatik çeviri, çıkış.
class SettingsScreen extends StatefulWidget {
  final AppUser me;
  const SettingsScreen({super.key, required this.me});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _userService = UserService();
  final _auth = AuthService();
  late String _lang = widget.me.preferredLanguage;

  Future<void> _changeLanguage(String code) async {
    setState(() => _lang = code);
    await _userService.updatePreferredLanguage(widget.me.uid, code);
    if (!mounted) return;
    // Dil her yerde geçerli olsun diye AuthGate'i yeniden yükle.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (_) => false,
    );
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        children: [
          // Profil özeti
          ListTile(
            leading: CircleAvatar(
              child: Text(widget.me.name.isNotEmpty
                  ? widget.me.name[0].toUpperCase()
                  : '?'),
            ),
            title: Text(widget.me.name),
            subtitle: Text('@${widget.me.username}'),
          ),
          const Divider(),

          // Otomatik çeviri
          ValueListenableBuilder<bool>(
            valueListenable: AppSettings.autoTranslate,
            builder: (context, value, _) {
              return SwitchListTile(
                title: const Text('Mesajları otomatik çevir'),
                subtitle: const Text(
                    'Açıksa gelen mesajlar ikona basmadan çevrilir.'),
                value: value,
                onChanged: (v) => AppSettings.setAutoTranslate(v),
              );
            },
          ),
          const Divider(),

          // Dil seçimi
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text('Okuma dilin',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ...kLanguages.map((lang) {
            return RadioListTile<String>(
              value: lang.code,
              groupValue: _lang,
              onChanged: (v) => _changeLanguage(v!),
              title: Text('${lang.flag}  ${lang.name}'),
            );
          }),
          const Divider(),

          // Çıkış
          ListTile(
            leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
            title: Text('Çıkış yap',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
            onTap: _signOut,
          ),
        ],
      ),
    );
  }
}
