//
//  AudioPreviewPlayer.swift
//  BNAudioWave
//
//  Created by MAC-Nasridinov-B on 02/01/26.
//

import SwiftUI

// MARK: - Audio Preview Player

public struct AudioPreviewPlayer: View {
    @StateObject private var playerManager: AudioPlayerManager
    
    let url: URL
    let style: AudioPreviewStyle
    
    public init(url: URL, style: AudioPreviewStyle = .default) {
        self.url = url
        self.style = style
        self._playerManager = StateObject(wrappedValue: AudioPlayerManager(barCount: style.barCount))
    }
    
    public var body: some View {
        HStack(spacing: style.spacing) {
            playButton
            waveformSection
            timeLabel
        }
        .padding(style.padding)
        .background(style.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: style.cornerRadius))
        .task {
            await playerManager.load(url: url)
        }
        .onDisappear {
            playerManager.reset()
        }
    }
    
    // MARK: - Play Button
    
    @ViewBuilder
    private var playButton: some View {
        Button(action: { playerManager.togglePlayPause() }) {
            ZStack {
                Circle()
                    .fill(style.playButtonColor)
                    .frame(width: style.playButtonSize, height: style.playButtonSize)
                
                if playerManager.state == .loading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: playButtonIcon)
                        .font(.system(size: style.playButtonSize * 0.4, weight: .semibold))
                        .foregroundStyle(.white)
                        .offset(x: playerManager.state == .playing ? 0 : 2)
                }
            }
        }
        .disabled(playerManager.state == .loading || playerManager.state == .idle)
        .buttonStyle(.plain)
    }
    
    private var playButtonIcon: String {
        playerManager.state == .playing ? "pause" : "play.fill"
    }
    
    // MARK: - Waveform Section
    
    @ViewBuilder
    private var waveformSection: some View {
        Group {
            if playerManager.amplitudes.isEmpty {
                WaveformPlaceholder(
                    barCount: style.barCount,
                    color: style.unplayedColor,
                    barWidth: style.barWidth,
                    spacing: style.barSpacing
                )
            } else {
                InteractiveWaveformView(
                    amplitudes: playerManager.amplitudes,
                    progress: .init(
                        get: { playerManager.progress },
                        set: { _ in }
                    ),
                    playedColor: style.playedColor,
                    unplayedColor: style.unplayedColor,
                    onSeek: { progress in
                        playerManager.seek(toProgress: progress)
                    }
                )
            }
        }
        .frame(height: style.waveformHeight)
    }
    
    // MARK: - Time Label
    
    @ViewBuilder
    private var timeLabel: some View {
        Text(playerManager.state == .playing
             ? playerManager.currentTimeFormatted
             : playerManager.durationFormatted)
            .font(style.timeFont)
            .foregroundStyle(style.timeColor)
            .monospacedDigit()
            .frame(minWidth: 40, alignment: .trailing)
    }
}

// MARK: - Preview

#Preview("Default Style") {
    VStack(spacing: 20) {
        // Note: Replace with actual audio file URL for testing
        if let url = Bundle.main.url(forResource: "sample", withExtension: "mp3") {
            AudioPreviewPlayer(url: url)
            AudioPreviewPlayer(url: url, style: .compact)
            AudioPreviewPlayer(url: url, style: .large)
            AudioPreviewPlayer(url: url, style: .whatsApp())
            AudioPreviewPlayer(url: url, style: .telegram())
        } else {
            Text("Add sample.mp3 to preview")
        }
    }
    .padding()
}
