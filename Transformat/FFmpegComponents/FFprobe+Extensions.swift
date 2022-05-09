//
//  FFProbe+Extensions.swift
//  Transformat
//
//  Created by QIU DU on 1/5/22.
//

import ffmpegkit
import VLCKit

extension FFprobeKit {
    
    static func mediaInformation(media: VLCMedia) -> MediaInformation? {
        guard let path = media.url?.path else {
            return nil
        }
        return FFprobeKit.getMediaInformation(path).getMediaInformation()
    }
    
    static func videoBitrate(media: VLCMedia) -> Double? {
        guard let bitrate = mediaInformation(media: media)?.getBitrate() else {
            return nil
        }
        return Double(bitrate)
    }
    
    static func sizeInBytes(media: VLCMedia) -> String? {
        guard
            let bytesText = mediaInformation(media: media)?.getSize(),
            let bytes = Double(bytesText) else
        {
            return nil
        }
        
        var mesurement = Measurement(value: bytes, unit: UnitStorage.bytes)
        
        for unit in UnitStorage.allCases {
            mesurement = mesurement.converted(to: unit)
            if mesurement.value > 1 {
                break
            }
        }
        
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        formatter.numberFormatter.numberStyle = .decimal
        formatter.numberFormatter.maximumFractionDigits = 2
        return formatter.string(from: mesurement)
    }
    
    static func streamsInfomation(media: VLCMedia) -> [StreamInformation] {
        guard
            let streams = mediaInformation(media: media)?.getStreams(),
            let streamInfomations = streams as? [StreamInformation] else
        {
            return []
        }
        return streamInfomations
    }
    
    static func resolution(media: VLCMedia) -> MediaResolution? {
        let streams = streamsInfomation(media: media)

        for stream in streams {
            guard
                let widthNumber = stream.getWidth(),
                let heightNumber = stream.getHeight(),
                let width = Int(exactly: widthNumber),
                let height = Int(exactly: heightNumber) else
            {
                continue
            }

            return MediaResolution(width: width, height: height)
        }
        return nil
    }
    
    static func duration(media: VLCMedia) -> TimeInterval? {
        guard let duration = FFprobeKit.mediaInformation(media: media)?.getDuration() else {
            return nil
        }
        return TimeInterval(duration)
    }
    
    static func startTime(media: VLCMedia) -> TimeInterval? {
        guard let duration = FFprobeKit.mediaInformation(media: media)?.getStartTime() else {
            return nil
        }
        return TimeInterval(duration)
    }
    
    static func endTime(media: VLCMedia) -> TimeInterval? {
        guard
            let startTime = startTime(media: media),
            let duration = duration(media: media) else
        {
            return nil
        }
        return TimeInterval(startTime + duration)
    }
     
    static func audioTracks(media: VLCMedia) -> AudioTracks {
        var audioTracks = AudioTracks()
        let streamInfomationLists = FFprobeKit.streamsInfomation(media: media)
        for streamInformation in streamInfomationLists where streamInformation.getType().equalsToIgnoreCase("audio") {
            let index = Int(truncating: streamInformation.getIndex())
            let tags = streamInformation.getTags()
            let title = tags?["title"] as? String
            let language = tags?["language"] as? String
            let name = "\(index). " + [title, language].compactMap { $0 }.joined(separator: " - ")
            var bitrate: Double? = nil
            if let bitrateText = streamInformation.getBitrate() {
                bitrate = Double(bitrateText)
            }
            audioTracks[index] = AudioTrack(name: name, bitrate: bitrate)
        }
        audioTracks[-1] = .disabled
        return audioTracks
    }
}
