//
//  AudioTracks.swift
//  Transformat
//
//  Created by QIU DU on 6/5/22.
//

typealias AudioTracks = [Int: AudioTrack]

struct AudioTrack {
    let name: String
    let bitrate: Double?
}

extension AudioTrack {
    static let disabled = AudioTrack(name: "Disabled", bitrate: nil)
}
