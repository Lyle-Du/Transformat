//
//  ProgressButton.swift
//  Transformat
//
//  Created by QIU DU on 11/5/22.
//

import RxCocoa
import RxSwift

final class ProgressButton: NSButton {
    
    var cornerRadius = CGFloat(4)
    var lineWidth = CGFloat(4)
    var progressColor: NSColor = .systemBlue
    
    var progress: Double {
        get { _progress }
        set { _progress = newValue.clamped(to: .zero...1) }
    }
    
    private var _progress: Double = .zero {
        didSet {
            needsDisplay = true
        }
    }
    
    private let progressLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.shadowOpacity = 1
        layer.shadowOffset = .zero
        return layer
    }()
    
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
        progressLayer.cornerRadius = cornerRadius
        progressLayer.lineWidth = lineWidth
        wantsLayer = true
        layer?.addSublayer(progressLayer)
        layer?.masksToBounds = false
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        progressLayer.fillColor = .clear
        progressLayer.shadowColor = progressColor.cgColor
        progressLayer.strokeColor = progressColor.cgColor
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

extension Notification.Name {
    static let AppleInterfaceThemeChangedNotification = Notification.Name("AppleInterfaceThemeChangedNotification")
}
