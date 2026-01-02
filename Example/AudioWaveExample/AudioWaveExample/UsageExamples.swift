//
//  UsageExamples.swift
//  AudioWaveExample
//
//  Created by MAC-Nasridinov-B on 02/01/26.
//

import SwiftUI
import UIKit
import BNAudioWave

// MARK: - Usage Examples

/// Basic usage in SwiftUI
struct BasicUsageExample: View {
    var body: some View {
        VStack(spacing: 24) {
            // Simple usage with default style
            if let url = Bundle.main.url(forResource: "voice_message", withExtension: "m4a") {
                AudioPreviewPlayer(url: url)
            }
            
            // With custom style
            if let url = Bundle.main.url(forResource: "podcast", withExtension: "mp3") {
                AudioPreviewPlayer(url: url, style: .large)
            }
        }
        .padding()
    }
}

/// Chat message bubble with audio
struct AudioMessageBubble: View {
    let audioURL: URL
    let timestamp: String
    let isOutgoing: Bool
    
    var body: some View {
        HStack {
            if isOutgoing { Spacer(minLength: 60) }
            
            VStack(alignment: .trailing, spacing: 4) {
                AudioPreviewPlayer(
                    url: audioURL,
                    style: isOutgoing ? outgoingStyle : incomingStyle
                )
                .frame(width: 240)
                
                Text(timestamp)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            if !isOutgoing { Spacer(minLength: 60) }
        }
    }
    
    private var outgoingStyle: AudioPreviewStyle {
        var style = AudioPreviewStyle.whatsApp()
        style.backgroundColor = Color(red: 0.85, green: 0.95, blue: 0.85)
        return style
    }
    
    private var incomingStyle: AudioPreviewStyle {
        var style = AudioPreviewStyle()
        style.backgroundColor = .white
        return style
    }
}

/// Voice message list
struct VoiceMessageList: View {
    struct VoiceMessage: Identifiable {
        let id = UUID()
        let url: URL
        let senderName: String
        let timestamp: Date
    }
    
    let messages: [VoiceMessage]
    
    var body: some View {
        List(messages) { message in
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(message.senderName)
                        .font(.subheadline.bold())
                    Spacer()
                    Text(message.timestamp, style: .time)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                AudioPreviewPlayer(url: message.url, style: .compact)
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Custom Style Example

struct CustomStyledPlayer: View {
    let url: URL
    
    var body: some View {
        AudioPreviewPlayer(url: url, style: customStyle)
    }
    
    private var customStyle: AudioPreviewStyle {
        var style = AudioPreviewStyle()
        style.barCount = 70
        style.barWidth = 2.5
        style.barSpacing = 1.5
        style.waveformHeight = 44
        style.playButtonSize = 48
        style.cornerRadius = 16
        
        // Custom colors
        style.playedColor = .purple
        style.unplayedColor = .purple.opacity(0.25)
        style.playButtonColor = .purple
        style.backgroundColor = Color.purple.opacity(0.1)
        
        return style
    }
}

// MARK: - UIKit Integration

/// UIKit wrapper for AudioPreviewPlayer
final class AudioPreviewPlayerView: UIView {
    
    private var hostingController: UIHostingController<AudioPreviewPlayer>?
    
    var url: URL? {
        didSet {
            updateContent()
        }
    }
    
    var style: AudioPreviewStyle = .default {
        didSet {
            updateContent()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = .clear
    }
    
    private func updateContent() {
        hostingController?.view.removeFromSuperview()
        hostingController = nil
        
        guard let url else { return }
        
        let player = AudioPreviewPlayer(url: url, style: style)
        let hosting = UIHostingController(rootView: player)
        hosting.view.backgroundColor = .clear
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(hosting.view)
        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: topAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: trailingAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        hostingController = hosting
    }
    
    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: style.waveformHeight + style.padding * 2)
    }
}

// MARK: - UIKit Usage Example

final class AudioMessageCell: UITableViewCell {
    
    static let reuseIdentifier = "AudioMessageCell"
    
    private let audioPlayerView = AudioPreviewPlayerView()
    private let timestampLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        selectionStyle = .none
        
        audioPlayerView.translatesAutoresizingMaskIntoConstraints = false
        timestampLabel.translatesAutoresizingMaskIntoConstraints = false
        timestampLabel.font = .preferredFont(forTextStyle: .caption2)
        timestampLabel.textColor = .secondaryLabel
        
        contentView.addSubview(audioPlayerView)
        contentView.addSubview(timestampLabel)
        
        NSLayoutConstraint.activate([
            audioPlayerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            audioPlayerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            audioPlayerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            timestampLabel.topAnchor.constraint(equalTo: audioPlayerView.bottomAnchor, constant: 4),
            timestampLabel.trailingAnchor.constraint(equalTo: audioPlayerView.trailingAnchor),
            timestampLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
    func configure(with url: URL, timestamp: String) {
        audioPlayerView.url = url
        audioPlayerView.style = .compact
        timestampLabel.text = timestamp
    }
}

// MARK: - Standalone Waveform Usage

/// If you only need the waveform without the player
struct StandaloneWaveformExample: View {
    @State private var amplitudes: [Float] = []
    @State private var progress: Double = 0.5
    
    let audioURL: URL
    
    var body: some View {
        VStack {
            // Read-only waveform
            WaveformView(
                amplitudes: amplitudes,
                progress: progress,
                playedColor: .green,
                unplayedColor: .green.opacity(0.3)
            )
            .frame(height: 60)
            
            // Interactive waveform with seeking
            InteractiveWaveformView(
                amplitudes: amplitudes,
                progress: $progress,
                playedColor: .orange,
                unplayedColor: .orange.opacity(0.3),
                onSeek: { newProgress in
                    print("Seeked to: \(newProgress)")
                }
            )
            .frame(height: 60)
            
            Slider(value: $progress)
        }
        .padding()
        .task {
            await loadWaveform()
        }
    }
    
    private func loadWaveform() async {
        do {
            let amps = try WaveformGenerator.generate(from: audioURL, barCount: 80)
            amplitudes = amps
        } catch {
            print("Failed to load waveform: \(error)")
        }
    }
}
