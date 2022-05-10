//
//  ProgressView.swift
//  Transformat
//
//  Created by QIU DU on 10/5/22.
//

import Cocoa
import RxSwift

final class ProgressView: NSView {
    
    var progress: Double {
        get { _progress }
        set { _progress = newValue.clamped(to: .zero...1) }
    }
    
    private var _progress: Double = .zero {
        didSet {
            needsDisplay = true
        }
    }
    
    private let progressLayer = CAShapeLayer()
    private let animation: CABasicAnimation = {
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.duration = 0.5
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        return animation
    }()
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        wantsLayer = true
        layer?.backgroundColor = .clear
        layer?.addSublayer(progressLayer)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        progressLayer.lineWidth = bounds.height
        let red = NSColor.red.redComponent * ( 1 - progress )
        let green = NSColor.green.greenComponent * progress
        let color = NSColor(calibratedRed: red, green: green, blue: .zero, alpha: 1)
        progressLayer.strokeColor = color.cgColor
        progressLayer.strokeEnd = progress
        animation.fromValue = animation.toValue ?? 0
        animation.toValue = NSNumber(value: progress)
        progressLayer.add(animation, forKey: nil)
    }
    
    override func layout() {
        super.layout()
        let cgPath = CGMutablePath()
        cgPath.move(to: CGPoint(x: bounds.minX, y: bounds.midY))
        cgPath.addLine(to: CGPoint(x: bounds.maxX, y: bounds.midY))
        progressLayer.path = cgPath.copy()
    }
}

extension Reactive where Base: ProgressView {
    
    var progressBinder: Binder<Double?> {
        Binder(base) { base, value in
            base.progress = value ?? .zero
        }
    }
}
