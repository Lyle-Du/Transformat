//
//  AudioBox.swift
//  Transformat
//
//  Created by QIU DU on 28/4/22.
//

import Cocoa

import RxCocoa
import RxSwift
import VLCKit
import ffmpegkit

final class MediaInfomationBox: NSBox {
    
    var viewModel: MediaInfomationBoxModel! {
        didSet {
            bind()
        }
    }
    
    private let disposeBag = DisposeBag()
    
    fileprivate let startTimeTextField: NSTextField = {
        let textField = NSTextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    fileprivate let endTimeTextField: NSTextField = {
        let textField = NSTextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private lazy var audioTrackPopUpButton: NSPopUpButton = {
        let button = NSPopUpButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setContentCompressionResistancePriority(.fittingSizeCompression, for: .horizontal)
        button.setContentHuggingPriority(.fittingSizeCompression, for: .horizontal)
        return button
    }()
    
    private lazy var dimensionsPopUpButton: NSPopUpButton = {
        let button = NSPopUpButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setContentCompressionResistancePriority(.fittingSizeCompression, for: .horizontal)
        button.setContentHuggingPriority(.fittingSizeCompression, for: .horizontal)
        return button
    }()
    
    private let stackView: NSStackView = {
        let view = NSStackView()
        view.distribution = .fillEqually
        view.orientation = .vertical
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
        titlePosition = .noTitle
        addSubview(stackView)
        
        stackView.addArrangedSubview(dimensionsPopUpButton)
        stackView.addArrangedSubview(audioTrackPopUpButton)
        
        stackView.addArrangedSubview(startTimeTextField)
        stackView.addArrangedSubview(endTimeTextField)
        
        let padding = CGFloat(12)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: padding),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -padding),
        ])
    }
    
    private func bind() {
        disposeBag.insert([
            
            viewModel.audioTrackNames.drive(onNext: { [weak self] in
                guard let self = self else { return }
                self.setupPopupButtoon(self.audioTrackPopUpButton, $0)
            }),
            
            viewModel.dismensionNames.drive(onNext: { [weak self] in
                guard let self = self else { return }
                self.setupPopupButtoon(self.dimensionsPopUpButton, $0)
            }),
            
            viewModel.startTimeTextDriver.drive(startTimeTextField.rx.stringValue),
            viewModel.startTimeTextPlaceholderDriver.drive(startTimeTextField.rx.placeholderString),
            viewModel.endTimeTextDriver.drive(endTimeTextField.rx.stringValue),
            viewModel.endTimeTextPlaceholderDriver.drive(endTimeTextField.rx.placeholderString),
            
            startTimeTextField.rx.controlEvent.withLatestFrom(startTimeTextField.rx.text).subscribe(viewModel.startTimeTextBinder),
            endTimeTextField.rx.controlEvent.withLatestFrom(endTimeTextField.rx.text).subscribe(viewModel.endTimeTextBinder),
            viewModel.currentAudioTrackIndex.drive(audioTrackPopUpButton.rx.selectedIndex),
            audioTrackPopUpButton.rx.selectedIndex.bind(to: viewModel.currentAudioTrackIndexBinder),
        ])
    }
    
    private func setupPopupButtoon(_ button: NSPopUpButton, _ names: [String]) {
        guard !names.isEmpty else { return }
        button.removeAllItems()
        button.addItems(withTitles: names)
    }
}
