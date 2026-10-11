import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUsername;
  final String otherAvatar;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUsername,
    required this.otherAvatar,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final _focus = FocusNode();
  List<MessageModel> _messages = [];
  bool _loading = true;
  bool _sending = false;
  bool _showEmoji = false;
  String? _myId;

  @override
  void initState() {
    super.initState();
    _myId = Supabase.instance.client.auth.currentUser?.id;
    _load();
    ChatService.markAsRead(widget.chatId);

    // Klavye açıldığında emoji'yi kapat
    _focus.addListener(() {
      if (_focus.hasFocus && _showEmoji) {
        setState(() => _showEmoji = false);
      }
    });
  }

  Future<void> _load() async {
    final msgs = await ChatService.getMessages(widget.chatId);
    if (!mounted) return;
    setState(() {
      _messages = msgs;
      _loading = false;
    });
    _scrollDown();
  }

  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    setState(() => _sending = true);
    await ChatService.sendMessage(widget.chatId, text);
    await _load();
    if (mounted) setState(() => _sending = false);
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      imageQuality: 80,
    );
    if (picked == null) return;

    setState(() => _sending = true);
    await ChatService.sendImageMessage(widget.chatId, File(picked.path));
    await _load();
    if (mounted) setState(() => _sending = false);
  }

  void _toggleEmoji() {
    if (_showEmoji) {
      setState(() => _showEmoji = false);
      _focus.requestFocus();
    } else {
      _focus.unfocus();
      setState(() => _showEmoji = true);
    }
  }

  void _onEmojiSelected(Emoji emoji) {
    _ctrl.text += emoji.emoji;
    _ctrl.selection = TextSelection.fromPosition(
      TextPosition(offset: _ctrl.text.length),
    );
  }

  void _showMessageMenu(MessageModel m, bool isMe) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(Icons.copy, color: AppColors.text),
              title: Text('Kopyala',
                  style: TextStyle(color: AppColors.text)),
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: m.content));
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Kopyalandı'),
                      backgroundColor: AppColors.success,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              },
            ),
            if (isMe)
              ListTile(
                leading:
                    Icon(Icons.delete_outline, color: AppColors.error),
                title: Text('Sil',
                    style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(m);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteMessage(MessageModel m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('Mesajı Sil',
            style: TextStyle(color: AppColors.text)),
        content: Text('Bu mesajı silmek istediğine emin misin?',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('İptal',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                Text('Sil', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ChatService.deleteMessage(m.id);
    _load();
  }

  void _showImage(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            child: Image.network(url, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  String _time(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary,
              backgroundImage: widget.otherAvatar.isNotEmpty
                  ? NetworkImage(widget.otherAvatar)
                  : null,
              child: widget.otherAvatar.isEmpty
                  ? Text(widget.otherUsername[0].toUpperCase(),
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700))
                  : null,
            ),
            const SizedBox(width: 10),
            Text('@${widget.otherUsername}',
                style: TextStyle(color: AppColors.text)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? Center(
                    child:
                        CircularProgressIndicator(color: AppColors.primary))
                : _messages.isEmpty
                    ? Center(
                        child: Text('Mesaj yok',
                            style: TextStyle(
                                color: AppColors.textSecondary)))
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, i) {
                          final m = _messages[i];
                          final isMe = m.senderId == _myId;
                          return GestureDetector(
                            onLongPress: () =>
                                _showMessageMenu(m, isMe),
                            child: Align(
                              alignment: isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: m.imageUrl != null
                                    ? const EdgeInsets.all(4)
                                    : const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 10),
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context)
                                          .size
                                          .width *
                                      0.7,
                                ),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? AppColors.primary
                                      : AppColors.card,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft:
                                        Radius.circular(isMe ? 16 : 4),
                                    bottomRight:
                                        Radius.circular(isMe ? 4 : 16),
                                  ),
                                ),
                                child: m.imageUrl != null
                                    ? GestureDetector(
                                        onTap: () =>
                                            _showImage(m.imageUrl!),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: Image.network(
                                            m.imageUrl!,
                                            width: 200,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      )
                                    : Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(m.content,
                                              style: TextStyle(
                                                  color: isMe
                                                      ? Colors.white
                                                      : AppColors.text,
                                                  fontSize: 14)),
                                          const SizedBox(height: 2),
                                          Text(_time(m.createdAt),
                                              style: TextStyle(
                                                  color: isMe
                                                      ? Colors.white70
                                                      : AppColors
                                                          .textSecondary,
                                                  fontSize: 10)),
                                        ],
                                      ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          // INPUT + EMOJI
          Container(
            padding: EdgeInsets.only(
              left: 4,
              right: 4,
              top: 8,
              bottom: 8,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                  top: BorderSide(color: AppColors.card, width: 1)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: _sending ? null : _pickImage,
                      icon: Icon(Icons.image,
                          color: AppColors.primary),
                      tooltip: 'Fotoğraf',
                    ),
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        focusNode: _focus,
                        style: TextStyle(color: AppColors.text),
                        maxLines: null,
                        onTap: () {
                          if (_showEmoji) {
                            setState(() => _showEmoji = false);
                          }
                        },
                        decoration: InputDecoration(
                          hintText: 'Mesaj yaz...',
                          hintStyle: TextStyle(
                              color: AppColors.textSecondary),
                          filled: true,
                          fillColor: AppColors.card,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _toggleEmoji,
                      icon: Icon(
                        _showEmoji
                            ? Icons.keyboard
                            : Icons.emoji_emotions_outlined,
                        color: AppColors.primary,
                      ),
                      tooltip: 'Emoji',
                    ),
                    IconButton(
                      onPressed: _sending ? null : _send,
                      icon: Icon(Icons.send, color: AppColors.primary),
                      tooltip: 'Gönder',
                    ),
                  ],
                ),
                // EMOJI PICKER
                if (_showEmoji)
                  SizedBox(
                    height: 280,
                    child: EmojiPicker(
                      onEmojiSelected: (category, emoji) {
                        _onEmojiSelected(emoji);
                      },
                      config: Config(
                        height: 280,
                        checkPlatformCompatibility: true,
                        emojiViewConfig: EmojiViewConfig(
                          backgroundColor: AppColors.background,
                          emojiSizeMax: 28,
                          columns: 8,
                        ),
                        categoryViewConfig: CategoryViewConfig(
                          backgroundColor: AppColors.surface,
                          iconColor: AppColors.textSecondary,
                          iconColorSelected: AppColors.primary,
                          indicatorColor: AppColors.primary,
                        ),
                        bottomActionBarConfig: BottomActionBarConfig(
                          backgroundColor: AppColors.surface,
                          buttonColor: AppColors.primary,
                          buttonIconColor: Colors.white,
                        ),
                        searchViewConfig: SearchViewConfig(
                          backgroundColor: AppColors.background,
                          buttonIconColor: AppColors.text,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
