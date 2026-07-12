import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/chat_service.dart';
import '../services/friend_service.dart';
import 'chat_screen.dart';

/// Arkadaş ekleme, gelen istekler ve arkadaş listesi.
class FriendsScreen extends StatefulWidget {
  final AppUser me;
  const FriendsScreen({super.key, required this.me});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _friendService = FriendService();
  final _chatService = ChatService();
  final _searchCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendRequest() async {
    final username = _searchCtrl.text.trim();
    if (username.isEmpty) return;
    setState(() => _sending = true);
    try {
      await _friendService.sendRequestByUsername(widget.me, username);
      _searchCtrl.clear();
      _snack('İstek gönderildi ✅');
    } on FriendException catch (e) {
      _snack(e.message);
    } catch (e) {
      _snack('Hata: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _openChat(AppUser friend) async {
    await _chatService.ensureChat(widget.me.uid, friend.uid);
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(me: widget.me, other: friend),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Arkadaşlar')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- Arkadaş ekle ---
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    prefixText: '@',
                    hintText: 'kullanıcı adı',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _sendRequest(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _sending ? null : _sendRequest,
                child: _sending
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Ekle'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // --- Gelen istekler ---
          _SectionTitle('Gelen istekler'),
          StreamBuilder<List<FriendRequest>>(
            stream: _friendService.watchIncomingRequests(widget.me.uid),
            builder: (context, snap) {
              final requests = snap.data ?? [];
              if (requests.isEmpty) {
                return _emptyHint('Bekleyen istek yok.');
              }
              return Column(
                children: requests.map((req) {
                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text('@${req.fromUsername}'),
                      subtitle: const Text('arkadaş olmak istiyor'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () async {
                              await _friendService.acceptRequest(req);
                              _snack('Arkadaş eklendi 🎉');
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () =>
                                _friendService.rejectRequest(req),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 24),

          // --- Arkadaş listesi ---
          _SectionTitle('Arkadaşların'),
          StreamBuilder<List<AppUser>>(
            stream: _friendService.watchFriends(widget.me.uid),
            builder: (context, snap) {
              final friends = snap.data ?? [];
              if (friends.isEmpty) {
                return _emptyHint('Henüz arkadaşın yok.');
              }
              return Column(
                children: friends.map((f) {
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(f.name.isNotEmpty
                          ? f.name[0].toUpperCase()
                          : '?'),
                    ),
                    title: Text(f.name),
                    subtitle: Text('@${f.username}'),
                    trailing: const Icon(Icons.chat_bubble_outline),
                    onTap: () => _openChat(f),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _emptyHint(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(text, style: TextStyle(color: Theme.of(context).hintColor)),
      );
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      );
}
