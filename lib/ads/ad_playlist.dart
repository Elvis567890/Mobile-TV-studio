import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// One commercial clip stored on the phone.
class AdClip {
  final String id;
  final String name;
  final String filePath;
  final int durationSeconds;

  AdClip({
    required this.id,
    required this.name,
    required this.filePath,
    required this.durationSeconds,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'filePath': filePath,
        'durationSeconds': durationSeconds,
      };

  factory AdClip.fromJson(Map<String, dynamic> j) => AdClip(
        id: j['id'] as String,
        name: j['name'] as String,
        filePath: j['filePath'] as String,
        durationSeconds: j['durationSeconds'] as int? ?? 0,
      );

  bool get exists => File(filePath).existsSync();
}

/// Manages the list of commercial clips.
class AdPlaylist {
  static const _kAds = 'ad_playlist';

  List<AdClip> _clips = [];
  List<AdClip> get clips => List.unmodifiable(_clips);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kAds);
    if (raw == null || raw.isEmpty) {
      _clips = [];
      return;
    }
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      _clips = list
          .map((e) => AdClip.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      _clips = [];
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_clips.map((c) => c.toJson()).toList());
    await prefs.setString(_kAds, raw);
  }

  /// Copy a chosen file into the app's private ads folder.
  Future<AdClip> addFromFile({
    required File source,
    required String name,
    int durationSeconds = 15,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final adsDir = Directory('${dir.path}/ads');
    if (!adsDir.existsSync()) adsDir.createSync(recursive: true);

    final id = const Uuid().v4();
    final ext = source.path.split('.').last;
    final dest = File('${adsDir.path}/$id.$ext');
    await source.copy(dest.path);

    final clip = AdClip(
      id: id,
      name: name,
      filePath: dest.path,
      durationSeconds: durationSeconds,
    );
    _clips.add(clip);
    await _persist();
    return clip;
  }

  Future<void> remove(String id) async {
    final match = _clips.where((c) => c.id == id).toList();
    for (final c in match) {
      try {
        final f = File(c.filePath);
        if (f.existsSync()) await f.delete();
      } catch (_) {}
    }
    _clips.removeWhere((c) => c.id == id);
    await _persist();
  }

  Future<void> rename(String id, String newName) async {
    final idx = _clips.indexWhere((c) => c.id == id);
    if (idx < 0) return;
    final old = _clips[idx];
    _clips[idx] = AdClip(
      id: old.id,
      name: newName,
      filePath: old.filePath,
      durationSeconds: old.durationSeconds,
    );
    await _persist();
  }

  /// Total time of all clips in the list, in seconds.
  int get totalSeconds =>
      _clips.fold(0, (sum, c) => sum + c.durationSeconds);

  /// Remove entries whose files no longer exist on disk.
  Future<void> pruneMissing() async {
    _clips.removeWhere((c) => !c.exists);
    await _persist();
  }
}
