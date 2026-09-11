import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'data_budget.dart';

/// A saved setup. The operator picks "Church", or "Field report",
/// and every setting is restored in one tap.
class BroadcastProfile {
  final String id;
  final String name;
  final String? primaryTargetId;
  final BudgetMode budgetMode;
  final int previewColumns;
  final bool audioMixerOpen;
  final bool titlesOpen;

  BroadcastProfile({
    required this.id,
    required this.name,
    this.primaryTargetId,
    this.budgetMode = BudgetMode.moderate,
    this.previewColumns = 2,
    this.audioMixerOpen = false,
    this.titlesOpen = false,
  });

  BroadcastProfile copyWith({
    String? name,
    String? primaryTargetId,
    BudgetMode? budgetMode,
    int? previewColumns,
    bool? audioMixerOpen,
    bool? titlesOpen,
  }) {
    return BroadcastProfile(
      id: id,
      name: name ?? this.name,
      primaryTargetId: primaryTargetId ?? this.primaryTargetId,
      budgetMode: budgetMode ?? this.budgetMode,
      previewColumns: previewColumns ?? this.previewColumns,
      audioMixerOpen: audioMixerOpen ?? this.audioMixerOpen,
      titlesOpen: titlesOpen ?? this.titlesOpen,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'primaryTargetId': primaryTargetId,
        'budgetMode': budgetMode.name,
        'previewColumns': previewColumns,
        'audioMixerOpen': audioMixerOpen,
        'titlesOpen': titlesOpen,
      };

  factory BroadcastProfile.fromJson(Map<String, dynamic> j) => BroadcastProfile(
        id: j['id'] as String,
        name: j['name'] as String,
        primaryTargetId: j['primaryTargetId'] as String?,
        budgetMode: BudgetMode.values.firstWhere(
          (b) => b.name == j['budgetMode'],
          orElse: () => BudgetMode.moderate,
        ),
        previewColumns: j['previewColumns'] as int? ?? 2,
        audioMixerOpen: j['audioMixerOpen'] as bool? ?? false,
        titlesOpen: j['titlesOpen'] as bool? ?? false,
      );

  /// A sensible starting profile for first launch.
  static BroadcastProfile defaultProfile() => BroadcastProfile(
        id: const Uuid().v4(),
        name: 'Default',
        budgetMode: BudgetMode.moderate,
        previewColumns: 2,
      );
}

/// Persists broadcast profiles on disk.
class ProfileStore {
  static const _kProfiles = 'broadcast_profiles';

  Future<List<BroadcastProfile>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kProfiles);
    if (raw == null || raw.isEmpty) {
      return [BroadcastProfile.defaultProfile()];
    }
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final profiles = list
          .map((e) => BroadcastProfile.fromJson(e as Map<String, dynamic>))
          .toList();
      return profiles.isEmpty ? [BroadcastProfile.defaultProfile()] : profiles;
    } catch (_) {
      return [BroadcastProfile.defaultProfile()];
    }
  }

  Future<void> saveAll(List<BroadcastProfile> profiles) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(profiles.map((p) => p.toJson()).toList());
    await prefs.setString(_kProfiles, raw);
  }

  Future<void> upsert(BroadcastProfile p) async {
    final all = await loadAll();
    final idx = all.indexWhere((x) => x.id == p.id);
    if (idx >= 0) {
      all[idx] = p;
    } else {
      all.add(p);
    }
    await saveAll(all);
  }

  Future<void> remove(String id) async {
    final all = await loadAll();
    all.removeWhere((p) => p.id == id);
    if (all.isEmpty) all.add(BroadcastProfile.defaultProfile());
    await saveAll(all);
  }
}
