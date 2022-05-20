//
//  AudioBox.swift
//  Transformat
//
//  Created by QIU DU on 28/4/22.
//

import Cocoa

import RxCocoa
import RxRelay
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
    
    private let gridView: NSGridView = {
        let gridView = NSGridView()
        gridView.translatesAutoresizingMaskIntoConstraints = false
        return gridView
    }()
    
    private let resolutionLabel: NSTextField = {
        let field = NSTextField.makeLabel()
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()
    
    private lazy var resolutionPopUpButton: NSPopUpButton = {
        let button = NSPopUpButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setContentCompressionResistancePriority(.fittingSizeCompression, for: .horizontal)
        button.setContentHuggingPriority(.fittingSizeCompression, for: .horizontal)
        return button
    }()
    
    private let customResolutionLabel: NSTextField = {
        let field = NSTextField.makeLabel()
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()
    
    private let customResolutionWidthTextField: NSTextField = {
        let textField = NSTextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let customResolutionHeightTextField: NSTextField = {
        let textField = NSTextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let customResolutionFieldsContainer: NSStackView = {
        let stackView = NSStackView()
        stackView.orientation = .horizontal
        stackView.distribution = .equalCentering
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.setContentHuggingPriority(.fittingSizeCompression, for: .horizontal)
        stackView.setContentCompressionResistancePriority(.fittingSizeCompression, for: .horizontal)
        return stackView
    }()
    
    private let audioTrackLabel: NSTextField = {
        let field = NSTextField.makeLabel()
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()
    
    private let audioTrackPopUpButton: NSPopUpButton = {
        let button = NSPopUpButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setContentCompressionResistancePriority(.fittingSizeCompression, for: .horizontal)
        button.setContentHuggingPriority(.fittingSizeCompression, for: .horizontal)
        return button
    }()
    
    private let subtitleLabel: NSTextField = {
        let field = NSTextField.makeLabel()
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()
    
    private let subtitlePopUpButton: NSPopUpButton = {
        let button = NSPopUpButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setContentCompressionResistancePriority(.fittingSizeCompression, for: .horizontal)
        button.setContentHuggingPriority(.fittingSizeCompression, for: .horizontal)
        return button
    }()
    
    private let timeLabel: NSTextField = {
        let field = NSTextField.makeLabel()
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()
    
    private let startTimeTextField: NSTextField = {
        let textField = NSTextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let endTimeTextField: NSTextField = {
        let textField = NSTextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let timeFieldsContainer: NSStackView = {
        let stackView = NSStackView()
        stackView.orientation = .horizontal
        stackView.distribution = .equalCentering
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.setContentHuggingPriority(.fittingSizeCompression, for: .horizontal)
        stackView.setContentCompressionResistancePriority(.fittingSizeCompression, for: .horizontal)
        return stackView
    }()
    
    private let speedLabel: NSTextField = {
        let label = NSTextField.makeLabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let speedSlider: TextFieldSlider = {
        let slider = TextFieldSlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
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
        
        addSubview(gridView)
        
        timeFieldsContainer.addArrangedSubview(startTimeTextField)
        timeFieldsContainer.addArrangedSubview(makeCharLabel("-"))
        timeFieldsContainer.addArrangedSubview(endTimeTextField)
        
        customResolutionFieldsContainer.addArrangedSubview(customResolutionWidthTextField)
        customResolutionFieldsContainer.addArrangedSubview(makeCharLabel("\u{2715}"))
        customResolutionFieldsContainer.addArrangedSubview(customResolutionHeightTextField)
        
        gridView.addRow(with: [resolutionLabel, resolutionPopUpButton])
        gridView.addRow(with: [customResolutionLabel, customResolutionFieldsContainer])
        gridView.addRow(with: [audioTrackLabel, audioTrackPopUpButton])
        gridView.addRow(with: [subtitleLabel, subtitlePopUpButton])
        gridView.addRow(with: [timeLabel, timeFieldsContainer])
        gridView.addRow(with: [speedLabel, speedSlider])
        
        let padding = CGFloat(12)
        NSLayoutConstraint.activate([
            gridView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            gridView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            gridView.topAnchor.constraint(equalTo: topAnchor, constant: padding),
            gridView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -padding),
        ])
        
        NSLayoutConstraint.activate([
            startTimeTextField.widthAnchor.constraint(greaterThanOrEqualToConstant: 120),
            endTimeTextField.widthAnchor.constraint(greaterThanOrEqualToConstant: 120),
        ])
    }
    
    
    private func bind() {
        resolutionLabel.stringValue = viewModel.resolutionLabel
        customResolutionLabel.stringValue = viewModel.customResolutionLabel
        audioTrackLabel.stringValue = viewModel.audioTrackLabel
        subtitleLabel.stringValue = viewModel.subtitleLabel
        timeLabel.stringValue = viewModel.timeLabel
        
        
        
        disposeBag.insert([
            
            viewModel.audioTrackNames.drive(onNext: { [weak self] in
                guard let self = self else { return }
                self.setupPopupButtoon(self.audioTrackPopUpButton, $0)
            }),
            
            viewModel.subtitleNames.drive(onNext: { [weak self] in
                guard let self = self else { return }
                self.setupPopupButtoon(self.subtitlePopUpButton, $0)
            }),
            
            viewModel.resolutionNames.drive(onNext: { [weak self] in
                guard let self = self else { return }
                self.setupPopupButtoon(self.resolutionPopUpButton, $0)
            }),
            
            viewModel.customResolutionWidthText.drive(customResolutionWidthTextField.rx.text),
            viewModel.customResolutionHeightText.drive(customResolutionHeightTextField.rx.text),
            
            customResolutionWidthTextField.rx.text.subscribe(viewModel.customResolutionWidthBinder),
            customResolutionHeightTextField.rx.text.subscribe(viewModel.customResolutionHeightBinder),
            
            viewModel.startTimeTextDriver.drive(startTimeTextField.rx.text),
            viewModel.endTimeTextDriver.drive(endTimeTextField.rx.text),
            
            viewModel.startTimeTextPlaceholderDriver.drive(startTimeTextField.rx.placeholderString),
            viewModel.endTimeTextPlaceholderDriver.drive(endTimeTextField.rx.placeholderString),
            
            startTimeTextField.rx.didEndEditingText.subscribe(viewModel.startTimeTextBinder),
            endTimeTextField.rx.didEndEditingText.subscribe(viewModel.endTimeTextBinder),
            
            viewModel.currentAudioTrackIndex.drive(audioTrackPopUpButton.rx.selectedIndex),
            audioTrackPopUpButton.rx.selectedIndex.bind(to: viewModel.currentAudioTrackIndexBinder),
            
            viewModel.currentSubtitleIndex.drive(subtitlePopUpButton.rx.selectedIndex),
            subtitlePopUpButton.rx.selectedIndex.bind(to: viewModel.currentSubtitleIndexBinder),
            
            viewModel.currentResolutionIndex.drive(resolutionPopUpButton.rx.selectedIndex),
            resolutionPopUpButton.rx.selectedIndex.bind(to: viewModel.currentResolutionIndexBinder),
            
            viewModel.speedSliderRange.drive(speedSlider.range),
            viewModel.speedTextDriver.drive(speedLabel.rx.stringValue),
            viewModel.speedDriver.drive(speedSlider.valueBinder),
            speedSlider.value.drive(viewModel.speedBinder),
        ])
    }
    
    private func setupPopupButtoon(_ button: NSPopUpButton, _ names: [String]) {
        button.removeAllItems()
        button.addItems(withTitles: names)
    }
}

private extension MediaInfomationBox {
    
    private func makeCharLabel(_ char: Character) -> NSTextField {
        let label = NSTextField.makeLabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.stringValue = String(char)
        label.setContentHuggingPriority(.fittingSizeCompression, for: .horizontal)
        label.setContentCompressionResistancePriority(.fittingSizeCompression, for: .horizontal)
        NSLayoutConstraint.activate([
            label.widthAnchor.constraint(greaterThanOrEqualToConstant: 10),
        ])
        return label
    }
}
