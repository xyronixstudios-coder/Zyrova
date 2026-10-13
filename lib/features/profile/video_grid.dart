import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/video_service.dart';
import 'video_viewer_screen.dart';

class VideoGrid extends StatelessWidget {
  final List<UserVideo> videos;
  final bool canDelete;
  final Function(UserVideo)? onDelete;

  const VideoGrid({
    super.key,
    required this.videos,
    this.canDelete = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppL.of(context);

    if (videos.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(Icons.video_library_outlined,
                color: AppColors.textSecondary, size: 48),
            const SizedBox(height: 12),
            Text(t.noVideos,
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 14)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 9 / 16,
      ),
      itemCount: videos.length,
      itemBuilder: (context, i) => _videoTile(context, videos[i], t),
    );
  }

  Widget _videoTile(BuildContext context, UserVideo video, AppStrings t) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoViewerScreen(video: video),
        ),
      ),
      onLongPress: canDelete && onDelete != null
          ? () => _showMenu(context, video, t)
          : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // MEDYA
            if (video.isImage && video.videoUrl.isNotEmpty)
              Image.network(
                video.videoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(),
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return _placeholder();
                },
              )
            else if (video.thumbnailUrl.isNotEmpty)
              Image.network(
                video.thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(),
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return _placeholder();
                },
              )
            else
              _placeholder(),

            // Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.5),
                  ],
                ),
              ),
            ),

            // Play ikonu
            if (!video.isImage)
              const Center(
                child: Icon(
                  Icons.play_circle_outline,
                  color: Colors.white,
                  size: 32,
                ),
              ),

            // Beğeni sayısı
            Positioned(
              left: 6,
              bottom: 6,
              child: Row(
                children: [
                  const Icon(Icons.favorite,
                      color: Colors.white, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    '${video.likes}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // 🔥 SİLME BUTONU (sağ üst) — KIRMIZI ÇÖP
            if (canDelete && onDelete != null)
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: () => _confirmDelete(context, video, t),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.red,
                      size: 20,
                    ),
                  ),
                ),
              ),

            // Story / IMG etiketi (sol üst)
            Positioned(
              left: 6,
              top: 6,
              child: Row(
                children: [
                  if (video.isStory)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'STORY',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  if (video.isImage)
                    Container(
                      margin: const EdgeInsets.only(left: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'IMG',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  if (video.musicName.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(left: 4),
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.music_note,
                          color: Colors.white, size: 10),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.card,
      child: Center(
        child: Icon(Icons.videocam,
            color: AppColors.textSecondary, size: 28),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, UserVideo video, AppStrings t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(
          video.isStory ? 'Story\'i Sil' : t.deleteVideoTitle,
          style: TextStyle(color: AppColors.text),
        ),
        content: Text(
          video.isStory
              ? 'Bu story\'i silmek istediğine emin misin?'
              : '"${video.title}" ${t.deleteVideoConfirm}',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancel,
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.delete,
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (ok == true) {
      onDelete?.call(video);
    }
  }

  void _showMenu(BuildContext context, UserVideo video, AppStrings t) {
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
              leading:
                  Icon(Icons.delete_outline, color: AppColors.error),
              title: Text(
                t.deleteVideoTitle,
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, video, t);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
