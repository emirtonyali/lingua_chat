import 'package:flutter/material.dart';

import '../models/message.dart';
import '../services/translation_service.dart';

/// Tek bir mesaj balonu. Karşıdan gelen mesajlarda çeviri ikonu gösterir;
/// ikona basınca çeviri orijinalin ALTINDA belirir.
class MessageBubble extends StatefulWidget {
  final Message message;
  final bool isMine;
  final String myLanguage;

  /// Ayarlardan "otomatik çeviri" açıksa, karşı mesajlar baştan çevrilir.
  final bool autoTranslate;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    required this.myLanguage,
    required this.autoTranslate,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  final _translationService = TranslationService();

  String? _translation;
  bool _loading = false;
  bool _showTranslation = false;
  String? _error;

  bool get _needsTranslation =>
      !widget.isMine && widget.message.originalLanguage != widget.myLanguage;

  @override
  void initState() {
    super.initState();
    if (widget.autoTranslate && _needsTranslation) {
      _toggleTranslation();
    }
  }

  Future<void> _toggleTranslation() async {
    // Zaten gösteriliyorsa gizle.
    if (_showTranslation) {
      setState(() => _showTranslation = false);
      return;
    }
    // Daha önce çevrildiyse tekrar göster (API'ye gitme).
    if (_translation != null) {
      setState(() => _showTranslation = true);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _translationService.translateMessage(
        message: widget.message,
        targetLang: widget.myLanguage,
      );
      setState(() {
        _translation = result;
        _showTranslation = true;
      });
    } on TranslationException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Çeviri yapılamadı.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMine = widget.isMine;
    final bubbleColor = isMine
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;
    final align = isMine ? Alignment.centerRight : Alignment.centerLeft;

    return Align(
      alignment: align,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Orijinal metin
            Text(widget.message.text, style: theme.textTheme.bodyLarge),

            // Çeviri alanı (orijinalin ALTINDA)
            if (_showTranslation && _translation != null) ...[
              const SizedBox(height: 6),
              Divider(height: 1, color: theme.dividerColor.withOpacity(0.5)),
              const SizedBox(height: 6),
              Text(
                _translation!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.hintColor,
                ),
              ),
            ],

            if (_error != null) ...[
              const SizedBox(height: 4),
              Text(_error!,
                  style: TextStyle(
                      color: theme.colorScheme.error, fontSize: 12)),
            ],

            // Çeviri ikonu (yalnızca çevrilebilir karşı mesajlarda)
            if (_needsTranslation)
              Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  onTap: _loading ? null : _toggleTranslation,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: _loading
                        ? const SizedBox(
                            height: 14,
                            width: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.translate,
                                  size: 16, color: theme.colorScheme.primary),
                              const SizedBox(width: 2),
                              Text(
                                _showTranslation ? 'gizle' : 'çevir',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.primary),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
