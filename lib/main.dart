import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:media_kit/media_kit.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/localization/locale_provider.dart';
import 'core/services/deep_link_service.dart';
import 'features/splash/splash_screen.dart';
import 'features/auth/reset_password_screen.dart';
import 'core/navigation/route_observer.dart';

const supabaseUrl = 'https://gbbeplpytmhxmwvnkpgf.supabase.co';
const supabaseAnonKey = 'sb_publishable_i2OPVq7bA5s7Y9D2oMiv4g_BZb5oRTi';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  MediaKit.ensureInitialized();

  // 🔥 12.5: Deep link başlat
  await DeepLinkService.init();
  DeepLinkService.onPasswordReset = (_) {
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
      (_) => false,
    );
  };

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()..load()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()..load()),
      ],
      child: const ZyrovaApp(),
    ),
  );
}

class ZyrovaApp extends StatelessWidget {
  const ZyrovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LocaleProvider>(
      builder: (context, theme, localeProvider, _) {
        if (theme.isDark) {
          AppColors.setDark();
        } else {
          AppColors.setLight();
        }

        final currentLocale = localeProvider.locale;
        final appKey =
            ValueKey('${theme.theme}_${currentLocale.languageCode}');

        return MaterialApp(
          navigatorKey: navigatorKey,
          navigatorObservers: [routeObserver],
          key: appKey,
          title: 'Zyrova',
          debugShowCheckedModeBanner: false,
          theme: theme.isDark
              ? AppTheme.buildDark(theme.accentColor)
              : AppTheme.buildLight(theme.accentColor),
          locale: currentLocale,
          supportedLocales: const [Locale('tr'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const SplashScreen(),
        );
      },
    );
  }
}
