//
//  FFmpeg+Extensions.swift
//  Transformat
//
//  Created by QIU DU on 11/5/22.
//

import ffmpegkit
import VLCKit

extension FFmpegKit {
    
    static func thumbnails(media: VLCMedia?, count: Int, fileManager: FileManager = .default) -> [Int: NSImage] {
        var result = [Int: NSImage]()
        
        guard let media = media else {
            return result
        }
        guard count > 0 else { return result }
        let start = FFprobeKit.startTime(media: media) ?? .zero
        let duration = FFprobeKit.duration(media: media) ?? .zero
        let directoryURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("trim_tracke_thumbnail", isDirectory: true)
        let success: ()? = try? fileManager.createDirectory(atPath: directoryURL.path, withIntermediateDirectories: true, attributes: nil)
        guard success != nil else { return result }
        
        let interval = duration / Double (count)
        
        DispatchQueue.concurrentPerform(iterations: count) { id in
            let fileURL = directoryURL.appendingPathComponent(String(id)).appendingPathExtension("png")
            if let argumentsBuilder = FFmpegArgumentsBuilder(media: media, outputURL: fileURL) {
                let arguments = argumentsBuilder.reset()
                    .time(start: String(start + interval * Double(id)))
                    .resolution(width: -1, height: 50)
                    .frames(count: 1)
                    .build()
                execute(withArguments: arguments)
            }
        }
        
        for id in (0..<count) {
            let fileURL = directoryURL.appendingPathComponent(String(id)).appendingPathExtension("png")
            result[id] = try? NSImage(data: Data(contentsOf: fileURL))
        }
        
        return result
    }
}
