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
    private var videoFilter = [String: String]()
    
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
    
    private func appendVideoFilter() {
        let videoFilterOption = "-vf"
        let videoFilterValue = videoFilter.map { key, value in "\(key)=\(value)" }.joined(separator: ",")
        arguments.append(contentsOf: [videoFilterOption, videoFilterValue])
    }
    
    func build() -> [String] {
        appendVideoFilter()
        arguments.append(outputURL.path)
        return arguments
    }
    
    @discardableResult
    func time(start: String? = nil, end: String? = nil) -> Self {
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
    
    @discardableResult
    func videoBitrate() -> Self {
        guard let audioBitrate = FFprobeKit.videoBitrate(media: media) else {
            return self
        }
        arguments.append(contentsOf: ["-b:v", String(audioBitrate)])
        return self
    }
    
    @discardableResult
    func audioBitrate(index: Int = 1) -> Self {
        guard let audioBitrate = FFprobeKit.audioTracks(media: media)[index]?.bitrate else {
            return self
        }
        arguments.append(contentsOf: ["-b:a", String(audioBitrate)])
        return self
    }
    
    @discardableResult
    func videoCodec(codec: VideoCodec) -> Self {
        arguments.append(contentsOf: ["-c:v", codec.rawValue])
        return self
    }
    
    @discardableResult
    func audioCodec(codec: AudioCodec) -> Self {
        arguments.append(contentsOf: ["-c:a", codec.encoder])
        return self
    }
    
    @discardableResult
    func audioTrack(index: Int) -> Self {
        guard index > 0 else {
            arguments.append(contentsOf: ["-an"])
            return self
        }
        let id = index - 1
        arguments.append(contentsOf: ["-map", "0:v:0", "-map", "0:a:\(id)"])
        return self
    }
    
    @discardableResult
    func resolution(_ resolution: MediaResolution?) -> Self {
        guard let resolution = resolution else {
            return self
        }
        videoFilter["scale"] = "\(resolution.width):\(resolution.height)"
        return self
    }
    
    @discardableResult
    func resolution(width: Int, height: Int) -> Self {
        videoFilter["scale"] = "\(width):\(height)"
        return self
    }
    
    @discardableResult
    func frames(count: Int) -> Self {
        arguments.append(contentsOf: ["-vframes", "\(count)"])
        return self
    }
    
    @discardableResult
    func speed(_ scale: Double) -> Self {
        videoFilter["setpts"] = "PTS/\(scale)"
        arguments.append(contentsOf: ["-af", "atempo=\(scale)"])
        return self
    }
    
    @discardableResult
    func framePerSecond(_ fps: String) -> Self {
        arguments.append(contentsOf: ["-r", fps])
        return self
    }
    
    @discardableResult
    func reset() -> Self {
        arguments = [
            "-v",
            "quiet",
            "-nostdin",
            "-y",
            "-i",
            inputURL.path,
        ]
        return self
    }
}
