//
//  WaveformView.swift
//  BNAudioWave
//
//  Created by MAC-Nasridinov-B on 02/01/26.
//

import SwiftUI

// MARK: - Waveform View

public struct WaveformView: View {
    let amplitudes: [Float]
    let progress: Double
    let playedColor: Color
    let unplayedColor: Color
    let barWidth: CGFloat
    let spacing: CGFloat
    let minBarHeight: CGFloat
    
    public init(
        amplitudes: [Float],
        progress: Double,
        playedColor: Color = .blue,
        unplayedColor: Color = .gray.opacity(0.4),
        barWidth: CGFloat = 3,
        spacing: CGFloat = 2,
        minBarHeight: CGFloat = 4
    ) {
        self.amplitudes = amplitudes
        self.progress = progress
        self.playedColor = playedColor
        self.unplayedColor = unplayedColor
        self.barWidth = barWidth
        self.spacing = spacing
        self.minBarHeight = minBarHeight
    }
    
    public var body: some View {
        GeometryReader { geometry in
            HStack(spacing: spacing) {
                ForEach(Array(amplitudes.enumerated()), id: \.offset) { index, amplitude in
                    WaveformBar(
                        amplitude: CGFloat(amplitude),
                        isPlayed: isBarPlayed(index: index),
                        partialFill: partialFillAmount(index: index),
                        playedColor: playedColor,
                        unplayedColor: unplayedColor,
                        minHeight: minBarHeight,
                        maxHeight: geometry.size.height
                    )
                    .frame(width: barWidth)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
    
    private func isBarPlayed(index: Int) -> Bool {
        guard !amplitudes.isEmpty else { return false }
        let barProgress = Double(index) / Double(amplitudes.count)
        return barProgress < progress
    }
    
    private func partialFillAmount(index: Int) -> CGFloat? {
        guard !amplitudes.isEmpty else { return nil }
        let barStart = Double(index) / Double(amplitudes.count)
        let barEnd = Double(index + 1) / Double(amplitudes.count)
        
        if progress > barStart && progress < barEnd {
            return CGFloat((progress - barStart) / (barEnd - barStart))
        }
        return nil
    }
}

// MARK: - Individual Bar

private struct WaveformBar: View {
    let amplitude: CGFloat
    let isPlayed: Bool
    let partialFill: CGFloat?
    let playedColor: Color
    let unplayedColor: Color
    let minHeight: CGFloat
    let maxHeight: CGFloat
    
    private var barHeight: CGFloat {
        max(minHeight, amplitude * maxHeight)
    }
    
    var body: some View {
        if let partial = partialFill {
            // Partially filled bar (current playback position)
            partiallyFilledBar(fill: partial)
        } else {
            // Fully played or unplayed bar
            RoundedRectangle(cornerRadius: 1.5)
                .fill(isPlayed ? playedColor : unplayedColor)
                .frame(height: barHeight)
        }
    }
    
    @ViewBuilder
    private func partiallyFilledBar(fill: CGFloat) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(unplayedColor)
                
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(playedColor)
                    .frame(width: geo.size.width * fill)
            }
        }
        .frame(height: barHeight)
    }
}

// MARK: - Loading Placeholder

struct WaveformPlaceholder: View {
    let barCount: Int
    let color: Color
    let barWidth: CGFloat
    let spacing: CGFloat
    
    @State private var isAnimating = false
    
    init(
        barCount: Int = 50,
        color: Color = .gray.opacity(0.3),
        barWidth: CGFloat = 3,
        spacing: CGFloat = 2
    ) {
        self.barCount = barCount
        self.color = color
        self.barWidth = barWidth
        self.spacing = spacing
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: spacing) {
                ForEach(0..<barCount, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(color)
                        .frame(
                            width: barWidth,
                            height: placeholderHeight(
                                index: index,
                                maxHeight: geometry.size.height
                            )
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .onAppear { isAnimating = true }
    }
    
    private func placeholderHeight(index: Int, maxHeight: CGFloat) -> CGFloat {
        let base = sin(Double(index) * 0.3) * 0.3 + 0.4
        return maxHeight * CGFloat(base)
    }
}

// MARK: - Interactive Waveform

public struct InteractiveWaveformView: View {
    let amplitudes: [Float]
    @Binding var progress: Double
    let playedColor: Color
    let unplayedColor: Color
    let onSeek: ((Double) -> Void)?
    
    @State private var isDragging = false
    
    public init(
        amplitudes: [Float],
        progress: Binding<Double>,
        playedColor: Color = .blue,
        unplayedColor: Color = .gray.opacity(0.4),
        onSeek: ((Double) -> Void)? = nil
    ) {
        self.amplitudes = amplitudes
        self._progress = progress
        self.playedColor = playedColor
        self.unplayedColor = unplayedColor
        self.onSeek = onSeek
    }
    
    public var body: some View {
        GeometryReader { geometry in
            WaveformView(
                amplitudes: amplitudes,
                progress: progress,
                playedColor: playedColor,
                unplayedColor: unplayedColor
            )
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isDragging = true
                        let newProgress = min(max(value.location.x / geometry.size.width, 0), 1)
                        progress = newProgress
                    }
                    .onEnded { value in
                        isDragging = false
                        let finalProgress = min(max(value.location.x / geometry.size.width, 0), 1)
                        onSeek?(finalProgress)
                    }
            )
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        // Sample waveform
        WaveformView(
            amplitudes: (0..<60).map { _ in Float.random(in: 0.2...1.0) },
            progress: 0.4
        )
        .frame(height: 50)
        
        // Placeholder
        WaveformPlaceholder()
            .frame(height: 50)
    }
    .padding()
}
