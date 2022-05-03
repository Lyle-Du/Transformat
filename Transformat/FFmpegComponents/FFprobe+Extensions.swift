//
//  FFProbe+Extensions.swift
//  Transformat
//
//  Created by QIU DU on 1/5/22.
//

import ffmpegkit
import VLCKit

extension FFprobeKit {
    
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
    
    static func codedDimension(media: VLCMedia) -> MediaDimension? {
        let streams = streamsInfomation(media: media)
        
        for stream in streams {
            let allProperties = stream.getAllProperties()
            
            guard
                let widthNumber = allProperties?["width"] as? NSNumber,
                let heightNumber = allProperties?["height"] as? NSNumber,
                let width = Int(exactly: widthNumber),
                let height = Int(exactly: heightNumber) else
            {
                continue
            }
            
            return MediaDimension(width: width, height: height)
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
}
