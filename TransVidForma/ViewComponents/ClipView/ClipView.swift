//
//  ClipView.swift
//  TransVidForma
//
//  Created by QIU DU on 15/5/22.
//  Copyright © 2022 Qiu Du. All rights reserved.
//

import Cocoa

import RxSwift

final class ClipView: NSControl {
    
    private let disposeBag = DisposeBag()
    
    var viewModel: ClipViewModel! {
        didSet {
            bind()
        }
    }
    
    private let scrollView: NSScrollView = {
        let scrollView = NSScrollView()
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private let container: DraggableStackView = {
        let stackView = DraggableStackView()
        stackView.orientation = .horizontal
        stackView.distribution = .fill
        stackView.spacing = 1
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private let dragHintLabel: NSTextField = {
        let label = NSTextField.makeLabel()
        label.cell = TextFieldCell()
        label.textColor = .white
        label.alignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let addButton: ImageButton = {
        let button = ImageButton()
        button.padding = 12
        button.image = NSImage(named: "add")
        button.title = ""
        button.image?.isTemplate = true
        button.image = button.image?.tint(color: NSColor.white)
        button.imageScaling = .scaleProportionallyDown
        button.font = .systemFont(ofSize: 24)
        button.isBordered = false
        button.wantsLayer = true
        button.layer?.cornerRadius = 4
        button.layer?.backgroundColor = NSColor.clear.cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func flagsChanged(with event: NSEvent) -> NSEvent? {
        let point = convert(event.locationInWindow, from: nil)
        if bounds.contains(point) {
            updateCursor(with: event)
        }
        return event
    }
    
    private func commonInit() {
        NSEvent.addLocalMonitorForEvents(matching: [.flagsChanged, .leftMouseDragged, .leftMouseUp], handler: flagsChanged)
        wantsLayer = true
        layer?.backgroundColor = NSColor(calibratedRed: .zero, green: 0.2, blue: .zero, alpha: 1.0).cgColor
        addSubview(dragHintLabel)
        addSubview(addButton)
        addSubview(scrollView)
        scrollView.documentView = container
        dragHintLabel.pinEdgesTo(view: self)
        let padding = CGFloat(2)
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            scrollView.trailingAnchor.constraint(equalTo: addButton.leadingAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor, constant: padding),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -padding),
            
            container.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
            
            addButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            addButton.heightAnchor.constraint(equalTo: heightAnchor),
            addButton.widthAnchor.constraint(equalTo: addButton.heightAnchor),
            addButton.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }
    
    private func bind() {
        
        dragHintLabel.stringValue = viewModel.dragHint
        
        let clips = container.viewsDriver
            .map { views -> [Clip] in
                views.compactMap { view in
                    guard let view = view as? SubClipView else {
                        return nil
                    }
                    return view.clip
                }
            }
            .asDriver()
        
        disposeBag.insert([
            addButton.rx.tap.subscribe(onNext: { [weak self] _ in
                self?.addClip()
            }),
            clips.drive(viewModel.clipsBinder),
        ])
    }
}

extension ClipView {
    
    private func addClip() {
        guard let clip = viewModel.clip() else {
            return
        }
        let view = Self.makeSubClipView(clip)
        container.addView(view, in: .leading)
        viewModel.trimControlModel.canAddClip = false
    }
    
    private func updateCursor(with event: NSEvent) {
        if event.modifierFlags.contains(.option) {
            if event.type == .leftMouseDragged {
                if viewModel.trimControlModel.canAddClip {
                    guard NSCursor.current != .dragCopy else { return }
                    NSCursor.dragCopy.set()
                }
            } else if event.type == .leftMouseUp {
                guard NSCursor.current != .arrow else { return }
                if viewModel.trimControlModel.canAddClip {
                    addClip()
                }
                NSCursor.arrow.set()
            }
        } else {
            guard NSCursor.current != .arrow else { return }
            NSCursor.arrow.set()
        }
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        for trackingArea in self.trackingAreas {
            self.removeTrackingArea(trackingArea)
        }
        
        let options: NSTrackingArea.Options = [
            .mouseEnteredAndExited,
            .activeAlways,
            .enabledDuringMouseDrag,
        ]
        let trackingArea = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
    }
}

extension ClipView {
    
    static func makeSubClipView(_ clip: Clip) -> SubClipView {
        let view = SubClipView()
        view.clip = clip
        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalTo: view.heightAnchor, multiplier: 20 / 9),
        ])
        return view
    }
}
