import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/banner_widget.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/profile_service.dart';
import '../../core/services/video_service.dart';
import '../../core/services/follow_service.dart';
import '../auth/login_screen.dart';
import '../settings/settings_screen.dart';
import 'follow_list_screen.dart';
import 'edit_profile_screen.dart';
import 'video_grid.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  List<UserVideo> _videos = [];
  int _followers = 0;
  int _following = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = await AuthService.getProfile();
    final videos = await VideoService.getMyVideos();

    if (user != null) {
      final counts = await FollowService.getCounts(user['id']);
      if (mounted) {
        setState(() {
          _followers = counts['followers'] ?? 0;
          _following = counts['following'] ?? 0;
        });
      }
    }

    if (!mounted) return;
    setState(() {
      _profile = user;
      _videos = videos;
      _loading = false;
    });
  }

  Future<void> _openEdit() async {
    if (_profile == null) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => EditProfileScreen(currentProfile: _profile!)),
    );
    if (result == true) _loadData();
  }

  Future<void> _logout() async {
    final t = AppL.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(t.logout, style: TextStyle(color: AppColors.text)),
        content: Text(t.confirmLogout,
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancel,
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.logout,
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (ok == true) {
      await AuthService.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  Future<void> _deleteVideo(UserVideo video) async {
    final t = AppL.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(t.deleteVideoTitle,
            style: TextStyle(color: AppColors.text)),
        content: Text('"${video.title}" ${t.deleteVideoConfirm}',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancel,
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                Text(t.delete, style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (ok != true) return;
    await VideoService.deleteVideo(video.id, video.videoUrl);
    _loadData();
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

    final username = _profile?['username'] ?? 'kullanici';
    final email = _profile?['email'] ?? '';
    final bio = _profile?['bio'];
    final avatarUrl = _profile?['avatar_url'];
    final bannerColor = _profile?['banner_color'] ?? '#1E90FF';
    final bannerColor2 = _profile?['banner_color2'] ?? '#0066FF';
    final bannerType = _profile?['banner_type'] ?? 'gradient';
    final bannerPattern = _profile?['banner_pattern'] ?? 'none';

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        backgroundColor: AppColors.card,
        child: ListView(
          padding: EdgeInsets.zero,
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
                  right: 8,
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SettingsScreen()),
                      ),
                      icon: Icon(Icons.settings, color: Colors.white),
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
              child: Text('@$username',
                  style: TextStyle(
                      color: AppColors.text,
                      fontSize: 20,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(email,
                  style: TextStyle(color: AppColors.textSecondary)),
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
                        userId: _profile!['id'],
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
                        userId: _profile!['id'],
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
                child: OutlinedButton.icon(
                  onPressed: _openEdit,
                  icon: Icon(Icons.edit, color: AppColors.primary),
                  label: Text(t.editProfile,
                      style: TextStyle(color: AppColors.primary)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
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
            VideoGrid(
              videos: _videos,
              canDelete: true,
              onDelete: (video) => _deleteVideo(video),
            ),

            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  icon: Icon(Icons.logout, color: AppColors.error),
                  label: Text(t.logout,
                      style: TextStyle(color: AppColors.error)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
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
