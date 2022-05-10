//
//  ProgressButton.swift
//  Transformat
//
//  Created by QIU DU on 11/5/22.
//

import RxCocoa
import RxSwift

final class ProgressButton: NSButton {
    
    var progress: Double {
        get { _progress }
        set { _progress = newValue.clamped(to: .zero...1) }
    }
    
    private let cornerRadius = CGFloat(4)
    
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
        isBordered = false
        wantsLayer = true
        progressLayer.cornerRadius = cornerRadius
        progressLayer.lineWidth = cornerRadius
        layer?.addSublayer(progressLayer)
        layer?.cornerRadius = cornerRadius
        layer?.masksToBounds = false
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        if isHighlighted {
            layer?.backgroundColor = NSColor.controlColor.shadow(withLevel: 0.1)?.cgColor
        } else {
            layer?.backgroundColor = NSColor.controlColor.cgColor
        }
        let red = NSColor.red.redComponent * ( 1 - progress )
        let green = NSColor.green.greenComponent * progress
        let color = NSColor(calibratedRed: red, green: green, blue: .zero, alpha: 1)
        progressLayer.strokeColor = color.cgColor
        progressLayer.fillColor = .clear
        progressLayer.strokeEnd = progress
        animation.fromValue = animation.toValue ?? 0
        animation.toValue = NSNumber(value: progress)
        progressLayer.add(animation, forKey: nil)
    }
    
    override func layout() {
        super.layout()
        let cgPath = CGMutablePath()
        cgPath.move(to: CGPoint(x: bounds.midX, y: bounds.minY))
        cgPath.addLine(to: CGPoint(x: bounds.maxX - cornerRadius, y: bounds.minY))
        cgPath.addRelativeArc(
            center: CGPoint(x: bounds.maxX - cornerRadius, y: bounds.minY + cornerRadius),
            radius: cornerRadius,
            startAngle: -.pi / 2,
            delta: .pi / 2)
        cgPath.addLine(to: CGPoint(x: bounds.maxX, y: bounds.maxY - cornerRadius))
        cgPath.addRelativeArc(
            center: CGPoint(x: bounds.maxX - cornerRadius, y: bounds.maxY - cornerRadius),
            radius: cornerRadius,
            startAngle: .zero,
            delta: .pi / 2)
        cgPath.addLine(to: CGPoint(x: bounds.minX + cornerRadius, y: bounds.maxY))
        cgPath.addRelativeArc(
            center: CGPoint(x: bounds.minX + cornerRadius, y: bounds.maxY - cornerRadius),
            radius: cornerRadius,
            startAngle: .pi / 2,
            delta: .pi / 2)
        cgPath.addLine(to: CGPoint(x: bounds.minX, y: bounds.minY + cornerRadius))
        cgPath.addRelativeArc(
            center: CGPoint(x: bounds.minX + cornerRadius, y: bounds.minY + cornerRadius),
            radius: cornerRadius,
            startAngle: .pi,
            delta: .pi / 2)
        cgPath.closeSubpath()
        progressLayer.path = cgPath.copy()
    }
}

extension Reactive where Base: ProgressButton {
    
    var progressBinder: Binder<Double?> {
        Binder(base) { base, value in
            base.progress = value ?? .zero
        }
    }
}
