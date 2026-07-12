import 'package:flutter/material.dart';

/// Config doldurulmadıysa gösterilir. Kullanıcıya sıradaki adımı anlatır.
class SetupNeededScreen extends StatelessWidget {
  const SetupNeededScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('🔧', style: TextStyle(fontSize: 48)),
                SizedBox(height: 16),
                Text(
                  'Son bir adım kaldı',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Text(
                  'lib/config.dart dosyasındaki Supabase URL ve anon anahtarını '
                  'doldur. Ardından uygulamayı yeniden başlat.\n\n'
                  '1) supabase.com → yeni proje\n'
                  '2) Project Settings → API → URL ve anon key\n'
                  '3) lib/config.dart içine yapıştır',
                  style: TextStyle(fontSize: 16, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
