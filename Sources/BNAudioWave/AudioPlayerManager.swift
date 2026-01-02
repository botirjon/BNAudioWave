//
//  AudioPlayerManager.swift
//  BNAudioWave
//
//  Created by MAC-Nasridinov-B on 02/01/26.
//

import AVFoundation
import Combine

// MARK: - Audio Player State

public enum AudioPlayerState: Equatable {
    case idle
    case loading
    case ready
    case playing
    case paused
    case error(String)
    
    public static func == (lhs: AudioPlayerState, rhs: AudioPlayerState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading), (.ready, .ready),
             (.playing, .playing), (.paused, .paused):
            return true
        case (.error(let a), .error(let b)):
            return a == b
        default:
            return false
        }
    }
}

// MARK: - Audio Player Manager

@MainActor
public final class AudioPlayerManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var state: AudioPlayerState = .idle
    @Published private(set) var currentTime: TimeInterval = 0
    @Published private(set) var duration: TimeInterval = 0
    @Published private(set) var progress: Double = 0
    @Published private(set) var amplitudes: [Float] = []
    @Published private(set) var waveformProgress: Float = 0
    
    // MARK: - Private Properties
    
    private var player: AVAudioPlayer?
    private var displayLink: CADisplayLink?
    private var waveformTask: Task<Void, Never>?
    
    private let barCount: Int
    
    // MARK: - Init
    
    public init(barCount: Int = 60) {
        self.barCount = barCount
    }
    
    // MARK: - Public Methods
    
    public func load(url: URL) async {
        reset()
        state = .loading
        
        // Start waveform generation
        waveformTask = Task {
            await generateWaveform(from: url)
        }
        
        // Load audio player
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            duration = player?.duration ?? 0
            state = .ready
        } catch {
            state = .error(error.localizedDescription)
        }
    }
    
    public func play() {
        guard let player, state == .ready || state == .paused else { return }
        
        player.play()
        state = .playing
        startProgressUpdates()
    }
    
    public func pause() {
        guard let player, state == .playing else { return }
        
        player.pause()
        state = .paused
        stopProgressUpdates()
    }
    
    public func togglePlayPause() {
        if state == .playing {
            pause()
        } else {
            play()
        }
    }
    
    public func seek(toProgress progress: Double) {
        guard let player else { return }
        
        let time = duration * progress
        player.currentTime = time
        currentTime = time
        self.progress = progress
    }
    
    public func seek(toTime time: TimeInterval) {
        guard let player, duration > 0 else { return }
        
        let clampedTime = min(max(time, 0), duration)
        player.currentTime = clampedTime
        currentTime = clampedTime
        progress = clampedTime / duration
    }
    
    public func skipForward(seconds: TimeInterval = 15) {
        seek(toTime: currentTime + seconds)
    }
    
    public func skipBackward(seconds: TimeInterval = 15) {
        seek(toTime: currentTime - seconds)
    }
    
    public func reset() {
        player?.stop()
        player = nil
        stopProgressUpdates()
        waveformTask?.cancel()
        
        state = .idle
        currentTime = 0
        duration = 0
        progress = 0
        amplitudes = []
        waveformProgress = 0
    }
    
    // MARK: - Private Methods
    
    private func generateWaveform(from url: URL) async {
        do {
            for try await update in WaveformGenerator.asyncGenerate(from: url, barCount: barCount) {
                switch update {
                case .loading(let progress):
                    waveformProgress = progress
                case .completed(let amps):
                    amplitudes = amps
                    waveformProgress = 1
                }
            }
        } catch {
            print("Waveform generation failed: \(error)")
            // Generate placeholder amplitudes
            amplitudes = (0..<barCount).map { _ in Float.random(in: 0.2...0.8) }
        }
    }
    
    private func startProgressUpdates() {
        displayLink?.invalidate()
        displayLink = CADisplayLink(target: self, selector: #selector(updateProgress))
        displayLink?.preferredFrameRateRange = CAFrameRateRange(minimum: 15, maximum: 30)
        displayLink?.add(to: .main, forMode: .common)
    }
    
    private func stopProgressUpdates() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc private func updateProgress() {
        guard let player else { return }
        
        currentTime = player.currentTime
        
        if duration > 0 {
            progress = currentTime / duration
        }
        
        // Check if playback finished
        if !player.isPlaying && currentTime >= duration - 0.1 {
            state = .paused
            stopProgressUpdates()
            seek(toProgress: 0)
        }
    }
}

// MARK: - Time Formatting

extension AudioPlayerManager {
    
    var currentTimeFormatted: String {
        formatTime(currentTime)
    }
    
    var durationFormatted: String {
        formatTime(duration)
    }
    
    var remainingTimeFormatted: String {
        formatTime(duration - currentTime)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        guard time.isFinite && time >= 0 else { return "0:00" }
        
        let totalSeconds = Int(time)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        
        return String(format: "%d:%02d", minutes, seconds)
    }
}

