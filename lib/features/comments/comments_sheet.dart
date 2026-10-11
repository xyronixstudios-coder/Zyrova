import '../profile/user_profile_screen.dart';
import '../../core/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/comment_service.dart';
import '../../core/services/auth_service.dart';

class CommentsSheet extends StatefulWidget {
  final String videoId;
  final Function(int) onCountChanged;

  const CommentsSheet({
    super.key,
    required this.videoId,
    required this.onCountChanged,
  });

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<Comment> _comments = [];
  bool _loading = true;
  bool _sending = false;
  String? _myUserId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = await AuthService.getProfile();
    final comments = await CommentService.getComments(widget.videoId);
    if (!mounted) return;
    setState(() {
      _comments = comments;
      _loading = false;
    });
    // userId'yi profile'dan al
    final currentUser = AuthService.currentUser;
    _myUserId = currentUser?.id;
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);

    final comment = await CommentService.addComment(
      videoId: widget.videoId,
      content: text,
    );

    if (comment != null) {
      _ctrl.clear();
      setState(() {
        _comments.insert(0, comment);
      });
      widget.onCountChanged(_comments.length);
      // Scroll to top
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut);
      }
    }

    if (mounted) setState(() => _sending = false);
  }

  Future<void> _delete(Comment comment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('Yorumu Sil',
            style: TextStyle(color: AppColors.text)),
        content: Text('Bu yorumu silmek istediğine emin misin?',
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

    if (confirm != true) return;

    await CommentService.deleteComment(comment.id);
    setState(() {
      _comments.removeWhere((c) => c.id == comment.id);
    });
    widget.onCountChanged(_comments.length);
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}dk';
    if (diff.inHours < 24) return '${diff.inHours}sa';
    if (diff.inDays < 7) return '${diff.inDays}g';
    return '${(diff.inDays / 7).floor()}h';
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Başlık
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.comment, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      '${_comments.length} Yorum',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: AppColors.card, height: 1),
              // Liste
              Expanded(
                child: _loading
                    ? Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary))
                    : _comments.isEmpty
                        ? _empty()
                        : ListView.builder(
                            controller: _scrollCtrl,
                            padding: const EdgeInsets.all(16),
                            itemCount: _comments.length,
                            itemBuilder: (context, i) =>
                                _commentItem(_comments[i]),
                          ),
              ),
              // Input
              Container(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  border: Border(
                      top: BorderSide(color: AppColors.surface, width: 1)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        style: TextStyle(color: AppColors.text),
                        maxLines: null,
                        decoration: InputDecoration(
                          hintText: 'Yorum yaz...',
                          hintStyle: TextStyle(
                              color: AppColors.textSecondary),
                          filled: true,
                          fillColor: AppColors.surface,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    IconButton(
                      onPressed: _sending ? null : _send,
                      icon: _sending
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: AppColors.primary, strokeWidth: 2),
                            )
                          : Icon(Icons.send,
                              color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline,
              color: AppColors.textSecondary, size: 64),
          SizedBox(height: 16),
          Text('Henüz yorum yok',
              style: TextStyle(
                  color: AppColors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          SizedBox(height: 8),
          Text('İlk yorumu sen yap!',
              style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _commentItem(Comment comment) {
    final isMine = comment.userId == _myUserId;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary,
            backgroundImage: comment.authorAvatar.isNotEmpty
                ? NetworkImage(comment.authorAvatar)
                : null,
            child: comment.authorAvatar.isEmpty
                ? Text(
                    comment.author.replaceAll('@', '')[0].toUpperCase(),
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14),
                  )
                : null,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.author,
                      style: TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      _timeAgo(comment.createdAt),
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    if (isMine) ...[
                      Spacer(),
                      GestureDetector(
                        onTap: () => _delete(comment),
                        child: Icon(Icons.delete_outline,
                            color: AppColors.error, size: 18),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  comment.content,
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
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
