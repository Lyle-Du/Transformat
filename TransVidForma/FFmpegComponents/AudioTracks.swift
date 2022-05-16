//
//  AudioTracks.swift
//  Transformat
//
//  Created by QIU DU on 6/5/22.
//

struct AudioTrack {
    
    let index: Int
    let title: String?
    let language: String?
    let bitrate: Double?
    
    var name: String {
        let combined = [title, language].compactMap { $0 }.joined(separator: " - ")
        guard index >= 0 else {
            return combined
        }
        return "\(index). \(combined)"
    }
}

extension AudioTrack {
    static let disabled = AudioTrack(index: -1, title: "Disabled", language: nil, bitrate: nil)
}
