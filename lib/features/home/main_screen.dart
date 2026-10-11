import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/services/smart_cache.dart';
import 'home_screen.dart';
import '../search/search_screen.dart';
import '../upload/upload_screen.dart';
import '../messages/messages_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;

  final _screens = const [
    HomeScreen(),
    SearchScreen(),
    UploadScreen(),
    MessagesScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    SmartCache.instance.init();
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL.of(context);
    final type = Responsive.of(context);

    if (type == ScreenType.mobile) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: _screens[_index],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          items: [
            BottomNavigationBarItem(
                icon: const Icon(Icons.home), label: t.home),
            BottomNavigationBarItem(
                icon: const Icon(Icons.search), label: t.discover),
            BottomNavigationBarItem(
              icon: const Icon(Icons.add_box,
                  size: 32, color: AppColors.primary),
              label: '',
            ),
            BottomNavigationBarItem(
                icon: const Icon(Icons.message), label: t.messages),
            BottomNavigationBarItem(
                icon: const Icon(Icons.person), label: t.profile),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          Container(
            width: type == ScreenType.desktop ? 240 : 80,
            color: AppColors.surface,
            child: Column(
              children: [
                const SizedBox(height: 24),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/zyrova-logo.png',
                    width: 44,
                    height: 44,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.flash_on,
                      color: AppColors.primary,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _item(Icons.home, t.home, 0, type),
                _item(Icons.search, t.discover, 1, type),
                _item(Icons.add_box, t.upload, 2, type),
                _item(Icons.message, t.messages, 3, type),
                _item(Icons.person, t.profile, 4, type),
                const Spacer(),
                _item(Icons.settings, t.settings, -1, type),
                const SizedBox(height: 16),
              ],
            ),
          ),
          Expanded(child: _screens[_index]),
        ],
      ),
    );
  }

  Widget _item(IconData icon, String label, int index, ScreenType type) {
    final active = _index == index;
    final isSettings = index == -1;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (isSettings) {
            _openSettings();
          } else {
            setState(() => _index = index);
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: EdgeInsets.symmetric(
            vertical: 12,
            horizontal: type == ScreenType.desktop ? 16 : 12,
          ),
          decoration: BoxDecoration(
            color: active
                ? AppColors.primary.withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: type == ScreenType.desktop
              ? Row(
                  children: [
                    Icon(icon,
                        color: active
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        size: 22),
                    const SizedBox(width: 16),
                    Text(
                      label,
                      style: TextStyle(
                        color: active
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontSize: 15,
                        fontWeight: active
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                )
              : Center(
                  child: Icon(icon,
                      color: active
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      size: 26),
                ),
        ),
      ),
    );
  }
}
