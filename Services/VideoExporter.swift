import Foundation
import AVFoundation
import UIKit

class VideoExporter {
    
    enum ExportError: Error {
        case failedToCreateWriter
        case videoInputUnvailable
        case pixelBufferFailed
        case audioMuxFailed
    }
    
    /// Exports the frames and optional audio to an MP4 file in the temporary directory.
    static func exportVideo(frames: [FrameData], audioData: Data?) async throws -> URL {
        guard !frames.isEmpty else { throw ExportError.failedToCreateWriter }
        
        // Step 1: Write a video-only MP4
        let videoOnlyURL = try await writeVideoFrames(frames: frames)
        
        // Step 2: If there's audio data, mux it together with the video
        guard let audioData = audioData, !audioData.isEmpty else {
            return videoOnlyURL
        }
        
        let finalURL = try await muxAudioIntoVideo(videoURL: videoOnlyURL, audioData: audioData)
        
        // Clean up the video-only intermediate file
        try? FileManager.default.removeItem(at: videoOnlyURL)
        
        return finalURL
    }
    
    // MARK: - Step 1: Write Video Frames
    
    private static func writeVideoFrames(frames: [FrameData]) async throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("ClassMotion_VideoOnly_\(UUID().uuidString).mp4")
        if FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)
        }
        
        let firstImage = frames[0].image ?? UIImage()
        let size = firstImage.size
        let width = Int(size.width / 2) * 2
        let height = Int(size.height / 2) * 2
        let videoSize = CGSize(width: width, height: height)
        
        let assetWriter = try AVAssetWriter(outputURL: url, fileType: .mp4)
        
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height
        ]
        
        let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        videoInput.expectsMediaDataInRealTime = false
        
        let sourcePixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB),
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height
        ]
        
        let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: videoInput,
            sourcePixelBufferAttributes: sourcePixelBufferAttributes
        )
        
        guard assetWriter.canAdd(videoInput) else { throw ExportError.videoInputUnvailable }
        assetWriter.add(videoInput)
        
        assetWriter.startWriting()
        assetWriter.startSession(atSourceTime: .zero)
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let videoQueue = DispatchQueue(label: "video.export.queue")
            
            var frameCount = 0
            var currentTime: CMTime = .zero
            
            videoInput.requestMediaDataWhenReady(on: videoQueue) {
                while videoInput.isReadyForMoreMediaData {
                    if frameCount >= frames.count {
                        videoInput.markAsFinished()
                        assetWriter.finishWriting {
                            if assetWriter.status == .completed {
                                continuation.resume()
                            } else {
                                continuation.resume(throwing: assetWriter.error ?? ExportError.failedToCreateWriter)
                            }
                        }
                        break
                    }
                    
                    guard let pixelBufferPool = pixelBufferAdaptor.pixelBufferPool else {
                        continuation.resume(throwing: ExportError.pixelBufferFailed)
                        return
                    }
                    
                    var pixelBuffer: CVPixelBuffer?
                    CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferPool, &pixelBuffer)
                    
                    if let buffer = pixelBuffer, let image = frames[frameCount].image {
                        fillPixelBufferFromImage(image: image, pixelBuffer: buffer, targetSize: videoSize)
                        let success = pixelBufferAdaptor.append(buffer, withPresentationTime: currentTime)
                        if !success { print("Warning: failed to append frame \(frameCount)") }
                    }
                    
                    let duration = CMTime(seconds: frames[frameCount].duration, preferredTimescale: 600)
                    currentTime = CMTimeAdd(currentTime, duration)
                    frameCount += 1
                }
            }
        }
        
        return url
    }
    
    // MARK: - Step 2: Mux Audio into Video
    
    private static func muxAudioIntoVideo(videoURL: URL, audioData: Data) async throws -> URL {
        // Write the raw audio data to a temporary file so AVFoundation can read it
        let audioFileURL = FileManager.default.temporaryDirectory.appendingPathComponent("ClassMotion_Audio_\(UUID().uuidString).m4a")
        try audioData.write(to: audioFileURL)
        
        let videoAsset = AVURLAsset(url: videoURL)
        let audioAsset = AVURLAsset(url: audioFileURL)
        
        let composition = AVMutableComposition()
        
        // Add video track
        guard let videoTrack = try await videoAsset.loadTracks(withMediaType: .video).first,
              let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            throw ExportError.audioMuxFailed
        }
        
        let videoDuration = try await videoAsset.load(.duration)
        try compositionVideoTrack.insertTimeRange(CMTimeRange(start: .zero, duration: videoDuration), of: videoTrack, at: .zero)
        
        // Add audio track (trimmed to video duration if longer)
        if let audioTrack = try? await audioAsset.loadTracks(withMediaType: .audio).first,
           let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
            let audioDuration = try await audioAsset.load(.duration)
            let insertDuration = CMTimeMinimum(audioDuration, videoDuration)
            try compositionAudioTrack.insertTimeRange(CMTimeRange(start: .zero, duration: insertDuration), of: audioTrack, at: .zero)
        }
        
        // Export the muxed composition
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("ClassMotion_Export_\(UUID().uuidString).mp4")
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try? FileManager.default.removeItem(at: outputURL)
        }
        
        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            throw ExportError.audioMuxFailed
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        
        await exportSession.export()
        
        // Clean up temporary audio file
        try? FileManager.default.removeItem(at: audioFileURL)
        
        guard exportSession.status == .completed else {
            throw exportSession.error ?? ExportError.audioMuxFailed
        }
        
        return outputURL
    }
    
    // MARK: - Pixel Buffer Rendering
    
    private static func fillPixelBufferFromImage(image: UIImage, pixelBuffer: CVPixelBuffer, targetSize: CGSize) {
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: pixelData,
            width: Int(targetSize.width),
            height: Int(targetSize.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
            space: rgbColorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        )
        
        let rect = CGRect(origin: .zero, size: targetSize)
        context?.clear(rect)
        context?.setFillColor(UIColor.black.cgColor)
        context?.fill(rect)
        
        if let cgImage = image.cgImage {
            let imageSize = image.size
            let widthRatio = targetSize.width / imageSize.width
            let heightRatio = targetSize.height / imageSize.height
            let factor = min(widthRatio, heightRatio)
            
            let drawWidth = imageSize.width * factor
            let drawHeight = imageSize.height * factor
            let x = (targetSize.width - drawWidth) / 2
            let y = (targetSize.height - drawHeight) / 2
            
            context?.draw(cgImage, in: CGRect(x: x, y: y, width: drawWidth, height: drawHeight))
        }
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
    }
}
