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
    
    private let formatsPopUpBotton: NSPopUpButton = {
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
        textField.lineBreakMode = .byCharWrapping
        textField.setContentHuggingPriority(.fittingSizeCompression, for: .horizontal)
        textField.setContentCompressionResistancePriority(.fittingSizeCompression, for: .horizontal)
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let outputPathButton: NSButton = {
        let button = NSButton()
        button.title = "location"
        button.translatesAutoresizingMaskIntoConstraints = false
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
        
        stackView.addArrangedSubview(formatsPopUpBotton)
        stackView.addArrangedSubview(outputPathTextField)
        stackView.addArrangedSubview(outputPathButton)
        
        let padding = CGFloat(12)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: padding),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -padding),
        ])
    }
    
    func bind() {
        
        formatsPopUpBotton.addItems(withTitles: viewModel.formatTitles)
        disposeBag.insert([
            outputPathButton.rx.tap
                .subscribe(onNext: { [weak self] in
                    self?.viewModel.setOutputPath()
                }),
            
            viewModel.outputPath.drive(outputPathTextField.rx.text),
            
            viewModel.selectedFormatIndex.drive(formatsPopUpBotton.rx.selectedIndex),
            formatsPopUpBotton.rx.selectedIndex.bind(to: viewModel.selectedIndexBinder),
        ])
    }
}
