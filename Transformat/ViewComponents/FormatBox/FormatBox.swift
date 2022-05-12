//
//  FormatBox.swift
//  Transformat
//
//  Created by QIU DU on 2/5/22.
//

import Cocoa

import ffmpegkit
import RxCocoa
import RxSwift
import VLCKit

final class FormatBox: NSBox {
    
    var viewModel: FormatBoxModel! {
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
    
    private let formatLabel: NSTextField = {
        let label = NSTextField.makeLabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let formatsPopUpBotton: NSPopUpButton = {
        let button = NSPopUpButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setContentCompressionResistancePriority(.fittingSizeCompression, for: .horizontal)
        button.setContentHuggingPriority(.fittingSizeCompression, for: .horizontal)
        return button
    }()
    
    private let videoCodecLabel: NSTextField = {
        let label = NSTextField.makeLabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let videoCodecPopUpBotton: NSPopUpButton = {
        let button = NSPopUpButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setContentCompressionResistancePriority(.fittingSizeCompression, for: .horizontal)
        button.setContentHuggingPriority(.fittingSizeCompression, for: .horizontal)
        return button
    }()
    
    private let audioCodecLabel: NSTextField = {
        let label = NSTextField.makeLabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let audioCodecPopUpBotton: NSPopUpButton = {
        let button = NSPopUpButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setContentCompressionResistancePriority(.fittingSizeCompression, for: .horizontal)
        button.setContentHuggingPriority(.fittingSizeCompression, for: .horizontal)
        return button
    }()
    
    private let outputPathTextField: NSTextField = {
        let textField = NSTextField()
        textField.isEditable = false
        textField.isSelectable = true
        textField.lineBreakMode = .byTruncatingHead
        textField.setContentHuggingPriority(.fittingSizeCompression, for: .horizontal)
        textField.setContentCompressionResistancePriority(.fittingSizeCompression, for: .horizontal)
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let outputPathContainer: NSStackView = {
        let statckView = NSStackView()
        statckView.orientation = .horizontal
        statckView.translatesAutoresizingMaskIntoConstraints = false
        return statckView
    }()
    
    private let outputPathLabel: NSTextField = {
        let label = NSTextField.makeLabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let outputPathButton: NSButton = {
        let button = NSButton()
        button.title = ""
        button.bezelStyle = .roundedDisclosure
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
    
    private func commonInit() {
        titlePosition = .noTitle
        
        outputPathContainer.addArrangedSubview(outputPathTextField)
        outputPathContainer.addArrangedSubview(outputPathButton)
        addSubview(gridView)
        
        gridView.addRow(with: [formatLabel, formatsPopUpBotton])
        gridView.addRow(with: [videoCodecLabel, videoCodecPopUpBotton])
        gridView.addRow(with: [audioCodecLabel, audioCodecPopUpBotton])
        gridView.addRow(with: [outputPathLabel, outputPathContainer])
        
        let padding = CGFloat(12)
        NSLayoutConstraint.activate([
            gridView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            gridView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            gridView.topAnchor.constraint(equalTo: topAnchor, constant: padding),
            gridView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -padding),
        ])
    }
    
    func bind() {
        formatLabel.stringValue = viewModel.formatLabel
        formatsPopUpBotton.addItems(withTitles: viewModel.formatTitles)
        videoCodecLabel.stringValue = viewModel.videoCodecLabel
        audioCodecLabel.stringValue = viewModel.audioCodecLabel
        formatsPopUpBotton.addItems(withTitles: viewModel.formatTitles)
        outputPathLabel.stringValue = viewModel.outputPathLabel
        
        disposeBag.insert([
            
            viewModel.videoCodecTitles.drive(onNext: { [weak self] in
                guard let self = self else { return }
                self.setupPopupButtoon(self.videoCodecPopUpBotton, $0)
            }),
            
            viewModel.audioCodecTitles.drive(onNext: { [weak self] in
                guard let self = self else { return }
                self.setupPopupButtoon(self.audioCodecPopUpBotton, $0)
            }),
            
            outputPathButton.rx.tap
                .subscribe(onNext: { [weak self] in
                    self?.viewModel.setOutputPath()
                }),
            
            viewModel.outputPath.drive(outputPathTextField.rx.text),
            
            viewModel.selectedFormatIndex.drive(formatsPopUpBotton.rx.selectedIndex),
            formatsPopUpBotton.rx.selectedIndex.bind(to: viewModel.selectedIndexBinder),
            
            viewModel.selectedVideoCodecIndex.drive(videoCodecPopUpBotton.rx.selectedIndex),
            videoCodecPopUpBotton.rx.selectedIndex.bind(to: viewModel.selectedVideoCodecIndexBinder),
            
            viewModel.selectedAudioCodecIndex.drive(audioCodecPopUpBotton.rx.selectedIndex),
            audioCodecPopUpBotton.rx.selectedIndex.bind(to: viewModel.selectedAudioCodecIndexBinder),
        ])
    }
    
    private func setupPopupButtoon(_ button: NSPopUpButton, _ names: [String]) {
        button.removeAllItems()
        button.addItems(withTitles: names)
    }
}
