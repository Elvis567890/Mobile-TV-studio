import Foundation
import AVFoundation
import Flutter

/// iOS camera bridge using AVFoundation.
///
/// Notes for iOS:
///  - Background camera is heavily restricted. Foreground only.
///  - Bluetooth video is not possible. Apple blocks RFCOMM.
///  - Everything else (Wi-Fi, internet, RTMP, ads, mixing) works.
final class CameraBridge: NSObject {

    private let session = AVCaptureSession()
    private var currentDevice: AVCaptureDevice?
    private var currentInput: AVCaptureDeviceInput?
    private let sessionQueue = DispatchQueue(label: "camera.session")

    /// List cameras: id, name, facing.
    func listCameras() -> [[String: Any]] {
        var out: [[String: Any]] = []

        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [
                .builtInWideAngleCamera,
                .builtInUltraWideCamera,
                .builtInTelephotoCamera
            ],
            mediaType: .video,
            position: .unspecified
        )

        for device in discovery.devices {
            let facing: String
            switch device.position {
            case .front: facing = "front"
            case .back: facing = "rear"
            default: facing = "unknown"
            }
            out.append([
                "id": device.uniqueID,
                "name": device.localizedName,
                "facing": facing
            ])
        }
        return out
    }

    /// Start a session on the given camera.
    func startPreview(
        cameraId: String,
        width: Int,
        height: Int,
        fps: Int,
        result: @escaping FlutterResult
    ) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            self.session.beginConfiguration()
            self.session.sessionPreset = .high

            // Remove existing input.
            if let input = self.currentInput {
                self.session.removeInput(input)
                self.currentInput = nil
            }

            // Find the requested device.
            let discovery = AVCaptureDevice.DiscoverySession(
                deviceTypes: [
                    .builtInWideAngleCamera,
                    .builtInUltraWideCamera,
                    .builtInTelephotoCamera
                ],
                mediaType: .video,
                position: .unspecified
            )
            let device = discovery.devices.first { $0.uniqueID == cameraId }
                ?? discovery.devices.first

            guard let camera = device else {
                DispatchQueue.main.async {
                    result(FlutterError(
                        code: "NO_CAMERA",
                        message: "No camera available",
                        details: nil
                    ))
                }
                self.session.commitConfiguration()
                return
            }

            do {
                let input = try AVCaptureDeviceInput(device: camera)
                if self.session.canAddInput(input) {
                    self.session.addInput(input)
                    self.currentInput = input
                    self.currentDevice = camera
                }

                // Configure format and frame rate.
                try self.configureFormat(camera: camera, width: width, height: height, fps: fps)

                self.session.commitConfiguration()
                self.session.startRunning()

                DispatchQueue.main.async { result(true) }
            } catch {
                self.session.commitConfiguration()
                DispatchQueue.main.async {
                    result(FlutterError(
                        code: "CAMERA_FAIL",
                        message: error.localizedDescription,
                        details: nil
                    ))
                }
            }
        }
    }

    private func configureFormat(
        camera: AVCaptureDevice,
        width: Int,
        height: Int,
        fps: Int
    ) throws {
        try camera.lockForConfiguration()

        let target = CMVideoDimensions(
            width: Int32(width),
            height: Int32(height)
        )

        var bestFormat: AVCaptureDevice.Format?
        var bestDistance = Int.max

        for format in camera.formats {
            let dims = CMVideoFormatDescriptionGetDimensions(
                format.formatDescription
            )
            let distance = abs(Int(dims.width) - Int(target.width))
                + abs(Int(dims.height) - Int(target.height))
            if distance < bestDistance {
                bestDistance = distance
                bestFormat = format
            }
        }

        if let chosen = bestFormat {
            camera.activeFormat = chosen

            let targetRate = Double(fps)
            var bestRange: AVFrameRateRange?
            var bestRangeDiff = Double.greatestFiniteMagnitude

            for range in chosen.videoSupportedFrameRateRanges {
                let diff = abs(range.maxFrameRate - targetRate)
                if diff < bestRangeDiff {
                    bestRangeDiff = diff
                    bestRange = range
                }
            }

            if let r = bestRange {
                let clamped = min(max(targetRate, r.minFrameRate), r.maxFrameRate)
                camera.activeVideoMinFrameDuration = CMTime(
                    value: 1,
                    timescale: CMTimeScale(clamped)
                )
                camera.activeVideoMaxFrameDuration = CMTime(
                    value: 1,
                    timescale: CMTimeScale(clamped)
                )
            }
        }

        camera.unlockForConfiguration()
    }

    func stopPreview() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }
}
