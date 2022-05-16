//
//  ControlPanel.swift
//  Transformat
//
//  Created by QIU DU on 26/4/22.
//

import Cocoa

import RxCocoa
import RxSwift
import VLCKit

final class ControlPanel: NSView {
    
    var viewModel: ControlPanelViewModel! {
        didSet {
            bind()
        }
    }
    
    private let disposeBag = DisposeBag()
    
    private let container: NSView = {
        let view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    fileprivate let playButton: ImageButton = {
        let button = ImageButton()
        button.padding = 12
        button.image = NSImage(named: ControlPanelViewModel.Constants.playImageName)
        button.title = ""
        button.image?.isTemplate = true
        button.image = button.image?.tint(color: NSColor.white)
        button.imageScaling = .scaleProportionallyDown
        button.font = .systemFont(ofSize: 24)
        button.isBordered = false
        button.wantsLayer = true
        button.layer?.cornerRadius = 4
        button.layer?.backgroundColor = NSColor(white: 0.2, alpha: 1).cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    fileprivate let trimControl: TrimControl = {
        let view = TrimControl()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
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
        addSubview(container)
        container.addSubview(playButton)
        container.addSubview(trimControl)
        container.pinEdgesTo(view: self)
        
        NSLayoutConstraint.activate([
            playButton.topAnchor.constraint(equalTo: container.topAnchor),
            playButton.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            playButton.widthAnchor.constraint(equalTo: container.heightAnchor),
            playButton.heightAnchor.constraint(equalTo: container.heightAnchor),
            
            trimControl.leadingAnchor.constraint(equalTo: playButton.trailingAnchor, constant: 12),
            trimControl.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            trimControl.topAnchor.constraint(equalTo: container.topAnchor),
            trimControl.heightAnchor.constraint(equalTo: container.heightAnchor),
        ])
    }
    
    private func bind() {
        trimControl.viewModel = viewModel.trimControlModel
        
        playButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.viewModel.playClicked()
            })
            .disposed(by: disposeBag)
        
        viewModel.playButtonImageName
            .map { NSImage(named: $0)?.tint(color: .white) }
            .drive(playButton.rx.image)
            .disposed(by: disposeBag)
    }
}
