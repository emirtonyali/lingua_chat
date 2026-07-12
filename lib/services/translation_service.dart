import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';
import '../languages.dart';
import '../models/message.dart';

/// Çeviriyi yönetir.
///
/// Akış:
/// 1. Hedef dil = orijinal dil ise çeviri gerekmez.
/// 2. Mesajda hedef dil için cache varsa onu döndür (API çağrısı yok).
/// 3. Yoksa Gemini'ye çeviri isteği at, sonucu Supabase'e cache'le ve döndür.
///
/// NOT (MVP): Gemini şu an doğrudan istemciden çağrılıyor. Yayın öncesi bu
/// çağrı ücretsiz bir Supabase Edge Function'a taşınabilir; dışarıya bakan
/// arayüz (translateMessage) aynı kalır.
class TranslationService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<String> translateMessage({
    required Message message,
    required String targetLang,
  }) async {
    if (message.originalLanguage == targetLang) {
      return message.text;
    }

    final cached = message.translations[targetLang];
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    if (!Config.isGeminiConfigured) {
      throw TranslationException(
        'Çeviri anahtarı ayarlanmamış. lib/config.dart dosyasına Gemini '
        'API anahtarını ekle.',
      );
    }

    final translated = await _callGemini(
      text: message.text,
      targetLang: targetLang,
    );

    // Cache'i güncelle (hata olsa da çeviriyi yine döndürürüz).
    try {
      final updated = Map<String, String>.from(message.translations)
        ..[targetLang] = translated;
      await _client
          .from('messages')
          .update({'translations': updated}).eq('id', message.id);
    } catch (_) {}

    return translated;
  }

  Future<String> _callGemini({
    required String text,
    required String targetLang,
  }) async {
    final targetName = languageByCode(targetLang).name;
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/'
      '${Config.geminiModel}:generateContent?key=${Config.geminiApiKey}',
    );

    final prompt = 'Translate the following chat message into $targetName. '
        'Preserve the tone, slang and emojis. '
        'Return ONLY the translation, with no quotes, no explanation, '
        'no extra text.\n\nMessage:\n$text';

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {'temperature': 0.3},
    });

    http.Response resp;
    try {
      resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
    } catch (e) {
      throw TranslationException('İnternet hatası: çeviri yapılamadı.');
    }

    if (resp.statusCode == 429) {
      throw TranslationException(
        'Çeviri limiti şimdilik doldu, biraz sonra tekrar dene.',
      );
    }
    if (resp.statusCode != 200) {
      throw TranslationException('Çeviri başarısız (kod ${resp.statusCode}).');
    }

    try {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final candidates = data['candidates'] as List<dynamic>;
      final content = candidates.first['content'] as Map<String, dynamic>;
      final parts = content['parts'] as List<dynamic>;
      final result = (parts.first['text'] as String).trim();
      if (result.isEmpty) {
        throw TranslationException('Çeviri boş döndü.');
      }
      return result;
    } catch (e) {
      if (e is TranslationException) rethrow;
      throw TranslationException('Çeviri yanıtı okunamadı.');
    }
  }
}

class TranslationException implements Exception {
  final String message;
  TranslationException(this.message);

  @override
  String toString() => message;
}
