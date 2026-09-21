

### This fork includes the Xcode 27 build and Swift 6 concurrency fixes.

![SwiftLAME GH Banner](https://github.com/hidden-spectrum/SwiftLAME/assets/469799/a65a5d73-61fb-4ef8-9b7a-7e8a29446d73)

SwiftLAME is a lightweight Swift wrapper around the [open-source LAME project](https://lame.sourceforge.io) for encoding audio files to MP3 format. This project was created to support the MP3 conversion feature of our [Producer Toolkit macOS App](https://hiddenspectrum.io/producer-toolkit).

## Requirements
SwiftLAME requires Swift 6.2 or newer and supports macOS 12+ and iOS 15+.

## Installation
Add the dependency to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/Tappz-GmbH/SwiftLAME.git", branch: "develop"),
]
```

## Usage

```swift
import Foundation
import SwiftLAME

let progress = Progress()
let lameEncoder = try SwiftLameEncoder(
    sourceUrl: URL(fileURLWithPath: "/path/to/source/file.wav"),
    configuration: .init(
        sampleRate: .custom(44100),
        bitrateMode: .constant(320),
        quality: .best
    ),
    destinationUrl: URL(fileURLWithPath: "/path/to/destination/file.mp3"),
    progress: progress // optional
)
try await lameEncoder.encode(priority: .userInitiated)
```

The source file must remain available until encoding finishes. Use a separate encoder, destination URL, and `Progress` instance for each concurrent conversion.

## Source Codec Support
SwiftLAME supports converting from the following codecs:
- WAV
- AIFF
- Raw PCM


## Notes
- SwiftLAME is still in early alpha. There may be bugs or missing features.

## License
SwiftLAME, like the [LAME project](https://lame.sourceforge.io/license.txt), is distributed under the LGPL License.
