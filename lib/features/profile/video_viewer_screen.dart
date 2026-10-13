import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/video_service.dart';
import '../../core/services/like_service.dart';
import '../comments/comments_sheet.dart';
import '../share/share_sheet.dart';
import 'user_profile_screen.dart';

class VideoViewerScreen extends StatefulWidget {
  final UserVideo video;

  const VideoViewerScreen({super.key, required this.video});

  @override
  State<VideoViewerScreen> createState() => _VideoViewerScreenState();
}

class _VideoViewerScreenState extends State<VideoViewerScreen> {
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

    if (!widget.video.isImage) {
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
      _player.play();

      _player.stream.duration.listen((d) {
        if (d.inMilliseconds > 0 && !_initialized) {
          if (mounted) setState(() => _initialized = true);
        }
      });
    } else {
      // Resim ise player başlatma
      _player = Player();
      _controller = VideoController(_player);
      _initialized = true;
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

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: widget.video.isImage
                ? Image.network(
                    widget.video.videoUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.black,
                      child: const Center(
                        child: Icon(Icons.broken_image,
                            color: Colors.white54, size: 64),
                      ),
                    ),
                  )
                : _initialized
                    ? AspectRatio(
                        aspectRatio: aspectRatio,
                        child: Video(controller: _controller),
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          if (widget.video.thumbnailUrl.isNotEmpty)
                            Image.network(
                              widget.video.thumbnailUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  Container(color: Colors.black),
                            ),
                          Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primary),
                          ),
                        ],
                      ),
          ),

          Positioned(
            left: 16,
            right: 80,
            bottom: 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: _openProfile,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primary,
                        backgroundImage:
                            widget.video.authorAvatar.isNotEmpty
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
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                if (widget.video.caption.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.video.caption,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 14),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (widget.video.musicName.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.music_note,
                          color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.video.musicName,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
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
            bottom: 100,
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
                      const Icon(Icons.share,
                          color: Colors.white, size: 34),
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
      ),
    );
  }
}
