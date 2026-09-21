import AVFAudio
import Foundation
import SwiftLAME
import Testing

struct SwiftLameEncoderRegressionTests {
    @Test("Encodes stereo audio across multiple buffers", arguments: [
        LameBitrateMode.constant(128),
        .variable(.default)
    ])
    func encodesMultipleBuffers(bitrateMode: LameBitrateMode) async throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let source = directory.appendingPathComponent("source.wav")
        let destination = directory.appendingPathComponent("encoded.mp3")
        try writeStereoAudio(to: source)
        let progress = Progress()
        let encoder = try SwiftLameEncoder(
            sourceUrl: source,
            configuration: LameConfiguration(bitrateMode: bitrateMode),
            destinationUrl: destination,
            progress: progress
        )

        try await encoder.encode()

        let decodedFile = try AVAudioFile(forReading: destination)
        let format = decodedFile.processingFormat
        try #require(format.channelCount == 2)
        #expect(format.sampleRate == 44_100)
        let buffer = try #require(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 4_096))
        var decodedFrameCount: AVAudioFramePosition = 0
        var channelPeaks: [Float] = [0, 0]
        while decodedFile.framePosition < decodedFile.length {
            try decodedFile.read(into: buffer)
            try #require(buffer.frameLength > 0)
            decodedFrameCount += AVAudioFramePosition(buffer.frameLength)
            let channels = try #require(buffer.floatChannelData)
            for channel in 0..<2 {
                for frame in 0..<Int(buffer.frameLength) {
                    channelPeaks[channel] = max(channelPeaks[channel], abs(channels[channel][frame]))
                }
            }
        }

        #expect(decodedFrameCount >= 20_000)
        #expect(channelPeaks[0] > 0.01)
        #expect(channelPeaks[1] > 0.01)
        #expect(progress.totalUnitCount == 20_000)
        #expect(progress.completedUnitCount == 20_000)
        #expect(progress.fractionCompleted == 1)
    }

    @Test("Encoding throws when the source disappears after initialization")
    func removedSourceThrowsDuringEncoding() async throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let source = directory.appendingPathComponent("source.wav")
        let destination = directory.appendingPathComponent("encoded.mp3")
        try writeStereoAudio(to: source)
        let encoder = try SwiftLameEncoder(
            sourceUrl: source,
            configuration: LameConfiguration(bitrateMode: .constant(128)),
            destinationUrl: destination
        )
        try FileManager.default.removeItem(at: source)

        await #expect(throws: (any Error).self) {
            try await encoder.encode()
        }
        #expect(!FileManager.default.fileExists(atPath: destination.path))
    }

    private func makeTemporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func writeStereoAudio(to url: URL) throws {
        let format = try #require(AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 2))
        // Exercise two full 8,192-frame encoder reads and a final partial read.
        let buffer = try #require(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 20_000))
        buffer.frameLength = 20_000
        let channels = try #require(buffer.floatChannelData)
        for frame in 0..<Int(buffer.frameLength) {
            let time = Double(frame) / format.sampleRate
            channels[0][frame] = Float(sin(time * 2 * .pi * 440) * 0.25)
            channels[1][frame] = Float(sin(time * 2 * .pi * 660) * 0.25)
        }
        var settings = format.settings
        settings[AVLinearPCMIsNonInterleaved] = false
        let file = try AVAudioFile(forWriting: url, settings: settings)
        try file.write(from: buffer)
    }
}
