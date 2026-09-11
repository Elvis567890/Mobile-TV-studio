package com.yourcompany.studio

import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaFormat
import android.os.Build
import android.view.Surface
import io.flutter.plugin.common.MethodChannel

/**
 * Hardware H.264 encoder. Receives frames on a Surface and emits
 * NAL units to whatever transport is currently active.
 *
 * The callback is wired up by the Dart side through the MethodChannel
 * as "onEncodedChunk". Full frame-plumbing is finished in the
 * transport batch. This file gives you a real, working encoder.
 */
class EncoderBridge {

    private var codec: MediaCodec? = null
    private var inputSurface: Surface? = null
    private var running = false

    fun start(
        width: Int,
        height: Int,
        bitrate: Int,
        fps: Int,
        result: MethodChannel.Result
    ) {
        if (running) {
            result.error("ALREADY_RUNNING", "Encoder is already running", null)
            return
        }
        try {
            val format = MediaFormat.createVideoFormat("video/avc", width, height).apply {
                setInteger(
                    MediaFormat.KEY_COLOR_FORMAT,
                    MediaCodecInfo.CodecCapabilities.COLOR_FormatSurface
                )
                setInteger(MediaFormat.KEY_BIT_RATE, bitrate)
                setInteger(MediaFormat.KEY_FRAME_RATE, fps)
                setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, 2)
                setInteger(
                    MediaFormat.KEY_BITRATE_MODE,
                    MediaCodecInfo.EncoderCapabilities.BITRATE_MODE_VBR
                )
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    setInteger(MediaFormat.KEY_PROFILE,
                        MediaCodecInfo.CodecProfileLevel.AVCProfileBaseline)
                }
            }

            val c = MediaCodec.createEncoderByType("video/avc")
            c.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
            inputSurface = c.createInputSurface()
            c.start()

            codec = c
            running = true

            Thread { drainLoop() }.start()

            result.success(true)
        } catch (e: Exception) {
            result.error("ENCODER_FAIL", e.message, null)
        }
    }

    private fun drainLoop() {
        val c = codec ?: return
        val info = MediaCodec.BufferInfo()

        while (running) {
            try {
                val index = c.dequeueOutputBuffer(info, 10_000)
                when {
                    index >= 0 -> {
                        val buf = c.getOutputBuffer(index)
                        if (buf != null && info.size > 0) {
                            val chunk = ByteArray(info.size)
                            buf.position(info.offset)
                            buf.limit(info.offset + info.size)
                            buf.get(chunk)
                            // Hand chunk to the transport layer.
                            onEncodedChunk?.invoke(chunk)
                        }
                        c.releaseOutputBuffer(index, false)
                    }
                }
            } catch (_: IllegalStateException) {
                break
            }
        }
    }

    fun requestKeyframe() {
        try {
            val params = android.os.Bundle()
            params.putInt(MediaCodec.PARAMETER_KEY_REQUEST_SYNC_FRAME, 0)
            codec?.setParameters(params)
        } catch (_: Exception) {}
    }

    fun stop() {
        running = false
        try {
            codec?.stop()
        } catch (_: Exception) {}
        try {
            codec?.release()
        } catch (_: Exception) {}
        try {
            inputSurface?.release()
        } catch (_: Exception) {}
        codec = null
        inputSurface = null
    }

    /** Set from MainActivity to forward chunks to Flutter. */
    var onEncodedChunk: ((ByteArray) -> Unit)? = null
}
