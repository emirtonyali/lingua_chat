# LinguaChat — Kurulum (tamamı ücretsiz, kart istemez)

Kod hazır. Aşağıdaki adımları bir kez yapman yeterli. Kod yazmayacaksın,
sadece hesap açıp iki-üç anahtarı `lib/config.dart` dosyasına yapıştıracaksın.

## 1) Supabase projesi aç
1. https://supabase.com → "Start your project" → GitHub/Google ile giriş.
2. "New project" → isim ver, bir veritabanı şifresi belirle (bir yere not et),
   bölge olarak sana yakınını seç → "Create new project".
3. Proje hazırlanınca (~1 dk) devam.

## 2) Veritabanını kur (tek tık)
1. Sol menüde **SQL Editor** → **New query**.
2. Bu klasördeki `supabase_schema.sql` dosyasının TAMAMINI kopyala, yapıştır.
3. **Run** de. "Success" görmelisin.

## 3) Anahtarları al
1. Sol altta **Project Settings** (dişli) → **API**.
2. Şunları kopyala:
   - **Project URL** (ör. https://xxxx.supabase.co)
   - **anon public** anahtarı (uzun bir metin; "service_role" OLAN DEĞİL)

## 4) Gemini (çeviri) anahtarı al — ücretsiz
1. https://aistudio.google.com/app/apikey → Google ile giriş.
2. **Create API key** → kopyala.

## 5) config.dart'ı doldur
`lib/config.dart` dosyasını aç, üç yeri değiştir:
```dart
static const String supabaseUrl     = 'BURAYA Project URL';
static const String supabaseAnonKey = 'BURAYA anon public anahtarı';
static const String geminiApiKey    = 'BURAYA Gemini anahtarı';
```
Kaydet. (Bu dosya .gitignore'da, yani anahtarların git'e gitmez.)

## 6) Çalıştır
Terminalde:
```
cd lingua_chat
flutter run -d chrome
```
Uygulama tarayıcıda açılır. Kayıt ol → dil seç → kullanıcı adı belirle.
Test için ikinci bir hesabı gizli sekmede açıp iki kullanıcıyı arkadaş yap,
mesajlaş ve çeviri ikonuna bas.

## Notlar
- **E-posta/şifre** girişi ekstra ayar istemeden çalışır. **Google ile giriş**
  için Supabase'de Authentication → Providers → Google'ı ayrıca açmak gerekir;
  onu sonra birlikte yaparız.
- Supabase e-posta doğrulaması isteyebilir. Test kolaylığı için:
  Authentication → Providers → Email → "Confirm email" kapatılabilir.
