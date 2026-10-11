import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/profile_service.dart';
import '../profile/user_profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;
  bool _hasSearched = false;

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) {
      setState(() {
        _results = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() => _loading = true);
    final res = await ProfileService.searchUsers(q.trim());
    if (!mounted) return;
    setState(() {
      _results = res;
      _loading = false;
      _hasSearched = true;
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL.of(context);

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.discover,
                    style: TextStyle(
                        color: AppColors.text,
                        fontSize: 24,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                TextField(
                  controller: _ctrl,
                  onSubmitted: _search,
                  onChanged: (v) {
                    if (v.length >= 2) _search(v);
                    if (v.isEmpty) _search('');
                  },
                  style: TextStyle(color: AppColors.text),
                  decoration: InputDecoration(
                    hintText: t.search,
                    hintStyle: TextStyle(color: AppColors.textSecondary),
                    prefixIcon:
                        Icon(Icons.search, color: AppColors.textSecondary),
                    suffixIcon: _ctrl.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.close,
                                color: AppColors.textSecondary),
                            onPressed: () {
                              _ctrl.clear();
                              _search('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : !_hasSearched
                    ? _placeholder(t)
                    : _results.isEmpty
                        ? _empty(t)
                        : ListView.builder(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _results.length,
                            itemBuilder: (context, i) =>
                                _userTile(_results[i]),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder(AppStrings t) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search,
              size: 80, color: AppColors.textSecondary.withOpacity(0.5)),
          const SizedBox(height: 24),
          Text(t.search,
              style: TextStyle(
                  color: AppColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _empty(AppStrings t) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off,
              size: 80, color: AppColors.textSecondary.withOpacity(0.5)),
          const SizedBox(height: 24),
          Text('Sonuç yok',
              style: TextStyle(
                  color: AppColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _userTile(Map<String, dynamic> user) {
    final username = user['username'] ?? 'kullanici';
    final avatar = user['avatar_url'];
    final bio = user['bio'] ?? '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UserProfileScreen(userId: user['id']),
          ),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary,
                backgroundImage:
                    avatar != null && avatar.isNotEmpty
                        ? NetworkImage(avatar)
                        : null,
                child: avatar == null || avatar.isEmpty
                    ? Text(username[0].toUpperCase(),
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700))
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('@$username',
                        style: TextStyle(
                            color: AppColors.text,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                    if (bio.isNotEmpty)
                      Text(bio,
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
