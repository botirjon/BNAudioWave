# BNAudioWave

A powerful SwiftUI audio waveform visualization and player library for iOS, macOS, tvOS, watchOS, and visionOS. Features pre-built styles including Telegram and WhatsApp voice message appearances.

## Features

- **Waveform Generation** - Extract amplitude data from audio files using high-performance DSP
- **Interactive Waveforms** - Tap and drag to seek through audio
- **Complete Audio Player** - Ready-to-use player component with controls
- **Pre-built Styles** - Default, Compact, Large, Minimal, WhatsApp, and Telegram styles
- **Full Customization** - Customize colors, dimensions, and layout
- **Async Support** - Non-blocking waveform generation with progress updates
- **UIKit Compatible** - Easy integration with UIKit via hosting controllers
- **Zero Dependencies** - Uses only Apple frameworks (AVFoundation, Accelerate, SwiftUI)

## Requirements

- iOS 15.0+ / macOS 12.0+ / tvOS 15.0+ / watchOS 8.0+ / visionOS 1.0+
- Swift 6.2+
- Xcode 16.0+

## Installation

### Swift Package Manager

Add BNAudioWave to your project via SPM:

```swift
dependencies: [
    .package(url: "https://github.com/AnotherBrick0/BNAudioWave.git", from: "1.0.0")
]
```

Or in Xcode: **File → Add Package Dependencies** and enter the repository URL.

## Quick Start

```swift
import BNAudioWave
import SwiftUI

struct ContentView: View {
    var body: some View {
        if let url = Bundle.main.url(forResource: "audio", withExtension: "mp3") {
            AudioPreviewPlayer(url: url)
        }
    }
}
```

## Usage

### Pre-built Styles

```swift
// Default style
AudioPreviewPlayer(url: audioURL)

// Compact - ideal for lists
AudioPreviewPlayer(url: audioURL, style: .compact)

// Large - for featured content
AudioPreviewPlayer(url: audioURL, style: .large)

// Minimal - borderless design
AudioPreviewPlayer(url: audioURL, style: .minimal)

// WhatsApp voice message style
AudioPreviewPlayer(url: audioURL, style: .whatsApp())

// Telegram voice message style
AudioPreviewPlayer(url: audioURL, style: .telegram())
```

### Custom Style

```swift
var customStyle: AudioPreviewStyle {
    var style = AudioPreviewStyle()
    style.barCount = 70
    style.barWidth = 2.5
    style.barSpacing = 1.5
    style.waveformHeight = 40
    style.playedColor = .purple
    style.unplayedColor = .purple.opacity(0.3)
    style.playButtonColor = .purple
    style.backgroundColor = Color.purple.opacity(0.1)
    style.cornerRadius = 16
    return style
}

AudioPreviewPlayer(url: audioURL, style: customStyle)
```

### Standalone Waveform View

Use `WaveformView` for read-only display or `InteractiveWaveformView` for seeking:

```swift
struct CustomPlayerView: View {
    @State private var amplitudes: [Float] = []
    @State private var progress: Double = 0

    var body: some View {
        VStack {
            // Read-only waveform
            WaveformView(
                amplitudes: amplitudes,
                progress: progress,
                playedColor: .blue,
                unplayedColor: .gray.opacity(0.3)
            )
            .frame(height: 50)

            // Interactive waveform with seeking
            InteractiveWaveformView(
                amplitudes: amplitudes,
                progress: $progress,
                onSeek: { newProgress in
                    print("Seeked to: \(newProgress)")
                }
            )
            .frame(height: 50)
        }
        .task {
            if let url = Bundle.main.url(forResource: "audio", withExtension: "mp3") {
                amplitudes = try! WaveformGenerator.generate(from: url, barCount: 60)
            }
        }
    }
}
```

### Manual Waveform Generation

```swift
// Synchronous generation
let amplitudes = try WaveformGenerator.generate(from: audioURL, barCount: 50)

// Asynchronous with progress
for try await progress in WaveformGenerator.asyncGenerate(from: audioURL, barCount: 50) {
    switch progress {
    case .loading(let value):
        print("Loading: \(Int(value * 100))%")
    case .completed(let amplitudes):
        print("Generated \(amplitudes.count) bars")
    }
}
```

### Using AudioPlayerManager

For custom player implementations:

```swift
struct CustomPlayer: View {
    @StateObject private var player = AudioPlayerManager(barCount: 60)
    let audioURL: URL

    var body: some View {
        VStack {
            InteractiveWaveformView(
                amplitudes: player.amplitudes,
                progress: Binding(
                    get: { player.progress },
                    set: { player.seek(toProgress: $0) }
                )
            )

            HStack {
                Button(action: { player.skipBackward() }) {
                    Image(systemName: "gobackward.15")
                }

                Button(action: { player.togglePlayPause() }) {
                    Image(systemName: player.state == .playing ? "pause.fill" : "play.fill")
                }

                Button(action: { player.skipForward() }) {
                    Image(systemName: "goforward.15")
                }
            }

            Text("\(player.currentTimeFormatted) / \(player.durationFormatted)")
        }
        .task {
            await player.load(url: audioURL)
        }
    }
}
```

### UIKit Integration

```swift
import UIKit
import SwiftUI
import BNAudioWave

class AudioViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let url = Bundle.main.url(forResource: "audio", withExtension: "mp3") else { return }

        let player = AudioPreviewPlayer(url: url, style: .telegram())
        let hostingController = UIHostingController(rootView: player)

        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            hostingController.view.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        hostingController.didMove(toParent: self)
    }
}
```

## API Reference

### AudioPreviewPlayer

Complete audio player component with waveform and controls.

```swift
init(url: URL, style: AudioPreviewStyle = .default)
```

### AudioPreviewStyle

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `barCount` | `Int` | `50` | Number of waveform bars |
| `barWidth` | `CGFloat` | `3` | Width of each bar |
| `barSpacing` | `CGFloat` | `2` | Space between bars |
| `waveformHeight` | `CGFloat` | `36` | Height of waveform |
| `playButtonSize` | `CGFloat` | `44` | Play button diameter |
| `spacing` | `CGFloat` | `12` | Spacing between elements |
| `padding` | `CGFloat` | `8` | Internal padding |
| `cornerRadius` | `CGFloat` | `24` | Background corner radius |
| `playedColor` | `Color` | `.blue` | Played portion color |
| `unplayedColor` | `Color` | `.gray.opacity(0.4)` | Unplayed portion color |
| `playButtonColor` | `Color` | `.blue` | Play button color |
| `backgroundColor` | `Color` | `systemGray6` | Background color |
| `timeColor` | `Color` | `.secondary` | Time label color |
| `timeFont` | `Font` | `.caption.monospacedDigit()` | Time label font |

### AudioPlayerManager

| Property | Type | Description |
|----------|------|-------------|
| `state` | `AudioPlayerState` | Current player state |
| `currentTime` | `TimeInterval` | Current playback time |
| `duration` | `TimeInterval` | Total audio duration |
| `progress` | `Double` | Playback progress (0-1) |
| `amplitudes` | `[Float]` | Generated waveform data |

| Method | Description |
|--------|-------------|
| `load(url:)` | Load audio file asynchronously |
| `play()` | Start playback |
| `pause()` | Pause playback |
| `togglePlayPause()` | Toggle play/pause state |
| `seek(toProgress:)` | Seek to progress (0-1) |
| `seek(toTime:)` | Seek to time in seconds |
| `skipForward(seconds:)` | Skip forward (default 15s) |
| `skipBackward(seconds:)` | Skip backward (default 15s) |
| `reset()` | Reset player state |

### WaveformGenerator

| Method | Description |
|--------|-------------|
| `generate(from:barCount:)` | Synchronous waveform generation |
| `asyncGenerate(from:barCount:)` | Async generation with progress |

### AudioPlayerState

```swift
enum AudioPlayerState {
    case idle       // Initial state
    case loading    // Loading audio file
    case ready      // Ready to play
    case playing    // Currently playing
    case paused     // Paused
    case error(String)  // Error occurred
}
```

## Style Presets Comparison

| Style | Bar Count | Height | Best For |
|-------|-----------|--------|----------|
| Default | 50 | 36pt | General purpose |
| Compact | 30 | 28pt | Lists, table cells |
| Large | 80 | 56pt | Featured content |
| Minimal | 40 | 24pt | Clean, borderless UI |
| WhatsApp | 50 | 32pt | Chat bubbles |
| Telegram | 60 | 28pt | Voice messages |

## License

MIT License. See [LICENSE](LICENSE) for details.

## Author

Created by AnotherBrick0
