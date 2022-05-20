//
//  ProgressButton.swift
//  Transformat
//
//  Created by QIU DU on 11/5/22.
//

import RxCocoa
import RxSwift

final class ProgressButton: NSButton {
    
    var progressColor: NSColor = .systemBlue
    
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
        progressLayer.lineWidth = cornerRadius
        layer?.addSublayer(progressLayer)
        layer?.cornerRadius = cornerRadius
        layer?.masksToBounds = false
        translatesAutoresizingMaskIntoConstraints = false
        
        DistributedNotificationCenter.default.addObserver(
            self,
            selector: #selector(interfaceModeChanged(sender:)),
            name: .AppleInterfaceThemeChangedNotification,
            object: nil)
    }
    
    @objc func interfaceModeChanged(sender: NSNotification) {
        needsDisplay = true
    }
    
    var foregroundEnabledFillColor: NSColor = NSColor(white: 10 / 255.0, alpha: 1)
    var foregroundDisabledFillColor: NSColor = NSColor(white: 45 / 255.0, alpha: 1)
    
    var foregroundEnabledStrokeColor: NSColor = NSColor(white: 100 / 255.0, alpha: 1)
    var foregroundDisabledStrokeColor: NSColor = NSColor(white: 50 / 255.0, alpha: 1)
    
    var foregroundEnabledDarkFillColor: NSColor = NSColor(white: 110 / 255.0, alpha: 1)
    var foregroundDisabledDarkFillColor: NSColor = NSColor(white: 45 / 255.0, alpha: 1)
    
    var foregroundEnabledDarkStrokeColor: NSColor = NSColor(white: 130 / 255.0, alpha: 1)
    var foregroundDisabledDarkStrokeColor: NSColor = NSColor(white: 50 / 255.0, alpha: 1)
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        progressLayer.strokeColor = progressColor.cgColor
        progressLayer.fillColor = .clear
        progressLayer.strokeEnd = progress
        progressLayer.shadowColor = progressColor.cgColor
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
