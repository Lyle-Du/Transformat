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
    open override var acceptsFirstResponder: Bool { true }
    
    func pinEdgesTo(view: NSView, padding: CGFloat = .zero) {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
            topAnchor.constraint(equalTo: view.topAnchor, constant: padding),
            bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -padding),
        ])
    }
    
    func pinEdgesTo(view: NSView, padding: CGFloat = .zero, orientation: Orientation) {
        translatesAutoresizingMaskIntoConstraints = false
        var horizontalPadding = CGFloat.zero
        var verticalPadding = CGFloat.zero
        switch orientation {
        case .horizontal:
            horizontalPadding = padding
        case .vertical:
            verticalPadding = padding
        }
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: horizontalPadding),
            trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -horizontalPadding),
            topAnchor.constraint(equalTo: view.topAnchor, constant: verticalPadding),
            bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -verticalPadding),
        ])
    }
    
    enum Orientation {
        case horizontal
        case vertical
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

extension NSVisualEffectView {
    
    static func makeDarkBlurView() -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .behindWindow
        view.state = .active
        view.isEmphasized = true
        view.appearance = NSAppearance(named: .vibrantDark)
        return view
    }
}

extension NSStackView {
    
    func removeAllArrangedSubviews() {
        
        let removedSubviews = arrangedSubviews.reduce([]) { (allSubviews, subview) -> [NSView] in
            self.removeArrangedSubview(subview)
            return allSubviews + [subview]
        }
        
        // Deactivate all constraints
        NSLayoutConstraint.deactivate(removedSubviews.flatMap({ $0.constraints }))
        
        // Remove the views from self
        removedSubviews.forEach({ $0.removeFromSuperview() })
    }
}
