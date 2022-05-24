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
        button.image?.isTemplate = true
        button.image = button.image?.tint(color: NSColor.white)
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
    
    private let audioTrackLabel: NSTextField = {
        let field = NSTextField.makeLabel()
        field.alignment = .right
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()
    
    private let audioTrackPopUpButton: NSPopUpButton = {
        let button = NSPopUpButton()
        button.bezelStyle = .roundRect
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setContentCompressionResistancePriority(.fittingSizeCompression, for: .horizontal)
        button.setContentHuggingPriority(.fittingSizeCompression, for: .horizontal)
        return button
    }()
    
    private let subtitleLabel: NSTextField = {
        let field = NSTextField.makeLabel()
        field.alignment = .right
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()
    
    private let subtitlePopUpButton: NSPopUpButton = {
        let button = NSPopUpButton()
        button.bezelStyle = .roundRect
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setContentCompressionResistancePriority(.fittingSizeCompression, for: .horizontal)
        button.setContentHuggingPriority(.fittingSizeCompression, for: .horizontal)
        return button
    }()
    
    private let audioSubtitleOptionsContainer: NSStackView = {
        let view = NSStackView()
        view.distribution = .equalCentering
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
        
        addSubview(audioSubtitleOptionsContainer)
        audioSubtitleOptionsContainer.addArrangedSubview(audioTrackLabel)
        audioSubtitleOptionsContainer.addArrangedSubview(audioTrackPopUpButton)
        audioSubtitleOptionsContainer.addArrangedSubview(subtitleLabel)
        audioSubtitleOptionsContainer.addArrangedSubview(subtitlePopUpButton)
        
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            audioSubtitleOptionsContainer.topAnchor.constraint(equalTo: container.bottomAnchor),
            audioSubtitleOptionsContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            audioSubtitleOptionsContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            audioSubtitleOptionsContainer.heightAnchor.constraint(equalToConstant: 24),
            audioSubtitleOptionsContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        
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
        audioTrackLabel.stringValue = viewModel.audioTrackLabel
        subtitleLabel.stringValue = viewModel.subtitleLabel
        
        playButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.viewModel.playClicked()
            })
            .disposed(by: disposeBag)
        
        viewModel.playButtonImageName
            .map { NSImage(named: $0)?.tint(color: .white) }
            .drive(playButton.rx.image)
            .disposed(by: disposeBag)
        
        viewModel.currentAudioTrackIndex
            .drive(audioTrackPopUpButton.rx.selectedIndex)
            .disposed(by: disposeBag)
        
        audioTrackPopUpButton.rx.selectedIndex
            .bind(to: viewModel.currentAudioTrackIndexBinder)
            .disposed(by: disposeBag)
        
        viewModel.currentSubtitleIndex
            .drive(subtitlePopUpButton.rx.selectedIndex)
            .disposed(by: disposeBag)
        
        subtitlePopUpButton.rx.selectedIndex
            .bind(to: viewModel.currentSubtitleIndexBinder)
            .disposed(by: disposeBag)
        
        viewModel.audioTrackNames
            .drive(onNext: { [weak self] in
                guard let self = self else { return }
                self.setupPopupButtoon(self.audioTrackPopUpButton, $0)
            })
            .disposed(by: disposeBag)
        
        viewModel.subtitleNames
            .drive(onNext: { [weak self] in
                guard let self = self else { return }
                self.setupPopupButtoon(self.subtitlePopUpButton, $0)
            })
            .disposed(by: disposeBag)
    }
    
    private func setupPopupButtoon(_ button: NSPopUpButton, _ names: [String]) {
        button.removeAllItems()
        button.addItems(withTitles: names)
    }
}
