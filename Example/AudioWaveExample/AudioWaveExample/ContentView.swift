//
//  ContentView.swift
//  AudioWaveExample
//
//  Created by MAC-Nasridinov-B on 02/01/26.
//

import SwiftUI
import BNAudioWave

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
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
}

#Preview {
    ContentView()
}
