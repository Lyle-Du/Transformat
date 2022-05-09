//
//  MediaResolution.swift
//  Transformat
//
//  Created by QIU DU on 1/5/22.
//


import Foundation

struct MediaResolution {
    
    let width: Int
    let height: Int
    
    private let scale: CGFloat
    
    init(width: Int, height: Int, scaled: CGFloat = 1.0) {
        scale = scaled
        self.width = Int((CGFloat(width) * scaled).rounded())
        self.height = Int((CGFloat(height) * scaled).rounded())
    }
}

extension MediaResolution: Equatable {
    
    static let custom = MediaResolution(width: Int.min, height: Int.min)
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.width == rhs.width && lhs.height == rhs.height
    }
}

extension MediaResolution {
    
    var description: String {
        guard self != .custom else {
            return "Custom"
        }
        return "\(width) x \(height)"
    }
    
    var descriptionWithScale: String {
        guard self != .custom else {
            return description
        }
        return "\(description) - \(String(format: "%.0f", scale * 100))%"
    }
}
