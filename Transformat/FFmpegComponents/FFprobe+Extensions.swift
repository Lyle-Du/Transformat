//
//  FFProbe+Extensions.swift
//  Transformat
//
//  Created by QIU DU on 1/5/22.
//

import ffmpegkit
import VLCKit

extension FFprobeKit {
    
    static func sizeInBytes(media: VLCMedia) -> String? {
        guard
            let path = media.url?.path,
            let bytesText = FFprobeKit.getMediaInformation(path).getMediaInformation().getSize(),
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
            let path = media.url?.path,
            let streams = FFprobeKit.getMediaInformation(path).getMediaInformation().getStreams(),
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
        guard
            let path = media.url?.path,
            let duration = FFprobeKit.getMediaInformation(path).getMediaInformation().getDuration() else
        {
            return nil
        }
        return TimeInterval(duration)
    }
    
    static func startTime(media: VLCMedia) -> TimeInterval? {
        guard
            let path = media.url?.path,
            let duration = FFprobeKit.getMediaInformation(path).getMediaInformation().getStartTime() else
        {
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
            let text = "Track \(index): " + [title, language].compactMap { $0 }.joined(separator: " - ")
            audioTracks[index] = text
        }
        audioTracks[-1] = "Disabled"
        return audioTracks
    }
}
