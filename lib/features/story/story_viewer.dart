import 'dart:async';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/video_service.dart';

class StoryViewer extends StatefulWidget {
  final List<dynamic> groups;
  final int initialGroupIndex;

  const StoryViewer({
    super.key,
    required this.groups,
    this.initialGroupIndex = 0,
  });

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer> {
  late int _groupIndex;
  int _storyIndex = 0;
  Timer? _timer;
  double _progress = 0.0;
  final _progressController = ValueNotifier<double>(0.0);

  @override
  void initState() {
    super.initState();
    _groupIndex = widget.initialGroupIndex;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  List<UserVideo> get _currentStories =>
      (widget.groups[_groupIndex] as dynamic).stories;

  UserVideo get _currentStory => _currentStories[_storyIndex];

  void _startTimer() {
    _timer?.cancel();
    _progress = 0.0;
    _progressController.value = 0.0;

    const interval = Duration(milliseconds: 50);
    _timer = Timer.periodic(interval, (timer) {
      _progress += 0.01;
      _progressController.value = _progress;
      if (_progress >= 1.0) {
        timer.cancel();
        _next();
      }
    });
  }

  void _next() {
    if (_storyIndex < _currentStories.length - 1) {
      setState(() => _storyIndex++);
      _startTimer();
    } else if (_groupIndex < widget.groups.length - 1) {
      setState(() {
        _groupIndex++;
        _storyIndex = 0;
      });
      _startTimer();
    } else {
      Navigator.pop(context);
    }
  }

  void _previous() {
    if (_storyIndex > 0) {
      setState(() => _storyIndex--);
      _startTimer();
    } else if (_groupIndex > 0) {
      setState(() {
        _groupIndex--;
        _storyIndex = 0;
      });
      _startTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final story = _currentStory;
    final group = widget.groups[_groupIndex] as dynamic;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: (details) {
          final width = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < width / 3) {
            _previous();
          } else {
            _next();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (story.isImage)
              Image.network(
                story.videoUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.black,
                  child: const Center(
                    child: Icon(Icons.broken_image,
                        color: Colors.white54, size: 64),
                  ),
                ),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: Colors.black,
                    child: const Center(
                      child: CircularProgressIndicator(
                          color: Colors.white),
                    ),
                  );
                },
              )
            else
              _VideoStory(
                key: ValueKey('${story.id}_$_storyIndex'),
                url: story.videoUrl,
                thumbnailUrl: story.thumbnailUrl,
              ),

            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 8),
                    child: Row(
                      children: List.generate(
                        _currentStories.length,
                        (i) => Expanded(
                          child: Container(
                            height: 3,
                            margin:
                                const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: ValueListenableBuilder<double>(
                              valueListenable: _progressController,
                              builder: (context, value, _) {
                                double fill = 0;
                                if (i < _storyIndex) fill = 1.0;
                                if (i == _storyIndex) fill = value;
                                return FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: fill,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius:
                                          BorderRadius.circular(2),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.primary,
                          backgroundImage: group.avatar.isNotEmpty
                              ? NetworkImage(group.avatar)
                              : null,
                          child: group.avatar.isEmpty
                              ? Text(
                                  group.username.replaceAll('@', '')[0]
                                      .toUpperCase(),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700),
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                group.username,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${DateTime.now().difference(story.createdAt).inHours}s önce',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close,
                              color: Colors.white, size: 26),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (story.title.isNotEmpty)
                        Text(
                          story.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      if (story.caption.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          story.caption,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (story.musicName.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.music_note,
                                  color: Colors.white, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                story.musicName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoStory extends StatefulWidget {
  final String url;
  final String thumbnailUrl;

  const _VideoStory({
    super.key,
    required this.url,
    required this.thumbnailUrl,
  });

  @override
  State<_VideoStory> createState() => _VideoStoryState();
}

class _VideoStoryState extends State<_VideoStory> {
  late final Player _player;
  late final VideoController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
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
    _player.open(Media(widget.url));
    _player.play();

    _player.stream.duration.listen((d) {
      if (d.inMilliseconds > 0 && !_initialized) {
        if (mounted) setState(() => _initialized = true);
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (!_initialized && widget.thumbnailUrl.isNotEmpty)
          Image.network(
            widget.thumbnailUrl,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Container(color: Colors.black),
          ),

        if (_initialized)
          Center(
            child: AspectRatio(
              aspectRatio: 9 / 16,
              child: Video(controller: _controller),
            ),
          ),

        if (!_initialized)
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 16),
                Text(
                  'Yükleniyor...',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
