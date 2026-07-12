import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cihazda saklanan basit ayarlar (şimdilik: otomatik çeviri).
class AppSettings {
  static const _kAutoTranslate = 'auto_translate';
  static SharedPreferences? _prefs;

  /// Değiştiğinde dinleyen ekranlar (ör. açık sohbet) kendini yeniler.
  static final ValueNotifier<bool> autoTranslate = ValueNotifier<bool>(false);

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    autoTranslate.value = _prefs?.getBool(_kAutoTranslate) ?? false;
  }

  static Future<void> setAutoTranslate(bool value) async {
    autoTranslate.value = value;
    await _prefs?.setBool(_kAutoTranslate, value);
  }
}
