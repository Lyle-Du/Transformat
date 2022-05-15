//
//  ImageButton.swift
//  Transformat
//
//  Created by QIU DU on 27/4/22.
//

import Cocoa

final class ImageButton: NSButton {
    
    var padding = CGFloat.zero {
        didSet {
            needsDisplay = true
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        if abs(padding * 2) <= dirtyRect.width {
            bounds = dirtyRect.insetBy(dx: padding, dy: padding)
        }
        super.draw(dirtyRect)
        bounds = dirtyRect
    }
}
