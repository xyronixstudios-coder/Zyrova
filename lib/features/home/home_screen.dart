import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/video_service.dart';
import '../../core/services/like_service.dart';
import '../comments/comments_sheet.dart';
import '../share/share_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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
      case 1: videos = await VideoService.getFollowingVideos(); break;
      case 2: videos = await VideoService.getPopularVideos(); break;
      default: videos = await VideoService.getDiscoverVideos();
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                ? Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _videos.isEmpty
                    ? _empty(t)
                    : RefreshIndicator(
                        onRefresh: _loadVideos,
                        color: AppColors.primary,
                        backgroundColor: AppColors.card,
                        child: PageView.builder(
                          controller: _pageController,
                          scrollDirection: Axis.vertical,
                          itemCount: _videos.length,
                          onPageChanged: (i) => setState(() => _currentIndex = i),
                          itemBuilder: (context, i) => _VideoPlayer(
                            video: _videos[i],
                            isActive: i == _currentIndex,
                          ),
                        ),
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
          Text(label, style: TextStyle(
            color: active ? AppColors.text : AppColors.textSecondary,
            fontSize: 16,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          )),
          const SizedBox(height: 4),
          Container(height: 2, width: active ? 24 : 0, color: AppColors.primary),
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
                  Icon(Icons.video_library_outlined, size: 80,
                      color: AppColors.textSecondary.withOpacity(0.5)),
                  const SizedBox(height: 24),
                  Text(msg, style: TextStyle(
                      color: AppColors.text, fontSize: 20,
                      fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(t.uploadFirst, style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoPlayer extends StatefulWidget {
  final UserVideo video;
  final bool isActive;

  const _VideoPlayer({required this.video, required this.isActive});

  @override
  State<_VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<_VideoPlayer> {
  late final Player _player;
  late final VideoController _controller;
  bool _initialized = false;
  bool _liked = false;
  int _likes = 0;
  int _comments = 0;

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
  void didUpdateWidget(covariant _VideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _player.play();
    } else if (!widget.isActive && oldWidget.isActive) {
      _player.pause();
    }
  }

  @override
  void dispose() {
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
      builder: (_) => ShareSheet(
        videoUrl: widget.video.videoUrl,
        videoTitle: widget.video.title,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 🔥 TAM EKRAN VIDEO
        if (_initialized)
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _player.state.width?.toDouble() ?? 1080,
                height: _player.state.height?.toDouble() ?? 1920,
                child: Video(controller: _controller),
              ),
            ),
          )
        else
          Container(
            color: AppColors.card,
            child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          ),
        // Alt gradyan
        IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.transparent, Colors.black.withOpacity(0.6)],
              ),
            ),
          ),
        ),
        // Alt bilgi
        Positioned(
          left: 16,
          right: 80,
          bottom: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary,
                    backgroundImage: widget.video.authorAvatar.isNotEmpty
                        ? NetworkImage(widget.video.authorAvatar)
                        : null,
                    child: widget.video.authorAvatar.isEmpty
                        ? Text(widget.video.author.replaceAll('@', '')[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Text(widget.video.author,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                ],
              ),
              const SizedBox(height: 8),
              if (widget.video.title.isNotEmpty)
                Text(widget.video.title,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(widget.video.caption,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        // Sağ aksiyonlar
        Positioned(
          right: 12,
          bottom: 80,
          child: Column(
            children: [
              GestureDetector(
                onTap: _toggleLike,
                child: Column(
                  children: [
                    Icon(_liked ? Icons.favorite : Icons.favorite_border,
                        color: _liked ? AppColors.error : Colors.white, size: 34),
                    const SizedBox(height: 4),
                    Text('$_likes', style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _openComments,
                child: Column(
                  children: [
                    const Icon(Icons.comment, color: Colors.white, size: 34),
                    const SizedBox(height: 4),
                    Text('$_comments', style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _openShare,
                child: const Column(
                  children: [
                    Icon(Icons.share, color: Colors.white, size: 34),
                    SizedBox(height: 4),
                    Text('Paylaş', style: TextStyle(color: Colors.white, fontSize: 12)),
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
