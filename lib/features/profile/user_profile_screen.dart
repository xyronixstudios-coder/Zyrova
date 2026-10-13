import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/banner_widget.dart';
import '../../core/services/profile_service.dart';
import '../../core/services/video_service.dart';
import '../../core/services/follow_service.dart';
import 'follow_list_screen.dart';
import 'video_grid.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Map<String, dynamic>? _profile;
  List<UserVideo> _videos = [];
  int _followers = 0;
  int _following = 0;
  bool _isFollowing = false;
  bool _loading = true;
  bool _followLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final profile = await ProfileService.getProfileById(widget.userId);
    final videos = await VideoService.getUserVideos(widget.userId);
    final counts = await FollowService.getCounts(widget.userId);
    final following = await FollowService.isFollowing(widget.userId);

    if (!mounted) return;
    setState(() {
      _profile = profile;
      _videos = videos;
      _followers = counts['followers'] ?? 0;
      _following = counts['following'] ?? 0;
      _isFollowing = following;
      _loading = false;
    });
  }

  Future<void> _toggleFollow() async {
    if (_followLoading) return;
    setState(() => _followLoading = true);

    final newState = !_isFollowing;

    if (newState) {
      await FollowService.follow(widget.userId);
    } else {
      await FollowService.unfollow(widget.userId);
    }

    if (mounted) {
      setState(() {
        _isFollowing = newState;
        _followers = _followers + (newState ? 1 : -1);
        _followLoading = false;
      });
    }
  }

  Color _hex(String hex) =>
      Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));

  @override
  Widget build(BuildContext context) {
    final t = AppL.of(context);

    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_profile == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.text,
          elevation: 0,
        ),
        body: Center(
          child: Text(t.userNotFoundTitle,
              style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    final username = _profile!['username'] ?? 'kullanici';
    final isPrivate = _profile!['is_private'] == true;
    final bio = _profile!['bio'];
    final avatarUrl = _profile!['avatar_url'];
    final bannerColor = _profile!['banner_color'] ?? '#1E90FF';
    final bannerColor2 = _profile!['banner_color2'] ?? '#0066FF';
    final bannerType = _profile!['banner_type'] ?? 'gradient';
    final bannerPattern = _profile!['banner_pattern'] ?? 'none';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        backgroundColor: AppColors.card,
        child: ListView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 16,
          ),
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                SizedBox(
                  height: 160,
                  child: BannerWidget(
                    type: bannerType,
                    color1: bannerColor,
                    color2: bannerColor2,
                    pattern: bannerPattern,
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -50,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                        border: Border.all(
                            color: AppColors.background, width: 4),
                        image: avatarUrl != null && avatarUrl.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(avatarUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: avatarUrl == null || avatarUrl.isEmpty
                          ? Center(
                              child: Text(
                                username[0].toUpperCase(),
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 42,
                                    fontWeight: FontWeight.w900),
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 60),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isPrivate)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Icon(Icons.lock,
                          color: AppColors.warning, size: 18),
                    ),
                  Text('@$username',
                      style: TextStyle(
                          color: AppColors.text,
                          fontSize: 20,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            if (bio != null && bio.isNotEmpty) ...[
              const SizedBox(height: 8),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(bio,
                      style: TextStyle(color: AppColors.textSecondary),
                      textAlign: TextAlign.center),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _stat('${_videos.length}', t.posts),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FollowListScreen(
                        userId: widget.userId,
                        showFollowers: true,
                      ),
                    ),
                  ),
                  child: _stat('$_followers', t.followers),
                ),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FollowListScreen(
                        userId: widget.userId,
                        showFollowers: false,
                      ),
                    ),
                  ),
                  child: _stat('$_following', t.following),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _followLoading ? null : _toggleFollow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFollowing
                        ? AppColors.card
                        : AppColors.primary,
                    foregroundColor: _isFollowing
                        ? AppColors.text
                        : Colors.white,
                    side: _isFollowing
                        ? BorderSide(color: AppColors.textSecondary)
                        : null,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _followLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: _isFollowing
                                  ? AppColors.primary
                                  : Colors.white,
                              strokeWidth: 2),
                        )
                      : Text(
                          _isFollowing ? t.unfollow : t.follow,
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(t.posts,
                  style: TextStyle(
                      color: AppColors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 12),

            // 🔥 GRID GÖRÜNÜM
            VideoGrid(videos: _videos),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _stat(String v, String l) {
    return Column(
      children: [
        Text(v,
            style: TextStyle(
                color: AppColors.text,
                fontSize: 18,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(l,
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: 13)),
      ],
    );
  }
}
