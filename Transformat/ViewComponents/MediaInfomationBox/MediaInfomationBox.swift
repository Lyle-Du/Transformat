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
    
    private let gridView: NSGridView = {
        let gridView = NSGridView()
        gridView.translatesAutoresizingMaskIntoConstraints = false
        return gridView
    }()
    
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
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private let dimensionsLabel: NSTextField = {
        let field = NSTextField.makeLabel()
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()
    
    private let audioTrackLabel: NSTextField = {
        let field = NSTextField.makeLabel()
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()
    
    private let timeLabel: NSTextField = {
        let field = NSTextField.makeLabel()
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()
    
    let timeFieldsContainer: NSStackView = {
        let stackView = NSStackView()
        stackView.orientation = .horizontal
        stackView.distribution = .equalCentering
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.setContentHuggingPriority(.fittingSizeCompression, for: .horizontal)
        stackView.setContentCompressionResistancePriority(.fittingSizeCompression, for: .horizontal)
        return stackView
    }()
    
    let timeDashLabel: NSTextField = {
        let label = NSTextField.makeLabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.stringValue = "-"
        label.setContentHuggingPriority(.fittingSizeCompression, for: .horizontal)
        label.setContentCompressionResistancePriority(.fittingSizeCompression, for: .horizontal)
        return label
    }()
    
    private func commonInit() {
        titlePosition = .noTitle
        
        addSubview(gridView)
        
        timeFieldsContainer.addArrangedSubview(startTimeTextField)
        timeFieldsContainer.addArrangedSubview(timeDashLabel)
        timeFieldsContainer.addArrangedSubview(endTimeTextField)
        
        gridView.addRow(with: [dimensionsLabel, dimensionsPopUpButton])
        gridView.addRow(with: [audioTrackLabel, audioTrackPopUpButton])
        gridView.addRow(with: [timeLabel, timeFieldsContainer])
        
        gridView.pinEdgesTo(view: self, padding: 12)
        
        NSLayoutConstraint.activate([
            startTimeTextField.widthAnchor.constraint(greaterThanOrEqualToConstant: 120),
            endTimeTextField.widthAnchor.constraint(greaterThanOrEqualToConstant: 120),
            timeDashLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 10),
        ])
    }
    
    
    private func bind() {
        dimensionsLabel.stringValue = viewModel.dimensionsLabel
        audioTrackLabel.stringValue = viewModel.audioTrackLabel
        timeLabel.stringValue = viewModel.timeLabel
        
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
            
            startTimeTextField.rx.didEndEditing.withLatestFrom(viewModel.startTimeTextDriver.mapToOptional()).subscribe(viewModel.startTimeTextBinder),
            endTimeTextField.rx.didEndEditing.withLatestFrom(viewModel.endTimeTextDriver.mapToOptional()).subscribe(viewModel.endTimeTextBinder),
            
            viewModel.currentAudioTrackIndex.drive(audioTrackPopUpButton.rx.selectedIndex),
            viewModel.currentDimensionsIndex.drive(dimensionsPopUpButton.rx.selectedIndex),
            audioTrackPopUpButton.rx.selectedIndex.bind(to: viewModel.currentAudioTrackIndexBinder),
            dimensionsPopUpButton.rx.selectedIndex.bind(to: viewModel.currentDimensionsIndexBinder),
        ])
    }
    
    private func setupPopupButtoon(_ button: NSPopUpButton, _ names: [String]) {
        guard !names.isEmpty else { return }
        button.removeAllItems()
        button.addItems(withTitles: names)
    }
}
