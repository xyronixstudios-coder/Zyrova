import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class ShareService {
  // Link kopyala
  static Future<void> copyLink(String videoUrl) async {
    await Clipboard.setData(ClipboardData(text: videoUrl));
  }

  // WhatsApp paylaş
  static Future<void> shareWhatsApp(String text) async {
    final uri = Uri.parse('whatsapp://send?text=${Uri.encodeComponent(text)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // Twitter paylaş
  static Future<void> shareTwitter(String text) async {
    final uri = Uri.parse(
        'https://twitter.com/intent/tweet?text=${Uri.encodeComponent(text)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // Telegram paylaş
  static Future<void> shareTelegram(String text) async {
    final uri = Uri.parse(
        'https://t.me/share/url?url=${Uri.encodeComponent(text)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // Genel paylaş (mail vb.)
  static Future<void> shareEmail(String subject, String body) async {
    final uri = Uri.parse(
        'mailto:?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
