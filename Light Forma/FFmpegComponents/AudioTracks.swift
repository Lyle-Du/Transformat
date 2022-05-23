//
//  AudioTracks.swift
//  Transformat
//
//  Created by QIU DU on 6/5/22.
//

import Foundation

struct AudioTrack {
    
    let streamID: Int
    let titleID: Int
    let title: String?
    let language: String?
    let bitrate: Double?
    
    var name: String {
        guard titleID != Self.disabled.titleID else {
            return Self.disabledTitle
        }
        let combined = [title, language].compactMap { $0 }.joined(separator: " - ")
        return "\(titleID). \(combined)"
    }
}

extension AudioTrack {
    static let disabled = AudioTrack(streamID: -1, titleID: 0, title: Self.disabledTitle, language: nil, bitrate: nil)
    static let disabledTitle = NSLocalizedString("Disabled", comment: "")
}
