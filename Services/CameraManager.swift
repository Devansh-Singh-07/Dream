import AVFoundation
import UIKit
import SwiftUI
import Combine  

class CameraManager: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    @Published var capturedImage: UIImage?
    @Published var error: Error?
    
    private let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private var isCapturing = false
    private var isSessionConfigured = false
    
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    // Check camera permission
    func checkPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        print("🔐 Camera permission status: \(status.rawValue)")
        
        switch status {
        case .authorized:
            print("✅ Camera authorized")
            setup()
            checkMicrophonePermission()
        case .notDetermined:
            print("⏳ Camera permission not determined, requesting...")
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                print(granted ? "✅ Permission granted" : "❌ Permission denied")
                if granted {
                    DispatchQueue.main.async {
                        self?.setup()
                        self?.checkMicrophonePermission()
                    }
                }
            }
        default:
            print("❌ Camera permission denied")
            error = CameraError.permissionDenied
            checkMicrophonePermission()
        }
    }
    
    // Check microphone permission immediately after to prevent iOS alert-crashing SwiftUI sheets
    func checkMicrophonePermission() {
        let status = AVAudioApplication.shared.recordPermission
        if status == .undetermined {
            print("⏳ Microphone permission not determined, requesting...")
            AVAudioApplication.requestRecordPermission { granted in
                print(granted ? "✅ Mic Permission granted" : "❌ Mic Permission denied")
            }
        }
    }
    
    // Set up camera session
    private func setup() {
        print("🎥 Camera setup started")
        
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .hd1920x1080
        
        // Get back camera
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("❌ No camera found")
            captureSession.commitConfiguration()
            error = CameraError.noCameraAvailable
            return
        }
        
        print("✅ Camera device found")
        
        do {
            try camera.lockForConfiguration()
            camera.videoZoomFactor = 1.0
            camera.unlockForConfiguration()
            
            let input = try AVCaptureDeviceInput(device: camera)
            
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
                print("✅ Camera input added")
            }
            
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
                if let connection = videoOutput.connection(with: .video) {
                    if connection.isVideoRotationAngleSupported(90) {
                        connection.videoRotationAngle = 90
                    }
                }
                print("✅ Video output added")
            }
            
            // Create preview layer
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer?.videoGravity = .resizeAspectFill

            captureSession.commitConfiguration()
            isSessionConfigured = true

            // Start session on background thread
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.startRunning()
                
                DispatchQueue.main.async {
                    self?.objectWillChange.send()
                }
            }
            
        } catch {
            print("❌ Camera setup error: \(error)")
            self.error = error
        }
    }
    
    // Capture photo silently
    func capturePhoto() {
        isCapturing = true
        
        #if targetEnvironment(simulator)
        // Simulate a camera capture delay and provide a fake image
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            let size = CGSize(width: 400, height: 300)
            let renderer = UIGraphicsImageRenderer(size: size)
            let image = renderer.image { ctx in
                UIColor.systemGray5.setFill()
                ctx.fill(CGRect(origin: .zero, size: size))
                
                let text = "Simulated Capture\n\(Date().formatted(date: .omitted, time: .standard))"
                let style = NSMutableParagraphStyle()
                style.alignment = .center
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                    .foregroundColor: UIColor.systemBlue,
                    .paragraphStyle: style
                ]
                let textSize = text.size(withAttributes: attrs)
                let rect = CGRect(
                    x: (size.width - textSize.width) / 2,
                    y: (size.height - textSize.height) / 2,
                    width: textSize.width,
                    height: textSize.height
                )
                text.draw(in: rect, withAttributes: attrs)
            }
            self?.capturedImage = image
            self?.isCapturing = false
        }
        #endif
    }
    
    func stop() {
        guard isSessionConfigured else { return }
        captureSession.stopRunning()
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard isCapturing else { return }
        isCapturing = false
        
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
        
        let orientation = imageOrientation()
        let uiImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: orientation)
        
        Task { @MainActor [weak self] in
            self?.capturedImage = uiImage
        }
    }
    
    private func imageOrientation() -> UIImage.Orientation {
        // videoRotationAngle = 90 on the connection already corrects the raw
        // Adjust rotation for device orientation
        // from that baseline for landscape / upside-down captures.
        let deviceOrientation = UIDevice.current.orientation
        switch deviceOrientation {
        case .portrait:
            return .up           // frame buffer already upright via videoRotationAngle
        case .landscapeLeft:
            return .left         // device rotated CCW → image needs CW correction
        case .landscapeRight:
            return .right        // device rotated CW → image needs CCW correction
        case .portraitUpsideDown:
            return .down
        default:
            return .up
        }
    }
}

enum CameraError: Error {
    case permissionDenied
    case noCameraAvailable
}
