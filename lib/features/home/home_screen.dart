import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/video_service.dart';
import '../../core/services/like_service.dart';
import '../../core/navigation/route_observer.dart';
import '../comments/comments_sheet.dart';
import '../share/share_sheet.dart';
import '../profile/user_profile_screen.dart';
import '../story/story_bar.dart';
import '../notifications/notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onAddStory;

  const HomeScreen({super.key, this.onAddStory});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  final _pageController = PageController();
  int _currentIndex = 0;
  List<UserVideo> _videos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    setState(() => _loading = true);
    List<UserVideo> videos;
    switch (_tab) {
      case 1:
        videos = await VideoService.getFollowingVideos();
        break;
      case 2:
        videos = await VideoService.getPopularVideos();
        break;
      default:
        videos = await VideoService.getDiscoverVideos();
    }
    if (!mounted) return;
    setState(() {
      _videos = videos;
      _currentIndex = 0;
      _loading = false;
    });
  }

  void _switchTab(int i) {
    if (_tab == i) return;
    setState(() => _tab = i);
    _loadVideos();
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => const NotificationsListScreen()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL.of(context);
    return SafeArea(
      child: Column(
        children: [
          // 🔥 ÜST BAŞLIK: Logo + Bildirim İkonu
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/images/zyrova-logo.png',
                        width: 32,
                        height: 32,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.flash_on,
                          color: AppColors.primary,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Zyrova',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                // 🔔 Bildirim ikonu
                GestureDetector(
                  onTap: _openNotifications,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications_outlined,
                      color: AppColors.text,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // StoryBar
          StoryBar(
            onAddStory: widget.onAddStory,
          ),

          // Tab butonları
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _tabBtn(t.discover, 0),
                const SizedBox(width: 24),
                _tabBtn(t.following, 1),
                const SizedBox(width: 24),
                _tabBtn(t.popular, 2),
              ],
            ),
          ),

          Expanded(
            child: _loading
                ? Center(
                    child:
                        CircularProgressIndicator(color: AppColors.primary))
                : _videos.isEmpty
                    ? _empty(t)
                    : PageView.builder(
                        controller: _pageController,
                        scrollDirection: Axis.vertical,
                        physics: const AlwaysScrollableScrollPhysics(),
                        pageSnapping: true,
                        allowImplicitScrolling: false,
                        itemCount: _videos.length,
                        onPageChanged: (i) {
                          setState(() => _currentIndex = i);
                        },
                        itemBuilder: (context, i) {
                          final isActive = i == _currentIndex;
                          return _VideoPlayer(
                            key: ValueKey('video_${_videos[i].id}'),
                            video: _videos[i],
                            isActive: isActive,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _tabBtn(String label, int index) {
    final active = _tab == index;
    return GestureDetector(
      onTap: () => _switchTab(index),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: active ? AppColors.text : AppColors.textSecondary,
              fontSize: 16,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            width: active ? 24 : 0,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _empty(AppStrings t) {
    String msg = t.noVideos;
    if (_tab == 1) msg = t.followFirst;
    return RefreshIndicator(
      onRefresh: _loadVideos,
      color: AppColors.primary,
      backgroundColor: AppColors.card,
      child: ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.video_library_outlined,
                      size: 80,
                      color: AppColors.textSecondary.withOpacity(0.5)),
                  const SizedBox(height: 24),
                  Text(msg,
                      style: TextStyle(
                          color: AppColors.text,
                          fontSize: 20,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(t.uploadFirst,
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// VİDEO OYNATICI (aynı kalıyor)
class _VideoPlayer extends StatefulWidget {
  final UserVideo video;
  final bool isActive;

  const _VideoPlayer({
    super.key,
    required this.video,
    required this.isActive,
  });

  @override
  State<_VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<_VideoPlayer> with RouteAware {
  late final Player _player;
  late final VideoController _controller;
  bool _initialized = false;
  bool _liked = false;
  int _likes = 0;
  int _comments = 0;
  bool _subscribed = false;

  @override
  void initState() {
    super.initState();
    _liked = widget.video.isLiked;
    _likes = widget.video.likes;
    _comments = widget.video.comments;

    _player = Player(
      configuration: const PlayerConfiguration(vo: 'libmpv'),
    );
    _controller = VideoController(
      _player,
      configuration: const VideoControllerConfiguration(
        enableHardwareAcceleration: false,
        hwdec: 'no',
      ),
    );
    _player.setPlaylistMode(PlaylistMode.loop);
    _player.open(Media(widget.video.videoUrl));

    _player.stream.duration.listen((d) {
      if (d.inMilliseconds > 0 && !_initialized) {
        if (mounted) setState(() => _initialized = true);
      }
    });

    if (widget.isActive) _player.play();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_subscribed) {
      final route = ModalRoute.of(context);
      if (route is PageRoute) {
        routeObserver.subscribe(this, route);
        _subscribed = true;
      }
    }
  }

  @override
  void didPushNext() => _player.pause();

  @override
  void didPopNext() {
    if (widget.isActive) _player.play();
  }

  @override
  void didUpdateWidget(covariant _VideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _player.play();
      } else {
        _player.pause();
      }
    }
  }

  @override
  void dispose() {
    if (_subscribed) routeObserver.unsubscribe(this);
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    final newLiked = !_liked;
    setState(() {
      _liked = newLiked;
      _likes = _likes + (newLiked ? 1 : -1);
    });
    if (newLiked) {
      await LikeService.likeVideo(widget.video.id);
    } else {
      await LikeService.unlikeVideo(widget.video.id);
    }
  }

  void _openComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => CommentsSheet(
        videoId: widget.video.id,
        onCountChanged: (count) {
          if (mounted) setState(() => _comments = count);
        },
      ),
    );
  }

  void _openShare() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => ShareSheet(
        videoUrl: widget.video.videoUrl,
        videoTitle: widget.video.title,
        thumbnailUrl: widget.video.thumbnailUrl,
        authorUsername: widget.video.author,
      ),
    );
  }

  void _openProfile() {
    if (widget.video.authorId.isEmpty) return;
    _player.pause();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(userId: widget.video.authorId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL.of(context);
    final w = _player.state.width?.toDouble() ?? 1080;
    final h = _player.state.height?.toDouble() ?? 1920;
    final aspectRatio = (w > 0 && h > 0) ? w / h : 9 / 16;

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          color: Colors.black,
          child: _initialized
              ? Center(
                  child: AspectRatio(
                    aspectRatio: aspectRatio,
                    child: Video(controller: _controller),
                  ),
                )
              : Center(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (widget.video.thumbnailUrl.isNotEmpty)
                        Image.network(
                          widget.video.thumbnailUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(color: Colors.black),
                        ),
                      Container(color: Colors.black.withOpacity(0.4)),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                                color: AppColors.primary),
                            const SizedBox(height: 16),
                            Text(t.loading,
                                style: const TextStyle(
                                    color: Colors.white70)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withOpacity(0.6),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 80,
          bottom: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _openProfile,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primary,
                      backgroundImage: widget.video.authorAvatar.isNotEmpty
                          ? NetworkImage(widget.video.authorAvatar)
                          : null,
                      child: widget.video.authorAvatar.isEmpty
                          ? Text(
                              widget.video.author
                                  .replaceAll('@', '')[0]
                                  .toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700),
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.video.author,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              if (widget.video.title.isNotEmpty)
                Text(
                  widget.video.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                widget.video.caption,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.video.musicName.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.music_note,
                        color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.video.musicName,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        Positioned(
          right: 12,
          bottom: 80,
          child: Column(
            children: [
              GestureDetector(
                onTap: _toggleLike,
                child: Column(
                  children: [
                    Icon(
                      _liked ? Icons.favorite : Icons.favorite_border,
                      color: _liked ? AppColors.error : Colors.white,
                      size: 34,
                    ),
                    const SizedBox(height: 4),
                    Text('$_likes',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _openComments,
                child: Column(
                  children: [
                    const Icon(Icons.comment,
                        color: Colors.white, size: 34),
                    const SizedBox(height: 4),
                    Text('$_comments',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _openShare,
                child: Column(
                  children: [
                    const Icon(Icons.share, color: Colors.white, size: 34),
                    const SizedBox(height: 4),
                    Text(t.share,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
