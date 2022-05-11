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
        guard
            let media = media,
            let inputPath = media.url?.path else
        {
            return [:]
        }
        guard count > 0 else { return [:] }
        let start = FFprobeKit.startTime(media: media) ?? .zero
        let duration = FFprobeKit.duration(media: media) ?? .zero
        let directory = NSTemporaryDirectory()
        let directoryURL = URL(fileURLWithPath: directory).appendingPathComponent("trim_tracke_thumbnail", isDirectory: true)
        do {
            try fileManager.createDirectory(atPath: directoryURL.path, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print(error.localizedDescription)
        }
        let interval = duration / Double (count)
        
        let ids = (0..<count)
        
        var result = [Int: NSImage]()
        
        for id in ids {
            let fileURL = directoryURL.appendingPathComponent(String(id)).appendingPathExtension("png")
            execute(withArguments: [
                "-nostdin",
                "-y",
                "-ss",
                String(start + interval * Double(id)),
                "-i",
                inputPath,
                "-vf",
                "scale=-1:50",
                "-vframes",
                "1",
                fileURL.path,
            ])
            
            do {
                result[id] = try NSImage(data: Data(contentsOf: fileURL))
            } catch {
                print(error)
            }
        }
        return result
    }
}
