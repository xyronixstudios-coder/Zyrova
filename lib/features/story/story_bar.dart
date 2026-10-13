import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/video_service.dart';
import '../profile/user_profile_screen.dart';
import 'story_viewer.dart';

class StoryBar extends StatefulWidget {
  final VoidCallback? onAddStory;

  const StoryBar({super.key, this.onAddStory});

  @override
  State<StoryBar> createState() => _StoryBarState();
}

class _StoryBarState extends State<StoryBar> {
  List<UserVideo> _stories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stories = await VideoService.getStories();
    if (mounted) {
      setState(() {
        _stories = stories;
        _loading = false;
      });
    }
  }

  /// Aynı kullanıcının story'lerini grupla
  List<_UserStories> _groupByUser() {
    final map = <String, List<UserVideo>>{};
    for (final s in _stories) {
      map.putIfAbsent(s.authorId, () => []).add(s);
    }
    return map.entries
        .map((e) => _UserStories(
              userId: e.key,
              username: e.value.first.author,
              avatar: e.value.first.authorAvatar,
              stories: e.value,
            ))
        .toList();
  }

  void _openStory(int index, List<_UserStories> groups) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoryViewer(
          groups: groups,
          initialGroupIndex: index,
        ),
      ),
    ).then((_) => _load());
  }

  void _openProfile(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(userId: userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return SizedBox(
        height: 110,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
                color: AppColors.primary, strokeWidth: 2),
          ),
        ),
      );
    }

    final groups = _groupByUser();

    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: groups.length + 1,
        itemBuilder: (context, i) {
          // İlk hücre: Kendi story'in
          if (i == 0) return _myStoryCell();

          final g = groups[i - 1];
          return _storyCell(g, i - 1, groups);
        },
      ),
    );
  }

  /// Kendi story hücresi
  Widget _myStoryCell() {
    final t = AppL.of(context);
    // Kendi story'im var mı?
    final me = VideoService.currentUserId;
    final myGroups = _stories.where((s) => s.authorId == me).toList();
    final hasMyStory = myGroups.isNotEmpty;

    return GestureDetector(
      onTap: hasMyStory
          ? () => _openStory(0, _groupByUser().where((g) => g.userId == me).toList())
          : widget.onAddStory,
      child: Container(
        width: 80,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.card,
                    border: Border.all(
                      color: hasMyStory
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: hasMyStory
                        ? ClipOval(
                            child: Image.network(
                              myGroups.first.thumbnailUrl.isNotEmpty
                                  ? myGroups.first.thumbnailUrl
                                  : myGroups.first.videoUrl,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                  Icons.person,
                                  color: AppColors.textSecondary),
                            ),
                          )
                        : Icon(Icons.add,
                            color: AppColors.primary, size: 28),
                  ),
                ),
                if (!hasMyStory)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.background, width: 2),
                      ),
                      child: Icon(Icons.add,
                          color: Colors.white, size: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              hasMyStory ? 'Story\'in' : t.upload,
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Takip ettiğim kişinin story hücresi
  Widget _storyCell(_UserStories g, int index, List<_UserStories> groups) {
    return GestureDetector(
      onTap: () => _openStory(index, groups),
      onLongPress: () => _openProfile(g.userId),
      child: Container(
        width: 80,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Column(
          children: [
            Container(
              width: 68,
              height: 68,
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.background,
                ),
                child: ClipOval(
                  child: g.avatar.isNotEmpty
                      ? Image.network(
                          g.avatar,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(
                              g.username.replaceAll('@', '')[0]
                                  .toUpperCase(),
                              style: TextStyle(
                                  color: AppColors.text,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            g.username.replaceAll('@', '')[0]
                                .toUpperCase(),
                            style: TextStyle(
                                color: AppColors.text,
                                fontSize: 20,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              g.username,
              style: TextStyle(color: AppColors.text, fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _UserStories {
  final String userId;
  final String username;
  final String avatar;
  final List<UserVideo> stories;

  _UserStories({
    required this.userId,
    required this.username,
    required this.avatar,
    required this.stories,
  });
}
