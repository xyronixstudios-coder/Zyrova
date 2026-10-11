import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacheEntry {
  final String key;
  final String path;
  final int sizeBytes;
  DateTime lastAccessed;
  int accessCount;

  CacheEntry({
    required this.key,
    required this.path,
    required this.sizeBytes,
    required this.lastAccessed,
    this.accessCount = 0,
  });
}

class SmartCache {
  static const int maxSizeMB = 200;
  static const String _indexKey = 'zyrova_cache_index';
  static const String _metaKey = 'zyrova_cache_meta';
  static SmartCache? _instance;

  final LinkedHashMap<String, CacheEntry> _entries = LinkedHashMap();
  int _currentSizeBytes = 0;

  SmartCache._();

  static SmartCache get instance {
    _instance ??= SmartCache._();
    return _instance!;
  }

  int get maxSizeBytes => maxSizeMB * 1024 * 1024;
  int get currentSizeBytes => _currentSizeBytes;
  double get currentSizeMB => _currentSizeBytes / (1024 * 1024);
  double get usagePercent => (_currentSizeBytes / maxSizeBytes) * 100;

  // ============================================
  // META VERİ (JSON string)
  // ============================================
  Future<void> putMeta(String key, String jsonValue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_metaKey}_$key', jsonValue);
  }

  Future<String?> getMeta(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('${_metaKey}_$key');
  }

  Future<void> removeMeta(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_metaKey}_$key');
  }

  // ============================================
  // DOSYA CACHE
  // ============================================
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getStringList(_indexKey) ?? [];

    for (final item in index) {
      final parts = item.split('|');
      if (parts.length < 5) continue;

      final key = parts[0];
      final path = parts[1];
      final size = int.tryParse(parts[2]) ?? 0;
      final lastAccess = DateTime.tryParse(parts[3]) ?? DateTime.now();
      final count = int.tryParse(parts[4]) ?? 0;

      final file = File(path);
      if (!await file.exists()) continue;

      _entries[key] = CacheEntry(
        key: key,
        path: path,
        sizeBytes: size,
        lastAccessed: lastAccess,
        accessCount: count,
      );
      _currentSizeBytes += size;
    }

    await _enforceLimit();
  }

  Future<void> put(String key, File file) async {
    if (_entries.containsKey(key)) {
      await remove(key);
    }

    final size = await file.length();
    final entry = CacheEntry(
      key: key,
      path: file.path,
      sizeBytes: size,
      lastAccessed: DateTime.now(),
      accessCount: 1,
    );

    _entries[key] = entry;
    _currentSizeBytes += size;

    await _enforceLimit();
    await _saveIndex();
  }

  Future<File?> get(String key) async {
    final entry = _entries[key];
    if (entry == null) return null;

    final file = File(entry.path);
    if (!await file.exists()) {
      _entries.remove(key);
      await _saveIndex();
      return null;
    }

    entry.lastAccessed = DateTime.now();
    entry.accessCount++;

    _entries.remove(key);
    _entries[key] = entry;

    await _saveIndex();
    return file;
  }

  bool has(String key) => _entries.containsKey(key);

  Future<void> remove(String key) async {
    final entry = _entries.remove(key);
    if (entry == null) return;

    _currentSizeBytes -= entry.sizeBytes;
    try {
      final file = File(entry.path);
      if (await file.exists()) await file.delete();
    } catch (_) {}
    await _saveIndex();
  }

  Future<void> clear() async {
    for (final entry in _entries.values) {
      try {
        final file = File(entry.path);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
    _entries.clear();
    _currentSizeBytes = 0;
    await _saveIndex();

    // Meta cache'leri de temizle
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_metaKey));
    for (final k in keys) {
      await prefs.remove(k);
    }
  }

  Future<void> _enforceLimit() async {
    while (_currentSizeBytes > maxSizeBytes && _entries.isNotEmpty) {
      final oldestKey = _entries.keys.first;
      await remove(oldestKey);
    }
  }

  Future<void> _saveIndex() async {
    final prefs = await SharedPreferences.getInstance();
    final index = _entries.values
        .map((e) => '${e.key}|${e.path}|${e.sizeBytes}|'
            '${e.lastAccessed.toIso8601String()}|${e.accessCount}')
        .toList();
    await prefs.setStringList(_indexKey, index);
  }

  static Future<Directory> getCacheDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${dir.path}/zyrova_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  Map<String, dynamic> getStats() => {
        'count': _entries.length,
        'sizeMB': currentSizeMB,
        'maxMB': maxSizeMB.toDouble(),
        'usagePercent': usagePercent,
      };
}
