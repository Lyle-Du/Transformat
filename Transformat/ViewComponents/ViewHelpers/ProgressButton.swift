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
    
    private let foregroundLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        return layer
    }()
    
    private let animation: CABasicAnimation = {
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.duration = 0.5
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        return animation
    }()
    
    private let label: NSTextField = {
        let textView = NSTextField.makeLabel()
        textView.isSelectable = false
        textView.alignment = .center
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
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
        layer?.backgroundColor = .clear
        progressLayer.cornerRadius = cornerRadius
        progressLayer.lineWidth = cornerRadius
        foregroundLayer.cornerRadius = cornerRadius
        layer?.addSublayer(progressLayer)
        layer?.addSublayer(foregroundLayer)
        layer?.cornerRadius = cornerRadius
        layer?.masksToBounds = false
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
            label.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
        ])
        
        DistributedNotificationCenter.default.addObserver(
            self,
            selector: #selector(interfaceModeChanged(sender:)),
            name: .AppleInterfaceThemeChangedNotification,
            object: nil)
    }
    
    @objc func interfaceModeChanged(sender: NSNotification) {
        needsDisplay = true
    }
    
    
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        let foregroundEnabledColor = isDarkMode ? NSColor(white: 90 / 255, alpha: 1) : NSColor.white
        let foregroundDisabledColor = isDarkMode ? NSColor(white: 45 / 255, alpha: 1) : NSColor(white: 250 / 255, alpha: 1)
        if self.isEnabled {
            foregroundLayer.strokeColor = (isDarkMode ? NSColor(white: 100 / 255, alpha: 1) : NSColor(white: 222 / 255, alpha: 1)).cgColor
            foregroundLayer.fillColor = foregroundEnabledColor.shadow(withLevel: isHighlighted ? 0.2 : .zero)?.cgColor
        } else {
            foregroundLayer.strokeColor = (isDarkMode ? NSColor(white: 50 / 255, alpha: 1) : NSColor(white: 222 / 255, alpha: 1)).cgColor
            foregroundLayer.fillColor = foregroundDisabledColor.cgColor
        }
        
        foregroundLayer.frame = dirtyRect
        progressLayer.strokeColor = progressColor.cgColor
        progressLayer.fillColor = .clear
        progressLayer.strokeEnd = progress
        progressLayer.shadowColor = progressColor.cgColor
        animation.fromValue = animation.toValue ?? 0
        animation.toValue = NSNumber(value: progress)
        progressLayer.add(animation, forKey: nil)
        label.stringValue = title
        label.font = font
        label.isEnabled = isEnabled
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
        foregroundLayer.path = cgPath.copy()
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


extension NSView {
    
    var isDarkMode: Bool {
        let mode = UserDefaults.standard.string(forKey: "AppleInterfaceStyle")
        let isDarkMode = mode == "Dark"
        return isDarkMode
    }
}
