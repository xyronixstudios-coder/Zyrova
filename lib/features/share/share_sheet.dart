import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/share_service.dart';

class ShareSheet extends StatefulWidget {
  final String videoUrl;
  final String videoTitle;
  final String thumbnailUrl;
  final String authorUsername;

  const ShareSheet({
    super.key,
    required this.videoUrl,
    required this.videoTitle,
    required this.thumbnailUrl,
    required this.authorUsername,
  });

  @override
  State<ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<ShareSheet> {
  final _screenshotCtrl = ScreenshotController();
  bool _generating = false;

  Future<void> _generateStoryCard() async {
    setState(() => _generating = true);
    try {
      final imageBytes = await _screenshotCtrl.captureFromWidget(
        Material(
          color: Colors.transparent,
          child: _storyCardWidget(),
        ),
        delay: const Duration(milliseconds: 300),
        pixelRatio: 2.5,
      );

      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/zyrova_story_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(imageBytes);

      if (!mounted) return;

      // Paylaş
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '${widget.videoTitle}\n${widget.videoUrl}',
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      print('Story card error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Widget _storyCardWidget() {
    return SizedBox(
      width: 360,
      height: 640,
      child: Stack(
        children: [
          // Arka plan: thumbnail veya gradient
          Positioned.fill(
            child: widget.thumbnailUrl.isNotEmpty
                ? Image.network(
                    widget.thumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1E90FF), Color(0xFF0066FF)],
                        ),
                      ),
                    ),
                  )
                : Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1E90FF), Color(0xFF0066FF)],
                      ),
                    ),
                  ),
          ),
          // Koyu overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                    Colors.black.withOpacity(0.85),
                  ],
                ),
              ),
            ),
          ),
          // Zyrova Logo (üst)
          Positioned(
            top: 32,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.flash_on, color: Color(0xFF1E90FF), size: 20),
                    SizedBox(width: 6),
                    Text(
                      'Zyrova',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // İçerik (alt)
          Positioned(
            left: 24,
            right: 24,
            bottom: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E90FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '@zyrova',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.videoTitle.isEmpty
                      ? 'Yeni video!'
                      : widget.videoTitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: const Color(0xFF1E90FF),
                      child: Text(
                        widget.authorUsername.replaceAll('@', '')[0]
                            .toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.authorUsername,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Alt yazı
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'zyrova.app',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 11,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              t.share,
              style: TextStyle(
                color: AppColors.text,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),

            // 🔥 STORY KARTI BUTONU
            GestureDetector(
              onTap: _generating ? null : _generateStoryCard,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E90FF), Color(0xFF0066FF)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      _generating
                          ? Icons.hourglass_top
                          : Icons.auto_awesome,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _generating
                                ? 'Oluşturuluyor...'
                                : 'Story Kartı Oluştur',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Instagram / WhatsApp için',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_generating)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    else
                      const Icon(Icons.arrow_forward,
                          color: Colors.white, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Klasik paylaşım seçenekleri
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _shareItem(
                  context,
                  Icons.link,
                  t.shareCopy,
                  AppColors.primary,
                  () async {
                    await ShareService.copyLink(widget.videoUrl);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(t.linkCopied),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  },
                ),
                _shareItem(
                  context,
                  Icons.chat,
                  t.shareWhatsApp,
                  const Color(0xFF25D366),
                  () async {
                    await ShareService.shareWhatsApp(
                        '${widget.videoTitle}\n${widget.videoUrl}');
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
                _shareItem(
                  context,
                  Icons.alternate_email,
                  t.shareTwitter,
                  const Color(0xFF1DA1F2),
                  () async {
                    await ShareService.shareTwitter(
                        '${widget.videoTitle}\n${widget.videoUrl}');
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _shareItem(
                  context,
                  Icons.send,
                  t.shareTelegram,
                  const Color(0xFF0088CC),
                  () async {
                    await ShareService.shareTelegram(widget.videoUrl);
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
                _shareItem(
                  context,
                  Icons.email,
                  t.shareEmail,
                  AppColors.warning,
                  () async {
                    await ShareService.shareEmail(
                        widget.videoTitle, widget.videoUrl);
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
                const SizedBox(width: 64),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _shareItem(BuildContext context, IconData icon, String label,
      Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}
