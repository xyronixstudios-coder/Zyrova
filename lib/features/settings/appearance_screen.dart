import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_provider.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppL.of(context);
    final tp = context.watch<ThemeProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        elevation: 0,
        title: Text(t.appearance,
            style: TextStyle(color: AppColors.text)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(t.theme,
              style: TextStyle(
                  color: AppColors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(children: [
            _btn(tp, 'dark', t.dark),
            const SizedBox(width: 12),
            _btn(tp, 'light', t.light),
          ]),
        ],
      ),
    );
  }

  Widget _btn(ThemeProvider tp, String v, String l) {
    final sel = tp.theme == v;
    return Expanded(
      child: GestureDetector(
        onTap: () => tp.setTheme(v),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: sel ? AppColors.primary : AppColors.card,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(l,
                style: TextStyle(
                    color: sel ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }
}
