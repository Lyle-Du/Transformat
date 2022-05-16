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
    private var complexFilter = [ComplexFilterKey: String]()
    
    private let media: VLCMedia
    private let inputURL: URL
    private let outputURL: URL
    private let format: ContainerFormat?
    private let audioTracks: [AudioTrack]
    
    init?(media: VLCMedia, outputURL: URL, format: ContainerFormat? = nil) {
        guard let inputURL = media.url else {
            return nil
        }
        
        self.media = media
        self.inputURL = inputURL
        self.outputURL = outputURL
        self.format = format
        audioTracks = FFprobeKit.audioTracks(media: media)
    }
    
    private func buildComplexFilter() {
        guard let lastInputIndex = arguments.lastIndex(of: "-i") else { return }
        let joined = complexFilter.sorted(by: { $0.key.rawValue < $1.key.rawValue })
            .map { $0.value }
            .joined(separator: ";")
        let complexFilterValue = joined
        var arguments = [String]()
        arguments.append(contentsOf: [ComplexFilter.option, complexFilterValue])
        arguments.append(contentsOf: ["-map", ComplexFilter.finalVideoTag])
        if format?.hasAudioCodecs == true {
            for id in 0..<audioTracks.count {
                arguments.append(contentsOf: ["-map", ComplexFilter.finalAudioTag(id: id)])
            }
            
            for id in 0..<audioTracks.count {
                arguments.append(contentsOf: ["-map_metadata:s:a:\(id)", "0:s:a:\(id)"])
            }
        }
        
        self.arguments.insert(contentsOf: arguments, at: lastInputIndex + 2)
    }
    
    func build() -> [String] {
        buildComplexFilter()
        arguments.append(contentsOf: ["-map_chapters", "-1"])
        arguments.append(outputURL.path)
        return arguments
    }
    
    @discardableResult
    func videoBitrate() -> Self {
        guard let videoBitrate = FFprobeKit.videoBitrate(media: media) else {
            return self
        }
        arguments.append(contentsOf: ["-b:v", String(videoBitrate)])
        return self
    }

    @discardableResult
    func audioBitrate(index: Int = 1) -> Self {
        guard format?.hasAudioCodecs == true else { return self }
        guard let audioBitrate = FFprobeKit.audioTracks(media: media).first(where: { $0.index == index })?.bitrate else {
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
        guard format?.hasAudioCodecs == true else { return self }
        arguments.append(contentsOf: ["-c:a", codec.encoder])
        return self
    }

    @discardableResult
    func resolution(_ resolution: MediaResolution?) -> Self {
        guard let resolution = resolution else {
            return self
        }
        complexFilter[.scale] = "\(ComplexFilter.finalVideoTag)\(ComplexFilterKey.scale.title)=\(resolution.width):\(resolution.height)\(ComplexFilter.finalVideoTag)"
        return self
    }

    @discardableResult
    func resolution(width: Int, height: Int) -> Self {
        complexFilter[.scale] = "\(ComplexFilter.finalVideoTag)\(ComplexFilterKey.scale.title)=\(width):\(height)\(ComplexFilter.finalVideoTag)"
        return self
    }

    @discardableResult
    func frame(at time: TimeInterval, width: Int, height: Int) -> [String] {
        var arguments = Constants.initialArguments
        arguments.append(contentsOf: ["-ss", String(time)])
        arguments.append(contentsOf: ["-i", inputURL.path])
        arguments.append(contentsOf: ["-vf", "scale=\(String(width)):\(String(height))"])
        arguments.append(contentsOf: ["-vframes", "1"])
        arguments.append(outputURL.path)
        return arguments
    }

    @discardableResult
    func speed(_ scale: Double) -> Self {
        complexFilter[ComplexFilterKey.setpts] = "\(ComplexFilter.finalVideoTag)\(ComplexFilterKey.setpts.title)=PTS/\(scale)\(ComplexFilter.finalVideoTag)"
        if format?.hasAudioCodecs == true {
            var values = [String]()
            for id in 0..<audioTracks.count {
                let tag = ComplexFilter.finalAudioTag(id: id)
                values.append("\(tag)\(ComplexFilterKey.atempo.title)=\(scale)\(tag)")
            }
            
            let joined = values.joined(separator: ";")
            
            if !joined.isEmpty {
                complexFilter[ComplexFilterKey.atempo] = joined
            }
        }
        return self
    }
    
    @discardableResult
    func clips(_ clips: [Clip]) -> Self {
        guard !clips.isEmpty else { return self }
        
        let inputsArguments = clips.map { [inputURL] clip -> [String] in
            var arguments = [String]()
            arguments.append("-ss")
            arguments.append(String(clip.start))
            arguments.append("-to")
            arguments.append(String(clip.end))
            arguments.append("-i")
            arguments.append(inputURL.path)
            return arguments
        }
        
        let numberOfInputs = inputsArguments.count
        var concatHeader = ""
        for index in 0..<numberOfInputs {
            concatHeader += "[\(index):v]"
            if format?.hasAudioCodecs == true {
                for id in 0..<audioTracks.count {
                    concatHeader += "[\(index):a:\(id)]"
                }
            }
        }
        concatHeader += ComplexFilterKey.concat.title
        concatHeader += "=n=\(numberOfInputs):v=1"
        if format?.hasAudioCodecs == true {
            concatHeader += ":a=\(audioTracks.count)"
        }
        concatHeader += ComplexFilter.finalVideoTag
        if format?.hasAudioCodecs == true {
            for id in 0..<audioTracks.count {
                concatHeader += ComplexFilter.finalAudioTag(id: id)
            }
        }
        complexFilter[.concat] = concatHeader
        arguments.append(contentsOf: inputsArguments.flatMap { $0 })
        return self
    }
    
    @discardableResult
    func framePerSecond(_ fps: String) -> Self {
        arguments.append(contentsOf: ["-r", fps])
        return self
    }
    
    @discardableResult
    func initArguments() -> Self {
        arguments = Constants.initialArguments
        return self
    }
}

private extension FFmpegArgumentsBuilder {
    
    struct Constants {
        
        #if DEBUG
        static let initialArguments = [
            "-nostdin",
            "-y",
        ]
        #else
        static let initialArguments = [
            "-v",
            "quiet",
            "-nostdin",
            "-y",
        ]
        #endif
    }
    
    enum ComplexFilterKey: Int {
        
        case concat
        case setpts
        case atempo
        case scale
        
        var title: String {
            switch self {
            case .concat:
                return "concat"
            case .setpts:
                return "setpts"
            case .atempo:
                return "atempo"
            case .scale:
                return "scale"
            }
        }
    }
    
    struct ComplexFilter {
        static let option = "-filter_complex"
        static let finalVideoTag = "[finalVideo]"
        static func finalAudioTag(id: Int) -> String { return "[finalAudio\(id)]" }
    }
}
