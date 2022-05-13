//
//  TrimButton.swift
//  Transformat
//
//  Created by QIU DU on 3/5/22.
//

import Cocoa

final class TrimButton: NSButton {
    
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
        font = .boldSystemFont(ofSize: 12)
        let title = "|"
        let attribute = [ NSAttributedString.Key.foregroundColor: NSColor.lightGray ]
        attributedTitle = NSAttributedString(string: title, attributes: attribute)
        layer?.backgroundColor = Constants.borderColor.cgColor
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        if isHighlighted {
            layer?.backgroundColor = Constants.buttonHighlitedColor.cgColor
        } else {
            layer?.backgroundColor = Constants.borderColor.cgColor
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        highlight(true)
    }
    
    override func mouseUp(with event: NSEvent) {
        highlight(false)
    }
}

extension TrimButton {
    struct Constants {
        static let buttonNormalColor = NSColor.white
        static let buttonHighlitedColor = NSColor(white: 0.8, alpha: 1)
        static let borderColor = buttonNormalColor
    }
}
