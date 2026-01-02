//
//  WaveformGenerator.swift
//  BNAudioWave
//
//  Created by MAC-Nasridinov-B on 02/01/26.
//

import AVFoundation
import Accelerate

// MARK: - Waveform Generator

public enum WaveformError: Error {
    case invalidFormat
    case bufferCreationFailed
    case noAudioData
    case fileNotFound
}

public struct WaveformGenerator {
    
    /// Chunk size for streaming (1 second at 44.1kHz)
    private static let chunkSize: AVAudioFrameCount = 44100
    
    /// Generates waveform amplitude data from an audio file
    /// - Parameters:
    ///   - url: Audio file URL
    ///   - barCount: Number of bars to generate
    /// - Returns: Normalized amplitude values (0.0 to 1.0)
    public static func generate(from url: URL, barCount: Int) throws -> [Float] {
        let file = try AVAudioFile(forReading: url)
        
        guard let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: file.fileFormat.sampleRate,
            channels: 1,
            interleaved: false
        ) else {
            throw WaveformError.invalidFormat
        }
        
        let totalFrames = Int(file.length)
        let samplesPerBar = max(totalFrames / barCount, 1)
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: chunkSize) else {
            throw WaveformError.bufferCreationFailed
        }
        
        var peaks = [Float](repeating: 0, count: barCount)
        var framesProcessed = 0
        
        while framesProcessed < totalFrames {
            let framesToRead = min(Int(chunkSize), totalFrames - framesProcessed)
            
            try file.read(into: buffer, frameCount: AVAudioFrameCount(framesToRead))
            
            guard let channelData = buffer.floatChannelData?[0] else {
                throw WaveformError.noAudioData
            }
            
            var offset = 0
            while offset < framesToRead {
                let globalPosition = framesProcessed + offset
                let barIndex = min(globalPosition / samplesPerBar, barCount - 1)
                let nextBarStart = (barIndex + 1) * samplesPerBar
                let samplesToProcess = min(nextBarStart - globalPosition, framesToRead - offset)
                
                var segmentPeak: Float = 0
                vDSP_maxmgv(
                    channelData.advanced(by: offset),
                    1,
                    &segmentPeak,
                    vDSP_Length(samplesToProcess)
                )
                
                peaks[barIndex] = max(peaks[barIndex], segmentPeak)
                offset += samplesToProcess
            }
            
            framesProcessed += framesToRead
        }
        
        return normalize(peaks)
    }
    
    /// Async version with progress updates
    public static func asyncGenerate(
        from url: URL,
        barCount: Int
    ) -> AsyncThrowingStream<WaveformProgress, Error> {
        AsyncThrowingStream { continuation in
            Task.detached {
                do {
                    let file = try AVAudioFile(forReading: url)
                    
                    guard let format = AVAudioFormat(
                        commonFormat: .pcmFormatFloat32,
                        sampleRate: file.fileFormat.sampleRate,
                        channels: 1,
                        interleaved: false
                    ),
                          let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: chunkSize)
                    else {
                        throw WaveformError.invalidFormat
                    }
                    
                    let totalFrames = Int(file.length)
                    let samplesPerBar = max(totalFrames / barCount, 1)
                    var peaks = [Float](repeating: 0, count: barCount)
                    var framesProcessed = 0
                    
                    while framesProcessed < totalFrames {
                        let framesToRead = min(Int(chunkSize), totalFrames - framesProcessed)
                        try file.read(into: buffer, frameCount: AVAudioFrameCount(framesToRead))
                        
                        guard let channelData = buffer.floatChannelData?[0] else {
                            throw WaveformError.noAudioData
                        }
                        
                        var offset = 0
                        while offset < framesToRead {
                            let globalPosition = framesProcessed + offset
                            let barIndex = min(globalPosition / samplesPerBar, barCount - 1)
                            let nextBarStart = (barIndex + 1) * samplesPerBar
                            let count = min(nextBarStart - globalPosition, framesToRead - offset)
                            
                            var peak: Float = 0
                            vDSP_maxmgv(channelData.advanced(by: offset), 1, &peak, vDSP_Length(count))
                            peaks[barIndex] = max(peaks[barIndex], peak)
                            
                            offset += count
                        }
                        
                        framesProcessed += framesToRead
                        
                        let progress = Float(framesProcessed) / Float(totalFrames)
                        continuation.yield(.loading(progress: progress))
                    }
                    
                    continuation.yield(.completed(amplitudes: normalize(peaks)))
                    continuation.finish()
                    
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    private static func normalize(_ peaks: [Float]) -> [Float] {
        guard let maxPeak = peaks.max(), maxPeak > 0 else { return peaks }
        return peaks.map { $0 / maxPeak }
    }
}

// MARK: - Progress Type

public enum WaveformProgress {
    case loading(progress: Float)
    case completed(amplitudes: [Float])
}
