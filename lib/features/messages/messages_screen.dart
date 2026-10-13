import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/chat_service.dart';
import 'chat_screen.dart';
import '../profile/user_profile_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List<ChatModel> _chats = [];
  List<FriendModel> _friends = [];
  bool _loading = true;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _load();
    try {
      _channel = ChatService.subscribeToMyChats(() {
        if (mounted) _load();
      });
    } catch (e) {
      print('Realtime chat subscribe error: $e');
    }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> _load() async {
    final chats = await ChatService.getMyChats();
    final friends = await ChatService.getMyFriends();
    final chatUserIds = chats.map((c) => c.otherUserId).toSet();
    final friendsWithoutChat =
        friends.where((f) => !chatUserIds.contains(f.userId)).toList();
    if (!mounted) return;
    setState(() {
      _chats = chats;
      _friends = friendsWithoutChat;
      _loading = false;
    });
  }

  Future<void> _openChat(FriendModel friend) async {
    final chatId = await ChatService.getOrCreateChat(friend.userId);
    if (chatId == null || !mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatId: chatId,
          otherUserId: friend.userId,
          otherUsername: friend.username,
          otherAvatar: friend.avatarUrl,
        ),
      ),
    );
    _load();
  }

  void _openProfile(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(userId: userId),
      ),
    );
  }

  String _timeAgo(DateTime d, AppStrings t) {
    final diff = DateTime.now().difference(d);
    if (diff.isNegative) return t.justNow;
    if (diff.inMinutes < 1) return t.justNow;
    if (diff.inMinutes < 60) return '${diff.inMinutes}${t.minutesAgo}';
    if (diff.inHours < 24) return '${diff.inHours}${t.hoursAgo}';
    if (diff.inDays < 7) return '${diff.inDays}${t.daysAgo}';
    return '${(diff.inDays / 7).floor()}${t.weeksAgo}';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL.of(context);
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(t.messages,
                    style: TextStyle(
                        color: AppColors.text,
                        fontSize: 24,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? Center(
                    child:
                        CircularProgressIndicator(color: AppColors.primary))
                : RefreshIndicator(
                    onRefresh: _load,
                    color: AppColors.primary,
                    backgroundColor: AppColors.card,
                    child: ListView(
                      children: [
                        if (_friends.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Text(t.friends,
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                          ),
                          SizedBox(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12),
                              itemCount: _friends.length,
                              itemBuilder: (context, i) {
                                final f = _friends[i];
                                return GestureDetector(
                                  onTap: () => _openChat(f),
                                  onLongPress: () =>
                                      _openProfile(f.userId),
                                  child: Container(
                                    width: 80,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    child: Column(
                                      children: [
                                        Stack(
                                          children: [
                                            CircleAvatar(
                                              radius: 30,
                                              backgroundColor:
                                                  AppColors.primary,
                                              backgroundImage:
                                                  f.avatarUrl.isNotEmpty
                                                      ? NetworkImage(
                                                          f.avatarUrl)
                                                      : null,
                                              child: f.avatarUrl.isEmpty
                                                  ? Text(
                                                      f.username[0]
                                                          .toUpperCase(),
                                                      style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 22,
                                                          fontWeight:
                                                              FontWeight
                                                                  .w700))
                                                  : null,
                                            ),
                                            Positioned(
                                              bottom: 0,
                                              right: 0,
                                              child: Container(
                                                width: 16,
                                                height: 16,
                                                decoration: BoxDecoration(
                                                  color:
                                                      AppColors.success,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                      color: AppColors
                                                          .background,
                                                      width: 2),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text('@${f.username}',
                                            style: TextStyle(
                                                color: AppColors.text,
                                                fontSize: 11),
                                            maxLines: 1,
                                            overflow:
                                                TextOverflow.ellipsis),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          Divider(color: AppColors.card),
                        ],
                        if (_chats.isEmpty && _friends.isEmpty)
                          _empty(t)
                        else
                          ..._chats.map((c) => _chatTile(c, t)),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _empty(AppStrings t) {
    return SizedBox(
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.message_outlined,
                size: 80, color: AppColors.textSecondary.withOpacity(0.5)),
            const SizedBox(height: 24),
            Text(t.noFriendsYet,
                style: TextStyle(
                    color: AppColors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(t.mutualFollowRequired,
                style: TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _chatTile(ChatModel c, AppStrings t) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                chatId: c.id,
                otherUserId: c.otherUserId,
                otherUsername: c.otherUsername,
                otherAvatar: c.otherAvatar,
              ),
            ),
          );
          _load();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _openProfile(c.otherUserId),
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.primary,
                  backgroundImage: c.otherAvatar.isNotEmpty
                      ? NetworkImage(c.otherAvatar)
                      : null,
                  child: c.otherAvatar.isEmpty
                      ? Text(c.otherUsername[0].toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 20))
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => _openProfile(c.otherUserId),
                      child: Text('@${c.otherUsername}',
                          style: TextStyle(
                              color: AppColors.text,
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                    ),
                    const SizedBox(height: 4),
                    Text(c.lastMessage.isEmpty ? '—' : c.lastMessage,
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_timeAgo(c.lastMessageAt, t),
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 11)),
                  if (c.unreadCount > 0) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('${c.unreadCount}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
