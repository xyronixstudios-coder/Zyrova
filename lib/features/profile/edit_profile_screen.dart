import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/profile_service.dart';
import '../../core/widgets/banner_widget.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> currentProfile;

  const EditProfileScreen({super.key, required this.currentProfile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _bioCtrl = TextEditingController();
  String _bannerType = 'gradient';
  String _bannerColor1 = '#1E90FF';
  String _bannerColor2 = '#0066FF';
  String _bannerPattern = 'none';
  String? _avatarUrl;
  bool _saving = false;
  bool _uploadingAvatar = false;

  final _colorPalette = [
    '#1E90FF', '#0066FF', '#00BCD4', '#00C853',
    '#8BC34A', '#FFC107', '#FF6B00', '#FF1744',
    '#FF4081', '#E91E63', '#9C27B0', '#673AB7',
    '#3F51B5', '#009688', '#795548', '#607D8B',
    '#000000', '#424242', '#FFFFFF', '#E0E0E0',
  ];

  @override
  void initState() {
    super.initState();
    _bioCtrl.text = widget.currentProfile['bio'] ?? '';
    _bannerType = widget.currentProfile['banner_type'] ?? 'gradient';
    _bannerColor1 = widget.currentProfile['banner_color'] ?? '#1E90FF';
    _bannerColor2 = widget.currentProfile['banner_color2'] ?? '#0066FF';
    _bannerPattern = widget.currentProfile['banner_pattern'] ?? 'none';
    _avatarUrl = widget.currentProfile['avatar_url'];
  }

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (picked == null) return;
    setState(() => _uploadingAvatar = true);
    final url = await ProfileService.uploadAvatar(File(picked.path));
    if (mounted) {
      setState(() {
        _avatarUrl = url;
        _uploadingAvatar = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await ProfileService.updateBio(_bioCtrl.text.trim());
    await ProfileService.updateBanner(
      type: _bannerType,
      color1: _bannerColor1,
      color2: _bannerColor2,
      pattern: _bannerPattern,
    );
    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(context, true);
    }
  }

  Color _hex(String hex) =>
      Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));

  @override
  void dispose() {
    _bioCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL.of(context);

    final bannerTypes = [
      {'value': 'solid', 'label': t.solid},
      {'value': 'gradient', 'label': t.gradient},
      {'value': 'pattern', 'label': t.pattern},
    ];

    final patterns = [
      {'value': 'none', 'label': t.none},
      {'value': 'dots', 'label': t.dots},
      {'value': 'stripes', 'label': t.stripes},
      {'value': 'waves', 'label': t.waves},
      {'value': 'circles', 'label': t.circles},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        elevation: 0,
        title: Text(t.editProfile,
            style: TextStyle(color: AppColors.text)),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: AppColors.primary, strokeWidth: 2))
                : Text(t.save,
                    style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 180,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  BannerWidget(
                    type: _bannerType,
                    color1: _bannerColor1,
                    color2: _bannerColor2,
                    pattern: _bannerPattern,
                  ),
                  Positioned(
                    bottom: -50,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: _pickAvatar,
                        child: Stack(
                          children: [
                            Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary,
                                border: Border.all(
                                    color: AppColors.background, width: 4),
                                image: _avatarUrl != null &&
                                        _avatarUrl!.isNotEmpty
                                    ? DecorationImage(
                                        image: NetworkImage(_avatarUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: _avatarUrl == null ||
                                      _avatarUrl!.isEmpty
                                  ? Icon(Icons.person,
                                      color: Colors.white, size: 56)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: _uploadingAvatar
                                    ? SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2))
                                    : Icon(Icons.camera_alt,
                                        color: Colors.white, size: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 70),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.bannerType,
                      style: TextStyle(
                          color: AppColors.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Row(
                    children: bannerTypes.map((bt) {
                      final selected = _bannerType == bt['value'];
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(
                              () => _bannerType = bt['value']!),
                          child: Container(
                            margin:
                                const EdgeInsets.symmetric(horizontal: 4),
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.card,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                bt['label']!,
                                style: TextStyle(
                                  color: selected
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Text(_bannerType == 'solid'
                          ? t.colorLabel
                          : t.primaryColor,
                      style: TextStyle(
                          color: AppColors.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _colorPalette.map((hex) {
                      final selected = _bannerColor1 == hex;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _bannerColor1 = hex),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _hex(hex),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: selected
                              ? Icon(Icons.check,
                                  color: Colors.white, size: 20)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  if (_bannerType != 'solid') ...[
                    const SizedBox(height: 20),
                    Text(t.secondColor,
                        style: TextStyle(
                            color: AppColors.text,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _colorPalette.map((hex) {
                        final selected = _bannerColor2 == hex;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _bannerColor2 = hex),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: _hex(hex),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected
                                    ? AppColors.primary
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                            child: selected
                                ? Icon(Icons.check,
                                    color: Colors.white, size: 20)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  if (_bannerType == 'pattern') ...[
                    const SizedBox(height: 20),
                    Text(t.patternType,
                        style: TextStyle(
                            color: AppColors.text,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: patterns.map((p) {
                        final selected = _bannerPattern == p['value'];
                        return GestureDetector(
                          onTap: () => setState(
                              () => _bannerPattern = p['value']!),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.card,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              p['label']!,
                              style: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(t.bio,
                      style: TextStyle(
                          color: AppColors.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _bioCtrl,
                    maxLines: 3,
                    maxLength: 150,
                    style: TextStyle(color: AppColors.text),
                    decoration: InputDecoration(
                      hintText: t.hintAboutYou,
                      hintStyle:
                          TextStyle(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.card,
                      counterStyle:
                          TextStyle(color: AppColors.textSecondary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Text(t.save,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
