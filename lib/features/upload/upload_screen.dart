import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
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

  File? _mediaFile;
  File? _customCover;
  File? _autoCover;
  File? _musicFile;

  bool _uploading = false;
  bool _isStory = false;
  bool _isImage = false;
  double _progress = 0.0;
  String _step = '';

  // ============================================
  // VİDEO SEÇ
  // ============================================
  Future<void> _pickVideo(ImageSource source) async {
    final picked = await ImagePicker().pickVideo(source: source);
    if (picked != null) {
      setState(() {
        _mediaFile = File(picked.path);
        _isImage = false;
        _autoCover = null;
        _customCover = null;
        _musicFile = null;
      });
      _generateCover();
    }
  }

  // ============================================
  // RESİM SEÇ
  // ============================================
  Future<void> _pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1080,
      imageQuality: 90,
    );
    if (picked != null) {
      setState(() {
        _mediaFile = File(picked.path);
        _isImage = true;
        _autoCover = File(picked.path);
        _customCover = null;
        _musicFile = null;
      });
    }
  }

  Future<void> _generateCover() async {
    if (_mediaFile == null || _isImage) return;
    setState(() => _step = 'Kapak oluşturuluyor...');
    final c = await VideoService.generateThumbnail(_mediaFile!);
    if (mounted) {
      setState(() {
        _autoCover = c;
        _step = '';
      });
    }
  }

  Future<void> _pickCover() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 720,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _customCover = File(picked.path));
    }
  }

  // ============================================
  // 🎵 MÜZİK SEÇ
  // ============================================
  Future<void> _pickMusic() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          _musicFile = File(result.files.single.path!);
        });
      }
    } catch (e) {
      _snack('Müzik seçilemedi: $e', AppColors.error);
    }
  }

  void _removeMusic() {
    setState(() => _musicFile = null);
  }

  // ============================================
  // YÜKLE
  // ============================================
  Future<void> _upload(AppStrings t) async {
    if (_mediaFile == null) {
      _snack(_isImage ? 'Resim seç' : 'Video seç', AppColors.error);
      return;
    }
    if (_titleCtrl.text.trim().isEmpty && !_isStory) {
      _snack('${t.title} gerekli', AppColors.error);
      return;
    }

    setState(() {
      _uploading = true;
      _progress = 0.1;
      _step = _isImage
          ? 'Resim yükleniyor...'
          : (_musicFile != null
              ? '🎵 Müzik birleştiriliyor...'
              : 'Video sıkıştırılıyor...');
    });

    try {
      File? compressed;
      File fileToUpload = _mediaFile!;

      // Müzik YOKSA video sıkıştır (müzik varsa ffmpeg zaten sıkıştırır)
      if (!_isImage && _musicFile == null) {
        compressed = await VideoService.compressVideo(_mediaFile!);
        if (compressed != null) fileToUpload = compressed;
      }

      setState(() {
        _progress = 0.5;
        _step = _musicFile != null
            ? '🎵 Müzik + video kaydediliyor...'
            : 'Kapak hazırlanıyor...';
      });

      final cover = _customCover ?? _autoCover;

      setState(() {
        _progress = 0.7;
        _step = '☁️ Sunucuya yükleniyor...';
      });

      final v = await VideoService.uploadVideo(
        videoFile: fileToUpload,
        title: _titleCtrl.text.trim(),
        caption: _captionCtrl.text.trim(),
        customCover: cover,
        musicFile: _musicFile,
        isStory: _isStory,
        isImage: _isImage,
      );

      try {
        if (compressed != null && compressed.path != _mediaFile!.path) {
          await compressed.delete();
        }
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _progress = 1.0;
        _step = '✅ Tamamlandı!';
      });

      if (v != null) {
        _snack(t.videoUploaded, AppColors.success);
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainScreen()),
          );
        }
      } else {
        _snack('Yükleme başarısız', AppColors.error);
      }
    } catch (e) {
      _snack('${t.error}: $e', AppColors.error);
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
          _progress = 0;
          _step = '';
        });
      }
    }
  }

  void _snack(String m, Color c) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: c),
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _captionCtrl.dispose();
    super.dispose();
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
            // BAŞLIK
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _isStory ? Icons.auto_awesome : Icons.add_box,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isStory ? 'Story Oluştur' : 'Video Yükle',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        _isStory
                            ? '24 saat görünür'
                            : 'Takipçilerinle paylaş',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // MOD
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _modeBtn(
                      icon: Icons.video_library,
                      label: 'Video',
                      active: !_isStory,
                      onTap: () => setState(() {
                        _isStory = false;
                        _mediaFile = null;
                        _isImage = false;
                        _autoCover = null;
                        _customCover = null;
                        _musicFile = null;
                      }),
                    ),
                  ),
                  Expanded(
                    child: _modeBtn(
                      icon: Icons.auto_awesome,
                      label: 'Story',
                      active: _isStory,
                      onTap: () => setState(() {
                        _isStory = true;
                        _mediaFile = null;
                        _isImage = false;
                        _autoCover = null;
                        _customCover = null;
                        _musicFile = null;
                      }),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // MEDYA ALANI
            if (_mediaFile == null)
              _mediaPlaceholder(t)
            else
              _mediaPreview(t),

            const SizedBox(height: 12),

            // SEÇİM BUTONLARI
            if (_mediaFile == null) _pickButtons(t),

            // KAPAK (video ise)
            if (_mediaFile != null && !_isImage) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Icon(Icons.image, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text('Kapak',
                      style: TextStyle(
                          color: AppColors.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _coverCard(
                      label: 'Otomatik',
                      file: _autoCover,
                      selected: _customCover == null && _autoCover != null,
                      isAuto: true,
                      onTap: () => setState(() => _customCover = null),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _coverCard(
                      label: 'Manuel',
                      file: _customCover,
                      selected: _customCover != null,
                      isAuto: false,
                      onTap: _pickCover,
                    ),
                  ),
                ],
              ),
            ],

            // 🎵 MÜZİK ALANI (video ise)
            if (_mediaFile != null && !_isImage) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Icon(Icons.music_note,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text('Müzik',
                      style: TextStyle(
                          color: AppColors.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(width: 6),
                  Text('(opsiyonel)',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 8),
              if (_musicFile == null)
                GestureDetector(
                  onTap: _pickMusic,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.library_music,
                              color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Müzik Ekle',
                                  style: TextStyle(
                                      color: AppColors.text,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text('MP3, WAV, M4A',
                                  style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11)),
                            ],
                          ),
                        ),
                        Icon(Icons.add_circle,
                            color: AppColors.primary, size: 26),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.music_note,
                            color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _musicFile!.path.split('/').last,
                              style: TextStyle(
                                color: AppColors.text,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text('Video sesi %20\'ye düşürülecek',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 10)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _removeMusic,
                        icon: Icon(Icons.close,
                            color: AppColors.error, size: 20),
                      ),
                    ],
                  ),
                ),
            ],

            // BAŞLIK + AÇIKLAMA
            if (_mediaFile != null) ...[
              const SizedBox(height: 24),
              Text('Başlık',
                  style: TextStyle(
                      color: AppColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              TextField(
                controller: _titleCtrl,
                style: TextStyle(color: AppColors.text),
                decoration: _inputDecor(t.titleHint, Icons.title),
              ),
              const SizedBox(height: 16),
              Text('Açıklama',
                  style: TextStyle(
                      color: AppColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              TextField(
                controller: _captionCtrl,
                maxLines: 3,
                style: TextStyle(color: AppColors.text),
                decoration: _inputDecor(t.captionHint, Icons.description),
              ),
              const SizedBox(height: 24),

              // PROGRESS
              if (_uploading) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.cloud_upload,
                              color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_step,
                                style: TextStyle(
                                    color: AppColors.text,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                          ),
                          Text('${(_progress * 100).toInt()}%',
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _progress,
                          minHeight: 6,
                          backgroundColor: AppColors.surface,
                          valueColor:
                              AlwaysStoppedAnimation(AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // YÜKLE BUTONU
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _uploading ? null : () => _upload(t),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _uploading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            ),
                            const SizedBox(width: 12),
                            Text('Yükleniyor...',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700)),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_isStory
                                ? Icons.auto_awesome
                                : Icons.cloud_upload),
                            const SizedBox(width: 8),
                            Text(
                              _isStory
                                  ? 'Story Olarak Paylaş'
                                  : t.uploadBtn,
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ============================================
  // YARDIMCI WIDGET'LAR
  // ============================================

  Widget _modeBtn({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: active ? Colors.white : AppColors.textSecondary,
                size: 18),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                  color: active ? Colors.white : AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                )),
          ],
        ),
      ),
    );
  }

  Widget _mediaPlaceholder(AppStrings t) {
    return GestureDetector(
      onTap: () {
        if (_isStory) {
          _pickImage(ImageSource.gallery);
        } else {
          _pickVideo(ImageSource.gallery);
        }
      },
      child: Container(
        width: double.infinity,
        height: 240,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withOpacity(0.15),
              AppColors.primary.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isStory
                    ? Icons.add_photo_alternate
                    : Icons.video_library,
                color: AppColors.primary,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isStory ? 'Story için medya seç' : t.selectVideo,
              style: TextStyle(
                color: AppColors.text,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _isStory
                  ? '📷 Fotoğraf veya 🎬 Video'
                  : 'MP4 / MOV • Max 50 MB',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mediaPreview(AppStrings t) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 240,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.success, width: 2),
          ),
          child: _isImage
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.file(
                    _mediaFile!,
                    fit: BoxFit.contain,
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check_circle,
                          color: AppColors.success, size: 48),
                    ),
                    const SizedBox(height: 12),
                    Text('Video Hazır!',
                        style: TextStyle(
                            color: AppColors.text,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        _mediaFile!.path.split('/').last,
                        style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
        ),
        Positioned(
          top: 10,
          right: 10,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _mediaFile = null;
                _autoCover = null;
                _customCover = null;
                _isImage = false;
                _musicFile = null;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, color: Colors.white, size: 18),
            ),
          ),
        ),
        if (_isStory)
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.warning,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(_isImage ? Icons.image : Icons.auto_awesome,
                      color: Colors.white, size: 12),
                  const SizedBox(width: 4),
                  Text(_isImage ? 'STORY • IMAGE' : 'STORY',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _pickButtons(AppStrings t) {
    if (_isStory) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _pickBtn(
                  icon: Icons.image,
                  label: 'Fotoğraf',
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _pickBtn(
                  icon: Icons.video_library,
                  label: 'Video',
                  onTap: () => _pickVideo(ImageSource.gallery),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: _pickBtn(
              icon: Icons.camera_alt,
              label: 'Kamera',
              onTap: () => _showPickSheet(t),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _pickBtn(
            icon: Icons.camera_alt,
            label: t.camera,
            onTap: () => _pickVideo(ImageSource.camera),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _pickBtn(
            icon: Icons.photo_library,
            label: t.cameraRoll,
            onTap: () => _pickVideo(ImageSource.gallery),
          ),
        ),
      ],
    );
  }

  void _showPickSheet(AppStrings t) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
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
            const SizedBox(height: 8),
            ListTile(
              leading:
                  Icon(Icons.camera_alt, color: AppColors.primary),
              title: Text('Fotoğraf Çek',
                  style: TextStyle(color: AppColors.text)),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.videocam, color: AppColors.primary),
              title: Text('Video Çek',
                  style: TextStyle(color: AppColors.text)),
              onTap: () {
                Navigator.pop(ctx);
                _pickVideo(ImageSource.camera);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _coverCard({
    required String label,
    required File? file,
    required bool selected,
    required bool isAuto,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 2.5,
          ),
          image: file != null
              ? DecorationImage(
                  image: FileImage(file),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: file == null
            ? Center(
                child: isAuto && _step.isNotEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: AppColors.primary,
                                strokeWidth: 2),
                          ),
                          const SizedBox(height: 8),
                          Text('Oluşturuluyor',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11)),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isAuto
                                ? Icons.auto_fix_high
                                : Icons.add_photo_alternate,
                            color: AppColors.primary,
                            size: 32,
                          ),
                          const SizedBox(height: 6),
                          Text(label,
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
              )
            : Stack(
                children: [
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(label,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                  if (selected)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.check,
                            color: Colors.white, size: 14),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _pickBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: AppColors.primary, size: 20),
      label: Text(label,
          style: TextStyle(
              color: AppColors.primary, fontWeight: FontWeight.w600)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  InputDecoration _inputDecor(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
      prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
      filled: true,
      fillColor: AppColors.card,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}
