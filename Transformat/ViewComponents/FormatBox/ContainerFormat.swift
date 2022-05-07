//
//  Format.swift
//  Transformat
//
//  Created by QIU DU on 7/5/22.
//

enum ContainerFormat: String, CaseIterable {
    
    case gif
    case mp4
    case mkv
    case mov
    
    var title: String {
        switch self {
        case .gif, .mov:
            return self.rawValue.uppercased()
        case .mp4:
            return "MPEG-4"
        case .mkv:
            return "Matroska"
        }
    }
    
    var titleWithFileExtension: String {
        "\(title) (.\(rawValue))"
    }
}
