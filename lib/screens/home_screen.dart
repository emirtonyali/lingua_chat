import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/chat.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import 'chat_screen.dart';
import 'friends_screen.dart';
import 'settings_screen.dart';

/// Giriş sonrası ana kabuk: alt menüyle 3 sekme.
class HomeScreen extends StatefulWidget {
  final AppUser me;
  const HomeScreen({super.key, required this.me});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _ChatListTab(me: widget.me),
      FriendsScreen(me: widget.me),
      SettingsScreen(me: widget.me),
    ];

    return Scaffold(
      body: tabs[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble),
              label: 'Sohbetler'),
          NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Arkadaşlar'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Ayarlar'),
        ],
      ),
    );
  }
}

/// Sohbet listesi sekmesi.
class _ChatListTab extends StatelessWidget {
  final AppUser me;
  const _ChatListTab({required this.me});

  @override
  Widget build(BuildContext context) {
    final chatService = ChatService();
    final userService = UserService();

    return Scaffold(
      appBar: AppBar(title: const Text('Sohbetler')),
      body: StreamBuilder<List<Chat>>(
        stream: chatService.watchChats(me.uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final chats = snapshot.data!;
          if (chats.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('💬', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),
                    Text(
                      'Henüz sohbet yok.\nArkadaşlar sekmesinden birini ekleyip '
                      'konuşmaya başla.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Theme.of(context).hintColor),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            itemCount: chats.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final chat = chats[i];
              final otherId = chat.otherMember(me.uid);
              return FutureBuilder<AppUser?>(
                future: userService.getUser(otherId),
                builder: (context, userSnap) {
                  final other = userSnap.data;
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        (other?.name.isNotEmpty ?? false)
                            ? other!.name[0].toUpperCase()
                            : '?',
                      ),
                    ),
                    title: Text(other?.name ?? '...'),
                    subtitle: Text(
                      chat.lastMessageText.isEmpty
                          ? 'Sohbeti başlat'
                          : chat.lastMessageText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: other == null
                        ? null
                        : () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    ChatScreen(me: me, other: other),
                              ),
                            ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
