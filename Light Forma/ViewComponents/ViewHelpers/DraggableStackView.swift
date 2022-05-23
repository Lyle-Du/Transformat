//
//  DraggableStackView.swift
//  TransVidForma
//
//  Created by QIU DU on 16/5/22.
//  Copyright © 2022 Qiu Du. All rights reserved.
//

import Cocoa

import RxCocoa
import RxSwift

final class DraggableStackView: NSStackView {
    
    var viewsDriver: Driver<[NSView]> {
        viewsRelay.asDriver()
    }
    
    private let viewsRelay = BehaviorRelay<[NSView]>(value: [])

    private func cacheViews() throws -> [CachedViewLayer] {
        return try views.map { try cacheView(view: $0) }
    }

    private func cacheView(view: NSView) throws -> CachedViewLayer {
        return try CachedViewLayer(view: view)
    }
    
    override func addView(_ view: NSView, in gravity: NSStackView.Gravity) {
        super.addView(view, in: gravity)
        switch orientation {
        case .horizontal:
            view.topAnchor.constraint(equalTo: topAnchor).isActive = true
            view.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        case .vertical:
            view.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
            view.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        @unknown default:
            break
        }
        viewsRelay.accept(views)
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for trackingArea in self.trackingAreas {
            self.removeTrackingArea(trackingArea)
        }

        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .mouseMoved, .activeAlways]
        let trackingArea = NSTrackingArea(rect: frame, options: options, owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
    }
}

extension DraggableStackView {
    
    private class CachedViewLayer: CALayer {
        
        let view: NSView
        
        enum CacheError: Error {
            case bitmapCreationFailed
        }
        
        override init(layer: Any) {
            view = (layer as! CachedViewLayer).view
            super.init(layer: layer)
        }
        
        init(view: NSView) throws {
            self.view = view
            super.init()
            try commonInit()
        }
        
        required init?(coder: NSCoder) {
            view = NSView()
            super.init(coder: coder)
        }
        
        private func commonInit() throws {
            guard let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds) else {
                throw CacheError.bitmapCreationFailed
            }
            view.cacheDisplay(in: view.bounds, to: bitmap)
            
            frame = view.frame
            contents = bitmap.cgImage
        }
    }
}

extension DraggableStackView {
    
    override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)
        let location = convert(event.locationInWindow, from: nil)
        if let dragged = views.first(where: { $0.hitTest(location) != nil }) {
            reorder(view: dragged, event: event)
        }
    }
    
    func update(views: [NSView]) {
    
        views.forEach {
            removeView($0)
        }

        views.forEach {
            addView($0, in: .leading)
            switch orientation {
            case .horizontal:
                $0.topAnchor.constraint(equalTo: topAnchor).isActive = true
                $0.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
            case .vertical:
                $0.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
                $0.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
            @unknown default:
                break
            }
        }
        
        viewsRelay.accept(views)
    }
    
    private func reorder(view: NSView, event: NSEvent) {
        guard
            let layer = layer,
            let cached = try? cacheViews() else
        {
            return
        }

        let container = CALayer()
        container.frame = layer.bounds
        container.zPosition = 1
        container.backgroundColor = NSColor.underPageBackgroundColor.cgColor

        cached.filter { $0.view != view }.forEach {
            container.addSublayer($0)
        }

        layer.addSublayer(container)
        defer {
            container.removeFromSuperlayer()
        }

        let dragged = cached.first(where: { $0.view == view })!

        dragged.zPosition = 2
        layer.addSublayer(dragged)
        defer {
            dragged.removeFromSuperlayer()
        }

        let d0 = view.frame.origin
        let p0 = convert(event.locationInWindow, from: nil)

        window?.trackEvents(matching: [.leftMouseDragged, .leftMouseUp], timeout: 1e6, mode: .eventTracking) { event, stop in
            if let event = event, event.type == .leftMouseDragged {
                let p1 = self.convert(event.locationInWindow, from: nil)

                let dx = (self.orientation == .horizontal) ? p1.x - p0.x : 0
                let dy = (self.orientation == .vertical)   ? p1.y - p0.y : 0

                CATransaction.begin()
                CATransaction.setDisableActions(true)
                dragged.frame.origin.x = d0.x + dx
                dragged.frame.origin.y = d0.y + dy
                CATransaction.commit()

                let reordered = views
                    .map { new -> (NSView, NSPoint) in
                        let newView = new
                        let position: NSPoint
                        if newView != view {
                            position = NSPoint(x: newView.frame.midX, y: newView.frame.midY)
                        } else {
                            position = NSPoint(x: dragged.frame.midX, y: dragged.frame.midY)
                        }
                        return (newView, position)
                    }
                    .sorted {
                        switch self.orientation {
                        case .vertical:
                            return $0.1.y < $1.1.y
                        case .horizontal:
                            return $0.1.x < $1.1.x
                        @unknown default:
                            return $0.1.x < $1.1.x
                        }
                    }
                    .map { $0.0 }

                let nextIndex = reordered.firstIndex(of: view)!
                let prevIndex = views.firstIndex(of: view)!

                if nextIndex != prevIndex {
                    self.update(views: reordered)
                    self.layoutSubtreeIfNeeded()

                    CATransaction.begin()
                    CATransaction.setAnimationDuration(0.15)
                    CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut))

                    for layer in cached {
                        layer.position = NSPoint(x: layer.view.frame.midX, y: layer.view.frame.midY)
                    }

                    CATransaction.commit()
                }

            } else {
                if let event = event {
                    view.mouseUp(with: event)
                    stop.pointee = true
                }
            }
        }
    }
}

private extension DraggableStackView {
    
    func mouseDragIn(_ event: NSEvent) -> NSEvent? {
        let point = convert(event.locationInWindow, from: nil)
        guard frame.contains(point) else { return nil }
        return event
    }
}
