import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';
import 'screens/auth_gate.dart';
import 'screens/setup_needed_screen.dart';
import 'services/app_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettings.init();

  // Supabase henüz ayarlanmadıysa, kullanıcıya ne yapması gerektiğini gösteren
  // bir ekran açıp çıkıyoruz (uygulama çökmez).
  if (!Config.isSupabaseConfigured) {
    runApp(const _AppShell(home: SetupNeededScreen()));
    return;
  }

  await Supabase.initialize(
    url: Config.supabaseUrl,
    anonKey: Config.supabaseAnonKey,
  );

  runApp(const _AppShell(home: AuthGate()));
}

/// Kısa yol: Supabase istemcisine her yerden erişim.
final supabase = Supabase.instance.client;

class _AppShell extends StatelessWidget {
  final Widget home;
  const _AppShell({required this.home});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LinguaChat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF2E7D6B),
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF2E7D6B),
        brightness: Brightness.dark,
      ),
      home: home,
    );
  }
}
