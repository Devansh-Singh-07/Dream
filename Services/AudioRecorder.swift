//
//  AudioRecorder.swift
//  classMotion
//
//  Created by devansh pratap singh on 26/02/26.
//

import Foundation
import AVFoundation
import Combine

@MainActor
final class AudioRecorder: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var isRecording = false
    @Published var hasRecording = false
    @Published var permissionDenied = false
    
    // MARK: - Private Properties
    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL?
    
    // MARK: - Public Setup Method
    func setupRecorder() {
        configureAudioSession()
        
        // iOS 17+ Permission Request
        AVAudioApplication.requestRecordPermission { [weak self] allowed in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if allowed {
                    self.configureRecorder()
                } else {
                    self.permissionDenied = true
                    print("Microphone permission denied")
                }
            }
        }
    }
    
    // MARK: - Audio Session Configuration
    private func configureAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
    
    // MARK: - Recorder Configuration
    private func configureRecorder() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory,
                                                     in: .userDomainMask)[0]
        
        recordingURL = documentsPath.appendingPathComponent(
            "narration_\(UUID().uuidString).m4a"
        )
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        guard let url = recordingURL else { return }
        
        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.prepareToRecord()
        } catch {
            print("Failed to create recorder: \(error)")
        }
    }
    
    // MARK: - Recording Controls
    func startRecording() {
        guard let recorder = audioRecorder else {
            print("Recorder not configured")
            return
        }
        
        if recorder.record() {
            isRecording = true
            hasRecording = false
        }
    }
    
    func stopRecording() {
        guard let recorder = audioRecorder else { return }
        
        recorder.stop()
        isRecording = false
    }
    
    // MARK: - Get Recorded Data
    func getRecordingData() -> Data? {
        guard let url = recordingURL else { return nil }
        return try? Data(contentsOf: url)
    }
    
    // MARK: - Cleanup
    func cleanup() {
        audioRecorder?.stop()
        isRecording = false
        
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
        }
        
        audioRecorder = nil
        recordingURL = nil
        hasRecording = false
    }
}

// MARK: - AVAudioRecorderDelegate
extension AudioRecorder: AVAudioRecorderDelegate {
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder,
                                                     successfully flag: Bool) {
        Task { @MainActor in
            self.hasRecording = flag
        }
    }
}
