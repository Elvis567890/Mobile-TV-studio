package com.yourcompany.studio

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val channelName = "mobile_tv_studio/native"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "$channelName/camera"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "listCameras" -> result.success(emptyList<Map<String, String>>())
                "startPreview" -> result.success(false)
                "stopPreview" -> result.success(null)
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "$channelName/permissions"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkAll" -> result.success(mapOf(
                    "camera" to true,
                    "microphone" to true,
                    "bluetooth" to true,
                    "notifications" to true
                ))
                "requestAll" -> result.success(null)
                "openAppSettings" -> result.success(null)
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "$channelName/bluetooth"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isSupported" -> result.success(false)
                "pairedDevices" -> result.success(emptyList<Map<String, String>>())
                "connect" -> result.success(false)
                "sendChunk" -> result.success(0)
                "disconnect" -> result.success(null)
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "$channelName/encoder"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> result.success(false)
                "stop" -> result.success(null)
                "requestKeyframe" -> result.success(null)
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "$channelName/audio"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "listInputs" -> result.success(emptyList<Map<String, String>>())
                "setPreferredInput" -> result.success(null)
                "getPreferredInput" -> result.success(null)
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "$channelName/overlay"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "canDrawOverlays" -> result.success(false)
                "requestOverlayPermission" -> result.success(null)
                "showOverlay" -> result.success(false)
                "hideOverlay" -> result.success(null)
                "isOverlayVisible" -> result.success(false)
                "updateOverlaySize" -> result.success(null)
                else -> result.notImplemented()
            }
        }
    }
}
