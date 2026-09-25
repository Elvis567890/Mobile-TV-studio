import 'package:rtmp_broadcaster/camera.dart';
import 'package:mic_info/mic_info.dart';

class StreamingService {
  static CameraController? _controller;
  static bool _isStreaming = false;
  static bool _isRecording = false;
  static bool _isMicMuted = false;

  static CameraController? get controller => _controller;
  static bool get isStreaming => _isStreaming;
  static bool get isRecording => _isRecording;
  static bool get isMicMuted => _isMicMuted;

  static Future<CameraController?> initialize({bool front = false}) async {
    final cams = await availableCameras();
    if (cams.isEmpty) return null;
    final lens = front
        ? CameraLensDirection.front
        : CameraLensDirection.back;
    final cam = cams.firstWhere(
      (c) => c.lensDirection == lens,
      orElse: () => cams.first,
    );
    _controller = CameraController(
      cam,
      ResolutionPreset.high,
      enableAudio: true,
    );
    await _controller!.initialize();
    return _controller;
  }

  static Future<List<String>> detectUsbMics() async {
    try {
      final mics = await MicInfo.getWiredMicrophones();
      return mics.map((m) => m.productName).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> startStream({
    required String rtmpUrl,
    required String streamKey,
    int bitrate = 2500 * 1024,
  }) async {
    if (_controller == null) return;
    final url = '$rtmpUrl/$streamKey';
    await _controller!.startVideoStreaming(
      url,
      bitrate: bitrate,
      androidUseOpenGL: false,
    );
    _isStreaming = true;
  }

  static Future<void> stopStream() async {
    if (_controller == null) return;
    await _controller!.stopEverything();
    _isStreaming = false;
  }

  static Future<void> startRecording(String path) async {
    if (_controller == null) return;
    await _controller!.startVideoRecording(path);
    _isRecording = true;
  }

  static Future<void> stopRecording() async {
    if (_controller == null) return;
    await _controller!.stopVideoRecording();
    _isRecording = false;
  }

  static Future<void> switchCamera() async {
    final cams = await availableCameras();
    if (cams.isEmpty) return;
    final current = _controller?.description.lensDirection
        ?? CameraLensDirection.back;
    final target = current == CameraLensDirection.back
        ? CameraLensDirection.front
        : CameraLensDirection.back;
    final cam = cams.firstWhere(
      (c) => c.lensDirection == target,
      orElse: () => cams.first,
    );
    await _controller?.dispose();
    _controller = CameraController(
      cam,
      ResolutionPreset.high,
      enableAudio: !_isMicMuted,
    );
    await _controller!.initialize();
  }

  static Future<void> muteMic(bool muted) async {
    if (_controller == null) return;
    final cam = _controller!.description;
    await _controller!.dispose();
    _controller = CameraController(
      cam,
      ResolutionPreset.high,
      enableAudio: !muted,
    );
    await _controller!.initialize();
    _isMicMuted = muted;
  }

  static Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
    _isStreaming = false;
    _isRecording = false;
    _isMicMuted = false;
  }
}
