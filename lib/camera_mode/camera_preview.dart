import 'package:flutter/material.dart';

class NativeCamera {
  static Future<List<Map<String, String>>> listCameras() async => [];
  static Future<bool> startPreview({
    required String cameraId,
    int width = 1280,
    int height = 720,
    int fps = 30,
  }) async => false;
  static Future<void> stopPreview() async {}
}

class CameraPreview extends StatefulWidget {
  final String cameraId;
  final int width;
  final int height;
  final int fps;
  final bool active;

  const CameraPreview({
    super.key,
    required this.cameraId,
    this.width = 1280,
    this.height = 720,
    this.fps = 30,
    this.active = true,
  });

  @override
  State<CameraPreview> createState() => _CameraPreviewState();
}

class _CameraPreviewState extends State<CameraPreview> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Text(
          'CAMERA PREVIEW',
          style: TextStyle(
            color: Colors.white24,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
          ),
        ),
      ),
    );
  }
}
