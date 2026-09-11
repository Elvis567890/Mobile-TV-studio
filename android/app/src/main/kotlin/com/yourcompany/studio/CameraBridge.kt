package com.yourcompany.studio

import android.content.Context
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.util.Size
import androidx.camera.core.CameraSelector
import androidx.camera.core.Preview
import androidx.camera.core.resolutionselector.ResolutionSelector
import androidx.camera.core.resolutionselector.ResolutionStrategy
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import io.flutter.plugin.common.MethodChannel

/**
 * Wraps CameraX. Lists cameras, opens a preview, closes it.
 * The actual frames are handed to the EncoderBridge when live.
 */
class CameraBridge(private val context: Context) {

    private var provider: ProcessCameraProvider? = null
    private var preview: Preview? = null

    /** Returns a list of cameras: id, name, facing. */
    fun listCameras(): List<Map<String, Any>> {
        val manager = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
        val out = mutableListOf<Map<String, Any>>()
        for (id in manager.cameraIdList) {
            val chars = manager.getCameraCharacteristics(id)
            val facing = chars.get(CameraCharacteristics.LENS_FACING) ?: -1
            out.add(
                mapOf(
                    "id" to id,
                    "name" to "Camera $id",
                    "facing" to if (facing == CameraCharacteristics.LENS_FACING_FRONT) "front" else "rear"
                )
            )
        }
        return out
    }

    fun startPreview(
        cameraId: String,
        width: Int,
        height: Int,
        fps: Int,
        result: MethodChannel.Result
    ) {
        val future = ProcessCameraProvider.getInstance(context)
        future.addListener({
            try {
                val p = future.get()
                provider = p

                val resolution = ResolutionSelector.Builder()
                    .setResolutionStrategy(
                        ResolutionStrategy(
                            Size(width, height),
                            ResolutionStrategy.FALLBACK_RULE_CLOSEST_HIGHER_THEN_LOWER
                        )
                    )
                    .build()

                val prev = Preview.Builder()
                    .setResolutionSelector(resolution)
                    .build()
                preview = prev

                val selector = CameraSelector.Builder()
                    .requireLensFacing(
                        if (cameraId == "front")
                            CameraSelector.LENS_FACING_FRONT
                        else
                            CameraSelector.LENS_FACING_BACK
                    )
                    .build()

                p.unbindAll()
                p.bindToLifecycle(
                    context as LifecycleOwner,
                    selector,
                    prev
                )

                result.success(true)
            } catch (e: Exception) {
                result.error("CAMERA_FAIL", e.message, null)
            }
        }, ContextCompat.getMainExecutor(context))
    }

    fun stopPreview() {
        try {
            provider?.unbindAll()
        } catch (_: Exception) {}
        preview = null
    }
}
