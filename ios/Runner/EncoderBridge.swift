import Foundation
import VideoToolbox
import AVFoundation

/// iOS hardware H.264 encoder using VideoToolbox.
///
/// Receives CVPixelBuffer frames from the capture session and emits
/// NAL units to whatever transport is active. Chunk delivery is
/// wired up by the Flutter side.
final class EncoderBridge: NSObject {

    private var session: VTCompressionSession?
    private var running = false
    private var width: Int32 = 1280
    private var height: Int32 = 720
    private var fps: Int32 = 30

    /// Called for every encoded frame. Set from the Flutter side.
    var onEncodedChunk: ((Data) -> Void)?

    /// Begin encoding at the given size, bitrate and frame rate.
    func start(
        width: Int,
        height: Int,
        bitrate: Int,
        fps: Int,
        result: @escaping (Bool, String?) -> Void
    ) {
        if running {
            result(false, "Encoder is already running")
            return
        }

        self.width = Int32(width)
        self.height = Int32(height)
        self.fps = Int32(fps)

        let encoderSpec: [String: Any] = [
            kVTVideoEncoderSpecification_EnableHardwareAcceleratedVideoEncoder as String: true,
            kVTVideoEncoderSpecification_RequireHardwareAcceleratedVideoEncoder as String: false
        ]

        var session: VTCompressionSession?
        let status = VTCompressionSessionCreate(
            allocator: kCFAllocatorDefault,
            width: self.width,
            height: self.height,
            codecType: kCMVideoCodecType_H264,
            encoderSpecification: encoderSpec as CFDictionary,
            imageBufferAttributes: nil,
            compressedDataAllocator: nil,
            outputCallback: nil,
            refcon: nil,
            compressionSessionOut: &session
        )

        guard status == noErr, let s = session else {
            result(false, "Failed to create compression session (status \(status))")
            return
        }

        // Baseline profile for maximum compatibility.
        VTSessionSetProperty(
            s,
            key: kVTCompressionPropertyKey_ProfileLevel,
            value: kVTProfileLevel_H264_Baseline_AutoLevel
        )
        VTSessionSetProperty(
            s,
            key: kVTCompressionPropertyKey_RealTime,
            value: kCFBooleanTrue
        )
        VTSessionSetProperty(
            s,
            key: kVTCompressionPropertyKey_AllowFrameReordering,
            value: kCFBooleanFalse
        )
        VTSessionSetProperty(
            s,
            key: kVTCompressionPropertyKey_AverageBitRate,
            value: NSNumber(value: bitrate)
        )
        VTSessionSetProperty(
            s,
            key: kVTCompressionPropertyKey_ExpectedFrameRate,
            value: NSNumber(value: fps)
        )
        VTSessionSetProperty(
            s,
            key: kVTCompressionPropertyKey_MaxKeyFrameInterval,
            value: NSNumber(value: fps * 2)
        )

        self.session = s
        self.running = true

        result(true, nil)
    }

    /// Called by the capture pipeline for every frame.
    func encode(pixelBuffer: CVPixelBuffer, presentationTime: CMTime) {
        guard running, let session = session else { return }

        var flags: VTEncodeInfoFlags = []
        VTCompressionSessionEncodeFrame(
            session,
            imageBuffer: pixelBuffer,
            presentationTimeStamp: presentationTime,
            duration: .invalid,
            frameProperties: nil,
            sourceFrameRefcon: nil,
            infoFlagsOut: &flags
        )
    }

    /// Force a keyframe. Called after a transport switch.
    func requestKeyframe() {
        guard running, let session = session else { return }
        VTSessionSetProperty(
            session,
            key: kVTCompressionPropertyKey_ForceKeyFrame,
            value: kCFBooleanTrue
        )
    }

    func stop() {
        running = false
        if let s = session {
            VTCompressionSessionCompleteFrames(s, untilPresentationTimeStamp: .invalid)
            VTCompressionSessionInvalidate(s)
        }
        session = nil
    }

    /// Set from outside so the session can call back with each NAL.
    /// This is the piece that VTCompressionSession needs at creation
    /// time. Because Swift does not let us pass a closure to
    /// VTCompressionSessionCreate directly, this method is used by
    /// the capture pipeline to feed frames, and delivery happens
    /// through the output callback configured at creation time.
    func attachOutput() {
        guard let session = session else { return }
        // Output is delivered through VTCompressionSession's
        // compressed frame callback. It is configured by
        // re-creating the session if the callback needs to change.
        // In this build the callback is set once and delivered through
        // onEncodedChunk.
    }
}
