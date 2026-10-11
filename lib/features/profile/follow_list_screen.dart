import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/follow_service.dart';
import '../../core/services/profile_service.dart';
import 'user_profile_screen.dart';

class FollowListScreen extends StatefulWidget {
  final String userId;
  final bool showFollowers; // true=takipçiler, false=takip

  const FollowListScreen({
    super.key,
    required this.userId,
    required this.showFollowers,
  });

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userIds = widget.showFollowers
        ? await FollowService.getFollowersIds(widget.userId)
        : await FollowService.getFollowingIdsOf(widget.userId);

    final List<Map<String, dynamic>> users = [];
    for (final id in userIds) {
      final p = await ProfileService.getProfileById(id);
      if (p != null) users.add(p);
    }

    if (!mounted) return;
    setState(() {
      _users = users;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        elevation: 0,
        title: Text(
          widget.showFollowers ? 'Takipçiler' : 'Takip Edilenler',
          style: TextStyle(color: AppColors.text),
        ),
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _users.isEmpty
              ? Center(
                  child: Text(
                    widget.showFollowers
                        ? 'Henüz takipçi yok'
                        : 'Henüz takip yok',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (context, i) {
                    final u = _users[i];
                    final username = u['username'] ?? 'kullanici';
                    final avatar = u['avatar_url'];
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                UserProfileScreen(userId: u['id']),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.primary,
                                backgroundImage:
                                    avatar != null && avatar.isNotEmpty
                                        ? NetworkImage(avatar)
                                        : null,
                                child: avatar == null || avatar.isEmpty
                                    ? Text(username[0].toUpperCase(),
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700))
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Text('@$username',
                                  style: TextStyle(
                                      color: AppColors.text,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
