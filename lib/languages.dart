/// Desteklenen diller. `code` çeviri için kullanılır, `name` ekranda gösterilir.
class AppLanguage {
  final String code;
  final String name;
  final String flag;

  const AppLanguage(this.code, this.name, this.flag);
}

const List<AppLanguage> kLanguages = [
  AppLanguage('tr', 'Türkçe', '🇹🇷'),
  AppLanguage('en', 'English', '🇬🇧'),
  AppLanguage('de', 'Deutsch', '🇩🇪'),
  AppLanguage('fr', 'Français', '🇫🇷'),
  AppLanguage('es', 'Español', '🇪🇸'),
  AppLanguage('it', 'Italiano', '🇮🇹'),
  AppLanguage('ru', 'Русский', '🇷🇺'),
  AppLanguage('ar', 'العربية', '🇸🇦'),
  AppLanguage('pt', 'Português', '🇵🇹'),
  AppLanguage('nl', 'Nederlands', '🇳🇱'),
  AppLanguage('zh', '中文', '🇨🇳'),
  AppLanguage('ja', '日本語', '🇯🇵'),
  AppLanguage('ko', '한국어', '🇰🇷'),
  AppLanguage('hi', 'हिन्दी', '🇮🇳'),
];

AppLanguage languageByCode(String code) {
  return kLanguages.firstWhere(
    (l) => l.code == code,
    orElse: () => kLanguages.first,
  );
}
