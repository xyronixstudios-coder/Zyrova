import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _likes = true, _comments = true, _follows = true, _mentions = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _likes = p.getBool('notif_likes') ?? true;
      _comments = p.getBool('notif_comments') ?? true;
      _follows = p.getBool('notif_follows') ?? true;
      _mentions = p.getBool('notif_mentions') ?? true;
    });
  }

  Future<void> _save(String k, bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(k, v);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        elevation: 0,
        title: Text(t.notifications,
            style: TextStyle(color: AppColors.text)),
      ),
      body: ListView(
        children: [
          _s(t.likes, _likes, (v) {
            setState(() => _likes = v);
            _save('notif_likes', v);
          }),
          _s(t.comments, _comments, (v) {
            setState(() => _comments = v);
            _save('notif_comments', v);
          }),
          _s(t.followers, _follows, (v) {
            setState(() => _follows = v);
            _save('notif_follows', v);
          }),
          _s(t.follow, _mentions, (v) {
            setState(() => _mentions = v);
            _save('notif_mentions', v);
          }),
        ],
      ),
    );
  }

  Widget _s(String t, bool v, Function(bool) cb) {
    return SwitchListTile(
      activeColor: AppColors.primary,
      title: Text(t, style: TextStyle(color: AppColors.text)),
      value: v,
      onChanged: cb,
    );
  }
}
