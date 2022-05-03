//
//  MediaDimension.swift
//  Transformat
//
//  Created by QIU DU on 1/5/22.
//

struct MediaDimension {
    
    let width: Int
    let height: Int
    let scaled: Float
    
    init(width: Int, height: Int, scaled: Float = 1) {
        self.width = Int((Float(width) * scaled).rounded())
        self.height = Int((Float(height) * scaled).rounded())
        self.scaled = scaled
    }
    
    init(mediaDimension: MediaDimension, scaled: Float = 1) {
        self.scaled = mediaDimension.scaled * scaled
        self.width = Int((Float(mediaDimension.width) * self.scaled).rounded())
        self.height = Int((Float(mediaDimension.height) * self.scaled).rounded())
    }
}

extension MediaDimension {
    
    var description: String {
        "\(width) x \(height) - \(String(format: "%.0f", scaled * 100))%"
    }
}
