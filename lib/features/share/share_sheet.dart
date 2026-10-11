import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/share_service.dart';

class ShareSheet extends StatelessWidget {
  final String videoUrl;
  final String videoTitle;

  const ShareSheet({
    super.key,
    required this.videoUrl,
    required this.videoTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
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
            'Paylaş',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          // Paylaş seçenekleri
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _shareItem(
                context,
                Icons.link,
                'Link Kopyala',
                AppColors.primary,
                () async {
                  await ShareService.copyLink(videoUrl);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Link kopyalandı!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
              ),
              _shareItem(
                context,
                Icons.chat,
                'WhatsApp',
                Color(0xFF25D366),
                () async {
                  await ShareService.shareWhatsApp(
                      '$videoTitle\n$videoUrl');
                  if (context.mounted) Navigator.pop(context);
                },
              ),
              _shareItem(
                context,
                Icons.alternate_email,
                'Twitter',
                Color(0xFF1DA1F2),
                () async {
                  await ShareService.shareTwitter(
                      '$videoTitle\n$videoUrl');
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _shareItem(
                context,
                Icons.send,
                'Telegram',
                Color(0xFF0088CC),
                () async {
                  await ShareService.shareTelegram(videoUrl);
                  if (context.mounted) Navigator.pop(context);
                },
              ),
              _shareItem(
                context,
                Icons.email,
                'E-posta',
                AppColors.warning,
                () async {
                  await ShareService.shareEmail(
                      videoTitle, videoUrl);
                  if (context.mounted) Navigator.pop(context);
                },
              ),
              const SizedBox(width: 64),
            ],
          ),
          const SizedBox(height: 20),
        ],
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
