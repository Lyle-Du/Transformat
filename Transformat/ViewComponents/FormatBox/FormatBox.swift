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
    
    private let framePerSecondLabel: NSTextField = {
        let label = NSTextField.makeLabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let framePerSecondSlider: TextFieldSlider = {
        let slider = TextFieldSlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
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
    
    private let audioLabelPlaceHolderView: NSView = {
        let view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let audioButtonPlaceHolderView: NSView = {
        let view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private func commonInit() {
        titlePosition = .noTitle
        
        outputPathContainer.addArrangedSubview(outputPathTextField)
        outputPathContainer.addArrangedSubview(outputPathButton)
        addSubview(gridView)
        
        audioLabelPlaceHolderView.addSubview(audioCodecLabel)
        audioCodecLabel.pinEdgesTo(view: audioLabelPlaceHolderView)
        audioLabelPlaceHolderView.addSubview(framePerSecondLabel)
        framePerSecondLabel.pinEdgesTo(view: audioLabelPlaceHolderView)
        
        audioButtonPlaceHolderView.addSubview(audioCodecPopUpBotton)
        audioCodecPopUpBotton.pinEdgesTo(view: audioButtonPlaceHolderView)
        audioButtonPlaceHolderView.addSubview(framePerSecondSlider)
        framePerSecondSlider.pinEdgesTo(view: audioButtonPlaceHolderView)
        framePerSecondSlider.slider.maxValue = 60
        framePerSecondSlider.doubleValue = 24
        framePerSecondSlider.slider.minValue = 1
        
        gridView.addRow(with: [formatLabel, formatsPopUpBotton])
        gridView.addRow(with: [videoCodecLabel, videoCodecPopUpBotton])
        gridView.addRow(with: [audioLabelPlaceHolderView, audioButtonPlaceHolderView])
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
        framePerSecondSlider.stringFormat = FormatBoxModel.Constants.framePerSecondFormat
        
        disposeBag.insert([
            
            viewModel.selectedMediaType.drive(onNext: { [weak self] type in
                guard let self = self else { return }
                let isImageType = type == .image
                self.videoCodecLabel.isHidden = isImageType
                self.videoCodecPopUpBotton.isHidden = isImageType
                self.audioCodecLabel.isHidden = isImageType
                self.audioCodecPopUpBotton.isHidden = isImageType
                
                self.framePerSecondLabel.isHidden = !isImageType
                self.framePerSecondSlider.isHidden = !isImageType
            }),
            
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
            viewModel.outputPath.drive(outputPathTextField.rx.toolTip),
            
            viewModel.selectedFormatIndex.drive(formatsPopUpBotton.rx.selectedIndex),
            formatsPopUpBotton.rx.selectedIndex.bind(to: viewModel.selectedIndexBinder),
            
            viewModel.selectedVideoCodecIndex.drive(videoCodecPopUpBotton.rx.selectedIndex),
            videoCodecPopUpBotton.rx.selectedIndex.bind(to: viewModel.selectedVideoCodecIndexBinder),
            
            viewModel.selectedAudioCodecIndex.drive(audioCodecPopUpBotton.rx.selectedIndex),
            audioCodecPopUpBotton.rx.selectedIndex.bind(to: viewModel.selectedAudioCodecIndexBinder),
            
            viewModel.framePerSecondTextDriver.drive(framePerSecondLabel.rx.stringValue),
            viewModel.framePerSecondDriver.drive(framePerSecondSlider.valueBinder),
            viewModel.framePerSecondSliderRange.drive(onNext: { [weak self] bound in
                guard let self = self else { return }
                self.framePerSecondSlider.slider.minValue = bound.lowerBound
                self.framePerSecondSlider.slider.maxValue = bound.upperBound
            }),
            framePerSecondSlider.value.drive(viewModel.framePerSecondBinder),
        ])
    }
    
    private func setupPopupButtoon(_ button: NSPopUpButton, _ names: [String]) {
        button.removeAllItems()
        button.addItems(withTitles: names)
    }
}
