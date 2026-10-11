import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/video_service.dart';
import '../home/main_screen.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final _titleCtrl = TextEditingController();
  final _captionCtrl = TextEditingController();
  File? _videoFile;
  bool _uploading = false;

  Future<void> _pickVideo() async {
    final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (picked != null) setState(() => _videoFile = File(picked.path));
  }

  Future<void> _pickFromCamera() async {
    final picked = await ImagePicker().pickVideo(source: ImageSource.camera);
    if (picked != null) setState(() => _videoFile = File(picked.path));
  }

  Future<void> _upload() async {
    if (_videoFile == null || _titleCtrl.text.trim().isEmpty) return;
    setState(() => _uploading = true);
    try {
      // 🔥 480p sıkıştırma (Linux/Mac/Windows)
      File? compressed = await VideoService.compressVideo(_videoFile!);
      final fileToUpload = compressed ?? _videoFile!;

      final v = await VideoService.uploadVideo(
        videoFile: fileToUpload,
        title: _titleCtrl.text.trim(),
        caption: _captionCtrl.text.trim(),
      );
      // Geçici sıkıştırılmış dosyayı sil
      if (compressed != null) {
        try { await compressed.delete(); } catch (_) {}
      }

      if (v != null && mounted) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const MainScreen()));
      }
    } catch (e) {}
    if (mounted) setState(() => _uploading = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.upload,
                style: TextStyle(
                    color: AppColors.text,
                    fontSize: 24,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _videoFile == null ? _pickVideo : null,
              child: Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _videoFile == null
                        ? AppColors.textSecondary
                        : AppColors.primary,
                    width: 2,
                  ),
                ),
                child: _videoFile == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.video_library,
                              color: AppColors.primary, size: 64),
                          const SizedBox(height: 16),
                          Text(t.selectVideo,
                              style: TextStyle(
                                  color: AppColors.text,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Text(t.gallery,
                              style:
                                  TextStyle(color: AppColors.textSecondary)),
                        ],
                      )
                    : Center(
                        child: Icon(Icons.check_circle,
                            color: AppColors.success, size: 64),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickFromCamera,
                    icon: Icon(Icons.camera_alt, color: AppColors.primary),
                    label: Text(t.camera,
                        style: TextStyle(color: AppColors.primary)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickVideo,
                    icon: Icon(Icons.photo_library, color: AppColors.primary),
                    label: Text(t.gallery,
                        style: TextStyle(color: AppColors.primary)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _titleCtrl,
              style: TextStyle(color: AppColors.text),
              decoration: InputDecoration(
                hintText: t.title,
                hintStyle: TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _captionCtrl,
              maxLines: 3,
              style: TextStyle(color: AppColors.text),
              decoration: InputDecoration(
                hintText: t.caption,
                hintStyle: TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _uploading ? null : _upload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _uploading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(t.uploadBtn,
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
