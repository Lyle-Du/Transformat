//
//  NSView+extension.swift
//  Transformat
//
//  Created by QIU DU on 24/4/22.
//

import Cocoa

extension NSView {
    
    // Making view acceptFirstResponder by default,
    // This will enable NSViewController receive responder event dispatched into responder chain
    open override var acceptsFirstResponder: Bool{ true }
    
    func pinEdgesTo(view: NSView, padding: CGFloat = .zero) {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
            topAnchor.constraint(equalTo: view.topAnchor, constant: padding),
            bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -padding),
        ])
    }
}

extension NSImage {
    
    func tint(color: NSColor) -> NSImage {
        let image = self.copy() as! NSImage
        image.lockFocus()
        color.set()
        let imageRect = NSRect(origin: NSZeroPoint, size: image.size)
        imageRect.fill(using: .sourceAtop)
        image.unlockFocus()
        image.isTemplate = false
        return image
    }
}

extension NSTextField {
    
    static func makeLabel() -> NSTextField {
        let field = NSTextField()
        field.isBordered = false
        field.isEditable = false
        field.backgroundColor = .clear
        return field
    }
}
