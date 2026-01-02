//
//  AudioPreviewStyle.swift
//  BNAudioWave
//
//  Created by MAC-Nasridinov-B on 02/01/26.
//

import Foundation
import SwiftUI

public struct AudioPreviewStyle : Sendable{
    public var barCount: Int = 50
    public var barWidth: CGFloat = 3
    public var barSpacing: CGFloat = 2
    public var waveformHeight: CGFloat = 36
    public var playButtonSize: CGFloat = 44
    public var spacing: CGFloat = 12
    public var padding: CGFloat = 8
    public var cornerRadius: CGFloat = 24
    
    public var playedColor: Color = .blue
    public var unplayedColor: Color = .gray.opacity(0.4)
    public var playButtonColor: Color = .blue
    public var backgroundColor: Color = Color(.systemGray6)
    public var timeColor: Color = .secondary
    public var timeFont: Font = .caption.monospacedDigit()
    
    public init(
        barCount: Int = 50,
        barWidth: CGFloat = 3,
        barSpacing: CGFloat = 2,
        waveformHeight: CGFloat = 36,
        playButtonSize: CGFloat = 44,
        spacing: CGFloat = 12,
        padding: CGFloat = 8,
        cornerRadius: CGFloat = 24,
        playedColor: Color = .blue,
        unplayedColor: Color = .gray.opacity(0.4),
        playButtonColor: Color = .blue,
        backgroundColor: Color = Color(.systemGray6),
        timeColor: Color = .secondary,
        timeFont: Font = .caption.monospacedDigit()
    ) {
        self.barCount = barCount
        self.barWidth = barWidth
        self.barSpacing = barSpacing
        self.waveformHeight = waveformHeight
        self.playButtonSize = playButtonSize
        self.spacing = spacing
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.playedColor = playedColor
        self.unplayedColor = unplayedColor
        self.playButtonColor = playButtonColor
        self.backgroundColor = backgroundColor
        self.timeColor = timeColor
        self.timeFont = timeFont
    }
    
    public static let `default` = AudioPreviewStyle()
    
    public static let compact = AudioPreviewStyle(
        barCount: 30,
        barWidth: 2,
        barSpacing: 1.5,
        waveformHeight: 28,
        playButtonSize: 36,
        spacing: 8,
        padding: 6,
        cornerRadius: 20
    )
    
    public static let large = AudioPreviewStyle(
        barCount: 80,
        barWidth: 4,
        barSpacing: 2,
        waveformHeight: 56,
        playButtonSize: 56,
        spacing: 16,
        padding: 12,
        cornerRadius: 28
    )
    
    public static let minimal = AudioPreviewStyle(
        barCount: 40,
        barWidth: 2,
        barSpacing: 1,
        waveformHeight: 24,
        playButtonSize: 32,
        spacing: 8,
        padding: 4,
        cornerRadius: 16,
        backgroundColor: .clear
    )
    
    public static func whatsApp() -> AudioPreviewStyle {
        AudioPreviewStyle(
            barCount: 50,
            barWidth: 3,
            barSpacing: 1.5,
            waveformHeight: 32,
            playButtonSize: 40,
            spacing: 10,
            padding: 8,
            cornerRadius: 22,
            playedColor: Color(red: 0.15, green: 0.68, blue: 0.38),
            unplayedColor: Color.gray.opacity(0.4),
            playButtonColor: Color(red: 0.15, green: 0.68, blue: 0.38),
            backgroundColor: Color(red: 0.9, green: 0.95, blue: 0.9)
        )
    }
    
    public static func telegram() -> AudioPreviewStyle {
        AudioPreviewStyle(
            barCount: 60,
            barWidth: 2,
            barSpacing: 1,
            waveformHeight: 28,
            playButtonSize: 40,
            spacing: 12,
            padding: 8,
            cornerRadius: 20,
            playedColor: Color(red: 0.35, green: 0.6, blue: 0.85),
            unplayedColor: Color.gray.opacity(0.35),
            playButtonColor: Color(red: 0.35, green: 0.6, blue: 0.85),
            backgroundColor: Color(red: 0.93, green: 0.95, blue: 0.98)
        )
    }
}
