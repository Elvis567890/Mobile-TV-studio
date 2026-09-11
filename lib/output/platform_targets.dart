import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

enum StreamPlatform { youtube, facebook, twitch, custom }

class StreamTarget {
  final String id;
  final StreamPlatform platform;
  final String displayName;
  final String rtmpUrl;
  final String streamKey;

  StreamTarget({
    required this.id,
    required this.platform,
    required this.displayName,
    required this.rtmpUrl,
    required this.streamKey,
  });

  /// The full URL an RTMP library needs.
  String get fullUrl => '$rtmpUrl/$streamKey';

  Map<String, dynamic> toJson() => {
        'id': id,
        'platform': platform.name,
        'displayName': displayName,
        'rtmpUrl': rtmpUrl,
        'streamKey': streamKey,
      };

  factory StreamTarget.fromJson(Map<String, dynamic> j) => StreamTarget(
        id: j['id'] as String,
        platform: StreamPlatform.values.firstWhere(
          (p) => p.name == j['platform'],
          orElse: () => StreamPlatform.custom,
        ),
        displayName: j['displayName'] as String,
        rtmpUrl: j['rtmpUrl'] as String,
        streamKey: j['streamKey'] as String,
      );

  /// Default RTMP endpoints per platform.
  static String defaultRtmpUrl(StreamPlatform p) {
    switch (p) {
      case StreamPlatform.youtube:
        return 'rtmp://a.rtmp.youtube.com/live2';
      case StreamPlatform.facebook:
        return 'rtmps://live-api-s.facebook.com:443/rtmp';
      case StreamPlatform.twitch:
        return 'rtmp://live.twitch.tv/app';
      case StreamPlatform.custom:
        return 'rtmp://your-server/live';
    }
  }

  static const Map<StreamPlatform, String> platformNames = {
    StreamPlatform.youtube: 'YouTube',
    StreamPlatform.facebook: 'Facebook',
    StreamPlatform.twitch: 'Twitch',
    StreamPlatform.custom: 'Custom RTMP',
  };
}

/// Persists stream targets on disk.
class TargetStore {
  static const _kTargets = 'stream_targets';

  Future<List<StreamTarget>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kTargets);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => StreamTarget.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveAll(List<StreamTarget> targets) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(targets.map((t) => t.toJson()).toList());
    await prefs.setString(_kTargets, raw);
  }

  Future<void> add(StreamTarget t) async {
    final all = await loadAll();
    all.removeWhere((x) => x.id == t.id);
    all.add(t);
    await saveAll(all);
  }

  Future<void> remove(String id) async {
    final all = await loadAll();
    all.removeWhere((x) => x.id == id);
    await saveAll(all);
  }
}
