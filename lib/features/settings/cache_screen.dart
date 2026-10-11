import '../../core/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/smart_cache.dart';
import '../../core/utils/responsive.dart';

class CacheScreen extends StatefulWidget {
  const CacheScreen({super.key});

  @override
  State<CacheScreen> createState() => _CacheScreenState();
}

class _CacheScreenState extends State<CacheScreen> {
  final _cache = SmartCache.instance;
  bool _loading = false;

  Future<void> _clearCache() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('Cache Temizle',
            style: TextStyle(color: AppColors.text)),
        content: Text(
          'Tum onbellek silinecek. Emin misin?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Iptal',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Temizle',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    setState(() => _loading = true);
    await _cache.clear();
    if (mounted) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cache temizlendi'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = _cache.getStats();
    final sizeMB = stats['sizeMB'] as double;
    final maxMB = stats['maxMB'] as double;
    final percent = stats['usagePercent'] as double;
    final count = stats['count'] as int;

    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        elevation: 0,
        title: Text(
          'Depolama ve Cache',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Büyük gösterge
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 180,
                            height: 180,
                            child: CircularProgressIndicator(
                              value: (percent / 100).clamp(0.0, 1.0),
                              strokeWidth: 14,
                              backgroundColor: AppColors.surface,
                              valueColor: AlwaysStoppedAnimation(
                                percent > 80
                                    ? AppColors.error
                                    : percent > 50
                                        ? AppColors.warning
                                        : AppColors.primary,
                              ),
                            ),
                          ),
                          Column(
                            children: [
                              Text(
                                sizeMB.toStringAsFixed(1),
                                style: TextStyle(
                                  color: AppColors.text,
                                  fontSize: 44,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'MB / ${maxMB.toInt()} MB',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 24),
                      Text(
                        '$count video onbellekte',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24),

                // Bilgi kutusu
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline,
                          color: AppColors.primary, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'SmartCache, izledigin videolari gecici olarak saklar. '
                          '200 MB sinirina ulasinca en eski videolar silinir.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24),

                // Temizle butonu
                OutlinedButton.icon(
                  onPressed: _loading ? null : _clearCache,
                  icon: _loading
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.error),
                        )
                      : Icon(Icons.delete_outline,
                          color: AppColors.error),
                  label: Text(
                    'Cache Temizle',
                    style: TextStyle(
                        color: AppColors.error, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
