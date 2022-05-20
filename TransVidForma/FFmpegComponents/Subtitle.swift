//
//  Subtitle.swift
//  TransVid Forma
//
//  Created by QIU DU on 20/5/22.
//  Copyright © 2022 Qiu Du. All rights reserved.
//

import Foundation

struct Subtitle {
    
    let streamID: Int
    let titleID: Int
    let title: String?
    let language: String?
    
    var name: String {
        guard titleID != Self.disabled.titleID else {
            return Self.disabledTitle
        }
        let combined = [title, language].compactMap { $0 }.joined(separator: " - ")
        return "\(titleID). \(combined)"
    }
}

extension Subtitle {
    static let disabled = Subtitle(streamID: -1, titleID: 0, title: disabledTitle, language: nil)
    static let disabledTitle = NSLocalizedString("Disabled", comment: "")
}
