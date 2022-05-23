//
//  SubClipView.swift
//  TransVidForma
//
//  Created by QIU DU on 17/5/22.
//  Copyright © 2022 Qiu Du. All rights reserved.
//

import Cocoa

final class SubClipView: NSView {
    
    var clip: Clip! {
        didSet {
            starTimeLabel.stringValue = NSLocalizedString("Start Time:", comment: "") + "\n" + (clip.start.toTimeString() ?? "")
            endTimeLabel.stringValue = NSLocalizedString("End Time:", comment: "") + "\n" + (clip.end.toTimeString() ?? "")
        }
    }
    
    private let container: NSStackView = {
        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = 0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private let starTimeLabel: NSTextField = {
        let label = NSTextField.makeLabel()
        label.cell = TextFieldCell()
        label.font = .systemFont(ofSize: 8)
        label.textColor = .white
        label.maximumNumberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let endTimeLabel: NSTextField = {
        let label = NSTextField.makeLabel()
        label.cell = TextFieldCell()
        label.font = .systemFont(ofSize: 8)
        label.textColor = .white
        label.maximumNumberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let closeButton: NSButton = {
        let button = NSButton()
        button.bezelStyle = .circular
        button.controlSize = .small
        button.title = "╳"
        button.font = .labelFont(ofSize: 8)
        button.imageScaling = NSImageScaling.scaleProportionallyUpOrDown
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
        wantsLayer = true
        layer?.backgroundColor = NSColor.red.cgColor
        layer?.cornerRadius = 4
        
        addSubview(container)
        addSubview(closeButton)
        
        container.addArrangedSubview(starTimeLabel)
        container.addArrangedSubview(endTimeLabel)
        
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -4),
            
            closeButton.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            closeButton.widthAnchor.constraint(equalToConstant: 12),
            closeButton.widthAnchor.constraint(equalTo: closeButton.heightAnchor),
        ])
        
        closeButton.target = self
        closeButton.action = #selector(closeButtonClicked)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func closeButtonClicked() {
        removeFromSuperview()
    }
}
