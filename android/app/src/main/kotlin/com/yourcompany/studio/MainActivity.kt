package com.yourcompany.studio

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val channelName = "mobile_tv_studio/native"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val camera = CameraBridge(this)
        val bluetooth = BluetoothBridge(this)
        val encoder = EncoderBridge()

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "$channelName/camera"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "listCameras" -> result.success(camera.listCameras())
                "startPreview" -> {
                    val cameraId = call.argument<String>("cameraId") ?: "0"
                    val width = call.argument<Int>("width") ?: 1280
                    val height = call.argument<Int>("height") ?: 720
                    val fps = call.argument<Int>("fps") ?: 30
                    camera.startPreview(cameraId, width, height, fps, result)
                }
                "stopPreview" -> {
                    camera.stopPreview()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "$channelName/bluetooth"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isSupported" -> result.success(bluetooth.isSupported())
                "pairedDevices" -> result.success(bluetooth.pairedDevices())
                "connect" -> {
                    val mac = call.argument<String>("mac")
                    if (mac == null) {
                        result.error("BAD_ARGS", "mac is required", null)
                    } else {
                        bluetooth.connect(mac, result)
                    }
                }
                "sendChunk" -> {
                    val data = call.argument<ByteArray>("data")
                    if (data == null) {
                        result.error("BAD_ARGS", "data is required", null)
                    } else {
                        bluetooth.sendChunk(data, result)
                    }
                }
                "disconnect" -> {
                    bluetooth.disconnect()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "$channelName/encoder"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    val width = call.argument<Int>("width") ?: 1280
                    val height = call.argument<Int>("height") ?: 720
                    val bitrate = call.argument<Int>("bitrate") ?: 2500000
                    val fps = call.argument<Int>("fps") ?: 30
                    encoder.start(width, height, bitrate, fps, result)
                }
                "stop" -> {
                    encoder.stop()
                    result.success(null)
                }
                "requestKeyframe" -> {
                    encoder.requestKeyframe()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
