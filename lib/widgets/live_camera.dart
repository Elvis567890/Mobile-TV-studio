import 'package:rtmp_broadcaster/camera.dart';
import 'package:flutter/material.dart';

class LiveCamera extends StatefulWidget {
  final bool front;
  const LiveCamera({super.key, this.front = false});
  @override
  State<LiveCamera> createState() => _LiveCameraState();
}

class _LiveCameraState extends State<LiveCamera> {
  CameraController? _ctrl;
  bool _ready = false;
  String? _error;
  @override
  void initState() { super.initState(); _init(); }
  Future<void> _init() async {
    try {
      final cams = await availableCameras();
      if (cams.isEmpty) { setState(() => _error = 'No cameras'); return; }
      final lens = widget.front
          ? CameraLensDirection.front : CameraLensDirection.back;
      final cam = cams.firstWhere((c) => c.lensDirection == lens,
          orElse: () => cams.first);
      _ctrl = CameraController(cam, ResolutionPreset.high, enableAudio: true);
      await _ctrl!.initialize();
      if (mounted) setState(() => _ready = true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }
  @override
  void didUpdateWidget(covariant LiveCamera old) {
    super.didUpdateWidget(old);
    if (old.front != widget.front) {
      _ctrl?.dispose(); _ready = false; _init();
    }
  }
  @override
  void dispose() { _ctrl?.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Container(color: Colors.black, child: Center(child: Text(
        _error!,
        style: const TextStyle(color: Colors.redAccent, fontSize: 11))));
    }
    if (!_ready || _ctrl == null) {
      return Container(color: Colors.black, child: const Center(
        child: CircularProgressIndicator(color: Colors.redAccent)));
    }
    final isFront =
        _ctrl!.description.lensDirection == CameraLensDirection.front;
    return RotatedBox(quarterTurns: isFront ? 3 : 1,
        child: CameraPreview(_ctrl!));
  }
}
