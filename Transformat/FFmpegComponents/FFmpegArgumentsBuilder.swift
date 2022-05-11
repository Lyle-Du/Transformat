//
//  FFmpegArgumentsBuilder.swift
//  Transformat
//
//  Created by QIU DU on 11/5/22.
//

import ffmpegkit
import VLCKit

final class FFmpegArgumentsBuilder {
    
    private var arguments = [String]()
    
    private let media: VLCMedia
    private let inputURL: URL
    private let outputURL: URL
    
    init?(media: VLCMedia, outputURL: URL) {
        guard let inputURL = media.url else {
            return nil
        }
        
        self.media = media
        self.inputURL = inputURL
        self.outputURL = outputURL
    }
    
    func build() -> [String] {
        arguments.append(outputURL.path)
        return arguments
    }
    
    func duration(start: String?, end: String?) -> Self {
        if
            let start = start,
            let inputIndex = arguments.firstIndex(of: "-i")
        {
            arguments.insert(contentsOf: ["-ss", start], at: inputIndex)
        }
        
        if
            let end = end,
            let inputIndex = arguments.firstIndex(of: "-i")
        {
            arguments.insert(contentsOf: ["-to", end], at: inputIndex)
        }
        return self
    }
    
    func videoBitrate() -> Self {
        guard let audioBitrate = FFprobeKit.videoBitrate(media: media) else {
            return self
        }
        arguments.append(contentsOf: ["-b:v", String(audioBitrate)])
        return self
    }
    
    func audioBitrate(index: Int = 1) -> Self {
        guard let audioBitrate = FFprobeKit.audioTracks(media: media)[index]?.bitrate else {
            return self
        }
        arguments.append(contentsOf: ["-b:a", String(audioBitrate)])
        return self
    }
    
    func videoCodec(codec: VideoCodec?) -> Self {
        guard let codec = codec else {
            return self
        }
        arguments.append(contentsOf: ["-c:v", codec.rawValue])
        return self
    }
    
    func audioCodec(codec: AudioCodec?) -> Self {
        guard let codec = codec else {
            return self
        }
        arguments.append(contentsOf: ["-c:a", codec.rawValue])
        return self
    }
    
    func resolution(_ resolution: MediaResolution?) -> Self {
        guard let resolution = resolution else {
            return self
        }
        arguments.append(contentsOf: ["-vf", "scale=\(resolution.width):\(resolution.height)"])
        return self
    }
    
    func reset() -> Self {
        arguments = [
            "-nostdin",
            "-y",
            "-i",
            inputURL.path,
        ]
        return self
    }
}
