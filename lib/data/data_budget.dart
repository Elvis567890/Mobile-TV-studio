import 'package:flutter/foundation.dart';

/// What the operator is allowed to spend on mobile data this session.
enum BudgetMode {
  unlimited,   // Wi-Fi present, no cap
  generous,    // 1.5 GB / hour
  moderate,    // 700 MB / hour
  conservative, // 400 MB / hour
  minimal,     // 180 MB / hour
}

extension BudgetModeX on BudgetMode {
  /// Approximate MB per hour at this budget.
  int get mbPerHour {
    switch (this) {
      case BudgetMode.unlimited:
        return 999999;
      case BudgetMode.generous:
        return 1500;
      case BudgetMode.moderate:
        return 700;
      case BudgetMode.conservative:
        return 400;
      case BudgetMode.minimal:
        return 180;
    }
  }

  /// Average bitrate in kbps to hit this budget.
  int get targetKbps {
    // MB/hour * 8 / 3600 * 1024 = kbps
    return ((mbPerHour * 8 * 1024) / 3600).round();
  }

  /// Best quality label this budget can support.
  String get quality {
    switch (this) {
      case BudgetMode.unlimited:
        return '1080p';
      case BudgetMode.generous:
        return '720p';
      case BudgetMode.moderate:
        return '480p';
      case BudgetMode.conservative:
        return '360p';
      case BudgetMode.minimal:
        return '240p';
    }
  }

  String get label {
    switch (this) {
      case BudgetMode.unlimited:
        return 'Unlimited';
      case BudgetMode.generous:
        return 'Generous';
      case BudgetMode.moderate:
        return 'Moderate';
      case BudgetMode.conservative:
        return 'Conservative';
      case BudgetMode.minimal:
        return 'Minimal';
    }
  }

  String get description {
    switch (this) {
      case BudgetMode.unlimited:
        return 'No cap. Best quality. Use on Wi-Fi.';
      case BudgetMode.generous:
        return '~1.5 GB / hour. 720p. Good Wi-Fi or strong 4G.';
      case BudgetMode.moderate:
        return '~700 MB / hour. 480p. Normal mobile use.';
      case BudgetMode.conservative:
        return '~400 MB / hour. 360p. Long sessions.';
      case BudgetMode.minimal:
        return '~180 MB / hour. 240p. Emergency backup.';
    }
  }
}

/// Tracks how much data this session has used and estimates time left.
class DataBudget extends ChangeNotifier {
  BudgetMode _mode = BudgetMode.moderate;
  BudgetMode get mode => _mode;

  int _bytesUsed = 0;
  int get bytesUsed => _bytesUsed;

  double get megabytesUsed => _bytesUsed / (1024 * 1024);
  double get gigabytesUsed => _bytesUsed / (1024 * 1024 * 1024);

  DateTime? _sessionStart;
  Duration get sessionDuration {
    if (_sessionStart == null) return Duration.zero;
    return DateTime.now().difference(_sessionStart!);
  }

  /// Bytes per second averaged over this session.
  double get currentBytesPerSecond {
    final secs = sessionDuration.inMilliseconds / 1000.0;
    if (secs <= 0) return 0;
    return _bytesUsed / secs;
  }

  /// Estimated MB per hour at the current rate.
  double get projectedMbPerHour {
    final bps = currentBytesPerSecond;
    if (bps <= 0) return 0;
    return (bps * 3600) / (1024 * 1024);
  }

  /// True when the projected use is above the chosen budget.
  bool get overBudget {
    if (_mode == BudgetMode.unlimited) return false;
    return projectedMbPerHour > _mode.mbPerHour * 1.15;
  }

  void startSession() {
    _sessionStart = DateTime.now();
    _bytesUsed = 0;
    notifyListeners();
  }

  void setMode(BudgetMode m) {
    _mode = m;
    notifyListeners();
  }

  /// Called by the transport layer for every byte actually sent.
  void reportBytes(int n) {
    _bytesUsed += n;
    notifyListeners();
  }

  void reset() {
    _bytesUsed = 0;
    _sessionStart = null;
    notifyListeners();
  }
}
