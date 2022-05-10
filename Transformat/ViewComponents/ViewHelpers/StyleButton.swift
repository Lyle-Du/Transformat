//
//  StyleButton.swift
//  Transformat
//
//  Created by QIU DU on 10/5/22.
//

import Cocoa

final class StyleButton: NSButton {
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        isBordered = false
        wantsLayer = true
        layer?.cornerRadius = 4
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        if isHighlighted {
            layer?.backgroundColor = NSColor.controlColor.shadow(withLevel: 0.1)?.cgColor
        } else {
            layer?.backgroundColor = NSColor.controlColor.cgColor
        }
    }
}
