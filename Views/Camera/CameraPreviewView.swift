import SwiftUI
import AVFoundation

struct CameraPreviewView: UIViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer
    
    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.backgroundColor = .black
        view.previewLayer = previewLayer
        return view
    }
    
    func updateUIView(_ uiView: PreviewUIView, context: Context) {
        // Frame will be set in layoutSubviews
    }
}

class PreviewUIView: UIView {
    var previewLayer: AVCaptureVideoPreviewLayer? {
        didSet {
            if let layer = previewLayer {
                layer.videoGravity = .resizeAspectFill
                self.layer.insertSublayer(layer, at: 0)
                updateOrientation()
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
        updateOrientation()
    }
    
    private func updateOrientation() {
        guard let connection = previewLayer?.connection, connection.isVideoRotationAngleSupported(90) else { return }
        
        // Find the active window scene to get current interface orientation
        guard let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else { return }
        
        let interfaceOrientation = windowScene.interfaceOrientation
        
        switch interfaceOrientation {
        case .portrait:
            connection.videoRotationAngle = 90
        case .landscapeLeft: // home button on left, camera on right
            connection.videoRotationAngle = 180
        case .landscapeRight: // home button on right, camera on left
            connection.videoRotationAngle = 0
        case .portraitUpsideDown:
            connection.videoRotationAngle = 270
        default:
            connection.videoRotationAngle = 90
        }
    }
}
