import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../services/app_settings.dart';
import '../services/chat_service.dart';
import '../widgets/message_bubble.dart';

/// İki kişi arası sohbet ekranı: mesaj akışı + gönderme kutusu.
class ChatScreen extends StatefulWidget {
  final AppUser me;
  final AppUser other;

  const ChatScreen({super.key, required this.me, required this.other});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _chatService = ChatService();
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  late final String _chatId;
  bool _ready = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _chatId = Chat.chatIdFor(widget.me.uid, widget.other.uid);
    _init();
  }

  Future<void> _init() async {
    await _chatService.ensureChat(widget.me.uid, widget.other.uid);
    if (mounted) setState(() => _ready = true);
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _inputCtrl.clear();
    try {
      await _chatService.sendMessage(
        chatId: _chatId,
        senderId: widget.me.uid,
        text: text,
        originalLanguage: widget.me.preferredLanguage,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gönderilemedi: $e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              child: Text(widget.other.name.isNotEmpty
                  ? widget.other.name[0].toUpperCase()
                  : '?'),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.other.name, style: const TextStyle(fontSize: 16)),
                Text('@${widget.other.username}',
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
      body: !_ready
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: StreamBuilder<List<Message>>(
                    stream: _chatService.watchMessages(_chatId),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      final messages = snapshot.data!;
                      if (messages.isEmpty) {
                        return Center(
                          child: Text(
                            'İlk mesajı sen yaz 👋',
                            style:
                                TextStyle(color: Theme.of(context).hintColor),
                          ),
                        );
                      }
                      _scrollToBottom();
                      return ValueListenableBuilder<bool>(
                        valueListenable: AppSettings.autoTranslate,
                        builder: (context, autoTranslate, _) {
                          return ListView.builder(
                            controller: _scrollCtrl,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: messages.length,
                            itemBuilder: (context, i) {
                              final msg = messages[i];
                              return MessageBubble(
                                key: ValueKey(msg.id),
                                message: msg,
                                isMine: msg.senderId == widget.me.uid,
                                myLanguage: widget.me.preferredLanguage,
                                autoTranslate: autoTranslate,
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
                _buildInputBar(),
              ],
            ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputCtrl,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: 'Mesaj yaz...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton(
              onPressed: _send,
              mini: true,
              child: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
