/// Where the relay lives and how WebRTC finds a path between two phones.
///
/// Replace the placeholder values with your own:
///  - SIGNALING_URL: the ws:// or wss:// address of your relay-server
///  - TURN_URL / TURN_USER / TURN_PASS: from your TURN provider
///
/// Free TURN providers to look at:
///  - metered.ca (50 GB/month free)
///  - twilio (paid, reliable)
///  - self-hosted coturn on a VPS
class TurnConfig {
  /// WebSocket signaling server. Points to your relay-server.
  ///
  /// Local dev:   ws://localhost:8080
  /// Production:  wss://relay.yourdomain.com
  static const String signalingUrl = 'wss://relay.example.com';

  /// TURN server for NAT traversal when peer-to-peer fails.
  static const String turnUrl = 'turn:turn.example.com:3478';
  static const String turnUser = 'REPLACE_ME';
  static const String turnPass = 'REPLACE_ME';

  /// Public STUN. Free, no auth. Good enough for most home Wi-Fi.
  static const String stunUrl = 'stun:stun.l.google.com:19302';

  /// Full ICE config passed to createPeerConnection.
  static const Map<String, dynamic> iceConfig = {
    'iceServers': [
      {'urls': stunUrl},
      {
        'urls': turnUrl,
        'username': turnUser,
        'credential': turnPass,
      },
    ],
    'sdpSemantics': 'unified-plan',
    'iceTransportPolicy': 'all',
  };
}
