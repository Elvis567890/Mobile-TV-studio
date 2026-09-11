import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as ws_status;

enum SignalingType { offer, answer, candidate, peerLeft, join, leave }

class SignalingMessage {
  final SignalingType type;
  final String room;
  final String from;
  final String sdp;
  final String mid;
  final int mline;

  SignalingMessage({
    required this.type,
    required this.room,
    required this.from,
    this.sdp = '',
    this.mid = '',
    this.mline = 0,
  });

  factory SignalingMessage.offer({
    required String room,
    required String from,
    required String sdp,
  }) =>
      SignalingMessage(
        type: SignalingType.offer,
        room: room,
        from: from,
        sdp: sdp,
      );

  factory SignalingMessage.answer({
    required String room,
    required String from,
    required String sdp,
  }) =>
      SignalingMessage(
        type: SignalingType.answer,
        room: room,
        from: from,
        sdp: sdp,
      );

  factory SignalingMessage.candidate({
    required String room,
    required String from,
    required String sdp,
    required String mid,
    required int mline,
  }) =>
      SignalingMessage(
        type: SignalingType.candidate,
        room: room,
        from: from,
        sdp: sdp,
        mid: mid,
        mline: mline,
      );

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'room': room,
        'from': from,
        'sdp': sdp,
        'mid': mid,
        'mline': mline,
      };

  factory SignalingMessage.fromJson(Map<String, dynamic> j) => SignalingMessage(
        type: SignalingType.values.firstWhere(
          (t) => t.name == j['type'],
          orElse: () => SignalingType.candidate,
        ),
        room: j['room'] ?? '',
        from: j['from'] ?? '',
        sdp: j['sdp'] ?? '',
        mid: j['mid'] ?? '',
        mline: j['mline'] ?? 0,
      );
}

class SignalingClient {
  SignalingClient({
    required this.serverUrl,
    required this.roomId,
    required this.clientId,
  });

  final String serverUrl;
  final String roomId;
  final String clientId;

  WebSocketChannel? _channel;
  final _controller = StreamController<SignalingMessage>.broadcast();
  final _openController = Completer<void>();

  Stream<SignalingMessage> get messages => _controller.stream;
  Future<void> get ready => _openController.future;

  Future<void> connect() async {
    _channel = WebSocketChannel.connect(Uri.parse(serverUrl));
    await _channel!.ready;
    if (!_openController.isCompleted) _openController.complete();

    _channel!.stream.listen(
      (raw) {
        try {
          final j = jsonDecode(raw as String) as Map<String, dynamic>;
          _controller.add(SignalingMessage.fromJson(j));
        } catch (_) {
          // Ignore malformed frames.
        }
      },
      onDone: () {
        _controller.add(SignalingMessage(
          type: SignalingType.peerLeft,
          room: roomId,
          from: '',
        ));
      },
      onError: (_) {},
    );

    send(SignalingMessage(
      type: SignalingType.join,
      room: roomId,
      from: clientId,
    ));
  }

  void send(SignalingMessage msg) {
    _channel?.sink.add(jsonEncode(msg.toJson()));
  }

  Future<void> disconnect() async {
    send(SignalingMessage(
      type: SignalingType.leave,
      room: roomId,
      from: clientId,
    ));
    await _channel?.sink.close(ws_status.normalClosure);
    await _controller.close();
  }
}
