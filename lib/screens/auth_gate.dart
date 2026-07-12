import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_user.dart';
import '../services/user_service.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';
import 'sign_in_screen.dart';

/// Oturum durumuna göre doğru ekrana yönlendirir:
/// - Giriş yoksa       → SignInScreen
/// - Giriş var ama profil yoksa → OnboardingScreen (dil + kullanıcı adı)
/// - Giriş + profil var → HomeScreen
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session == null) {
          return const SignInScreen();
        }
        return _ProfileGate(uid: session.user.id);
      },
    );
  }
}

/// Profil var mı diye bakar; yoksa onboarding'e gönderir.
class _ProfileGate extends StatelessWidget {
  final String uid;
  const _ProfileGate({required this.uid});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser?>(
      future: UserService().getUser(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snapshot.data;
        if (user == null || user.username.isEmpty) {
          return const OnboardingScreen();
        }
        return HomeScreen(me: user);
      },
    );
  }
}
