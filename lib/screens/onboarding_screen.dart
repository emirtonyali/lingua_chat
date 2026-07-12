import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../languages.dart';
import '../services/user_service.dart';
import 'auth_gate.dart';

/// İlk giriş: dil seç + kullanıcı adı belirle → profil oluştur.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _userService = UserService();
  final _usernameCtrl = TextEditingController();

  String _selectedLang = 'tr';
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final username = _usernameCtrl.text.trim().toLowerCase();
    if (username.length < 3) {
      setState(() => _error = 'Kullanıcı adı en az 3 karakter olmalı.');
      return;
    }
    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(username)) {
      setState(() =>
          _error = 'Sadece küçük harf, rakam ve alt çizgi kullanabilirsin.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      if (await _userService.isUsernameTaken(username)) {
        setState(() {
          _error = 'Bu kullanıcı adı alınmış, başka dene.';
          _saving = false;
        });
        return;
      }

      final user = Supabase.instance.client.auth.currentUser!;
      await _userService.createProfile(
        uid: user.id,
        name: user.userMetadata?['name'] as String? ??
            user.email?.split('@').first ??
            'Kullanıcı',
        email: user.email ?? '',
        photoUrl: user.userMetadata?['avatar_url'] as String?,
        username: username,
        preferredLanguage: _selectedLang,
      );
      // Profil oluşunca AuthGate'i sıfırdan çalıştır → HomeScreen'e düşer.
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (_) => false,
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Kaydedilemedi: $e';
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profilini oluştur')),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Hangi dilde okumak istersin?',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gelen mesajları bu dile çevireceğiz. Sonradan '
                    'değiştirebilirsin.',
                    style: TextStyle(color: Theme.of(context).hintColor),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: kLanguages.map((lang) {
                      final selected = lang.code == _selectedLang;
                      return ChoiceChip(
                        label: Text('${lang.flag} ${lang.name}'),
                        selected: selected,
                        onSelected: (_) =>
                            setState(() => _selectedLang = lang.code),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Kullanıcı adın',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Arkadaşların seni bununla bulacak.',
                    style: TextStyle(color: Theme.of(context).hintColor),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _usernameCtrl,
                    decoration: const InputDecoration(
                      prefixText: '@',
                      hintText: 'ornek_kullanici',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Devam et'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

