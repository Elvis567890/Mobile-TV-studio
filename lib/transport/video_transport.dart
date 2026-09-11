/// Every radio path (Wi-Fi, Bluetooth, internet) implements this.
/// The rest of the app talks only to this interface and never
/// cares which radio is currently active.
abstract class VideoTransport {
  /// Human name shown in the UI — "Wi-Fi", "Bluetooth", "Internet".
  String get name;

  /// Practical ceiling for this radio, in kilobits per second.
  int get maxBitrateKbps;

  /// Best resolution this radio can carry.
  TransportQuality get bestQuality;

  /// Open the connection.
  Future<void> start();

  /// Close and release.
  Future<void> stop();

  /// True while video is actually flowing.
  bool get isRunning;

  /// Fired when the connection drops — the selector uses this
  /// to switch to a fallback radio.
  void Function()? onLost;

  /// Fired when the radio is ready and video is flowing.
  void Function()? onReady;
}

/// Quality ladder shared by every transport.
enum TransportQuality {
  low360p,   // ~600 kbps   — Bluetooth
  medium480p, // ~1200 kbps — Internet / metered
  high720p,   // ~2500 kbps — Wi-Fi
  ultra1080p, // ~4500 kbps — Wi-Fi, strong signal only
}

extension TransportQualityX on TransportQuality {
  int get kbps {
    switch (this) {
      case TransportQuality.low360p:
        return 600;
      case TransportQuality.medium480p:
        return 1200;
      case TransportQuality.high720p:
        return 2500;
      case TransportQuality.ultra1080p:
        return 4500;
    }
  }

  String get label {
    switch (this) {
      case TransportQuality.low360p:
        return '360p';
      case TransportQuality.medium480p:
        return '480p';
      case TransportQuality.high720p:
        return '720p';
      case TransportQuality.ultra1080p:
        return '1080p';
    }
  }
}
