//
//  ViewController.swift
//  Transformat
//
//  Created by QIU DU on 18/4/22.
//

import Cocoa

import ffmpegkit
import RxSwift
import VLCKit

final class MainViewController: NSViewController {
    
    private let viewModel: MainViewModel = MainViewModel()
    
    private let disposeBag = DisposeBag()
    
    private let progressView: ProgressView = {
        let progressView = ProgressView()
        progressView.translatesAutoresizingMaskIntoConstraints = false
        return progressView
    }()
    
    private let playerView: VLCVideoView = {
        let view = VLCVideoView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let controlPanelContainer: NSVisualEffectView = {
        let view = NSVisualEffectView()
        view.blendingMode = .withinWindow
        view.material = .ultraDark
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let controlPanel: ControlPanel = {
        let panel = ControlPanel()
        panel.translatesAutoresizingMaskIntoConstraints = false
        return panel
    }()
    
    private let boxContainer: NSStackView = {
        let stackView = NSStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.distribution = .fillEqually
        return stackView
    }()
    
    private let mediaInfomationBox: MediaInfomationBox = {
        let box = MediaInfomationBox()
        box.translatesAutoresizingMaskIntoConstraints = false
        return box
    }()
    
    private let formatBox: FormatBox = {
        let box = FormatBox()
        box.translatesAutoresizingMaskIntoConstraints = false
        return box
    }()
    
    private let importButton: ProgressButton = {
        let button = ProgressButton()
        button.font = .systemFont(ofSize: 16)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let exportButton: ProgressButton = {
        let button = ProgressButton()
        button.font = .systemFont(ofSize: 16)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let cancelButton: NSButton = {
        let button = NSButton()
        button.isBordered = false
        button.wantsLayer = true
        button.layer?.backgroundColor = NSColor.red.cgColor
        button.layer?.cornerRadius = 4
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let panel = NSOpenPanel()
    private let alert = NSAlert()
    
    override func viewDidLoad() {
        setupViews()
        bind()
    }
    
    func bind() {
        controlPanel.viewModel = viewModel.controlPanelViewModel
        mediaInfomationBox.viewModel = viewModel.mediaInfomationBoxModel
        formatBox.viewModel = viewModel.formatBoxModel
        
        let pstyle = NSMutableParagraphStyle()
        pstyle.alignment = .center
        let attributedTitle = NSAttributedString(
            string: viewModel.cancleButtonTitle,
            attributes: [ NSAttributedString.Key.foregroundColor : NSColor.white, NSAttributedString.Key.paragraphStyle : pstyle ])
        cancelButton.attributedTitle = attributedTitle
        
        alert.messageText = viewModel.cancelAlert.messageText
        alert.informativeText = viewModel.cancelAlert.informativeText
        alert.alertStyle = viewModel.cancelAlert.alertStyle
        alert.addButton(withTitle: viewModel.cancelAlert.okButtonTitle)
        alert.addButton(withTitle: viewModel.cancelAlert.cancelButtonTitle)
        
        disposeBag.insert([
            cancelButton.rx.tap.subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                guard let window = self.view.window else { return }
                self.alert.beginSheetModal(for: window) { [weak self] returnCode in
                    if returnCode == .alertFirstButtonReturn {
                        self?.viewModel.cancel()
                    }
                }
            }),
            
            viewModel.isExportDisabled.map { !$0 }.drive(exportButton.rx.isEnabled),
            viewModel.isImportExportDisabled.map { !$0 }.drive(exportButton.rx.isEnabled),
            viewModel.isImportExportDisabled.map { !$0 }.drive(importButton.rx.isEnabled),
            viewModel.progressPercentage.drive(progressView.rx.progressBinder),
            viewModel.progressPercentage.drive(importButton.rx.progressBinder),
            viewModel.progressPercentage.drive(exportButton.rx.progressBinder),
            
            viewModel.importButtonTitle.drive(importButton.rx.title),
            viewModel.exportButtonTitle.drive(exportButton.rx.title),
            
            importButton.rx.tap.subscribe(onNext: { [weak self] in
                self?.viewModel.importButtonClicked()
            }),
            
            exportButton.rx.tap.subscribe(onNext: { [weak self] in
                self?.viewModel.exportButtonClicked()
            }),
            
            viewModel.isCancelButtonHidden.drive(cancelButton.rx.isHidden),
            
            // Fix player view size
            viewModel.resize.subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.viewModel.mediaPlayer.drawable = nil
                self.viewModel.mediaPlayer.drawable = self.playerView
                self.fixedFirstTimeInvalidSize = false
                self.fixFirstTimeInvalidSize(view: self.playerView)
            }),
        ])
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        viewModel.mediaPlayer.drawable = nil
        viewModel.mediaPlayer.drawable = playerView
    }
    
    override func viewDidDisappear() {
        super.viewDidDisappear()
        viewModel.mediaPlayer.pause()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        view.window?.title = viewModel.windowTitle
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    private func setupViews() {
        view.addSubview(importButton)
        view.addSubview(exportButton)
        exportButton.addSubview(cancelButton)
        view.addSubview(playerView)
        
        view.addSubview(controlPanelContainer)
        controlPanelContainer.addSubview(controlPanel)
        controlPanel.pinEdgesTo(view: controlPanelContainer, padding: 8)
        
        view.addSubview(boxContainer)
        view.addSubview(mediaInfomationBox)
        view.addSubview(formatBox)
        boxContainer.addArrangedSubview(mediaInfomationBox)
        boxContainer.addArrangedSubview(formatBox)
        
        view.addSubview(progressView)
        
        NSLayoutConstraint.activate([
            cancelButton.leadingAnchor.constraint(equalTo: exportButton.leadingAnchor, constant: 4),
            cancelButton.trailingAnchor.constraint(equalTo: exportButton.trailingAnchor, constant: -4),
            cancelButton.heightAnchor.constraint(lessThanOrEqualToConstant: 30),
            cancelButton.bottomAnchor.constraint(equalTo: exportButton.bottomAnchor, constant: -4),
        ])
        
        NSLayoutConstraint.activate([
            importButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            importButton.topAnchor.constraint(equalTo: boxContainer.topAnchor),
            importButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -12),
            importButton.widthAnchor.constraint(equalToConstant: 120),
        ])
        
        NSLayoutConstraint.activate([
            exportButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            exportButton.topAnchor.constraint(equalTo: boxContainer.topAnchor),
            exportButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -12),
            exportButton.widthAnchor.constraint(equalToConstant: 120),
        ])
        
        NSLayoutConstraint.activate([
            playerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playerView.topAnchor.constraint(equalTo: view.topAnchor),
            playerView.widthAnchor.constraint(equalTo: view.widthAnchor),
            playerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 400),
            playerView.widthAnchor.constraint(greaterThanOrEqualToConstant: 600),
            
            controlPanelContainer.leadingAnchor.constraint(equalTo: playerView.leadingAnchor),
            controlPanelContainer.trailingAnchor.constraint(equalTo: playerView.trailingAnchor),
            controlPanelContainer.topAnchor.constraint(equalTo: playerView.bottomAnchor),
            controlPanelContainer.heightAnchor.constraint(equalToConstant: 60),
            
            boxContainer.leadingAnchor.constraint(equalTo: importButton.trailingAnchor, constant: 12),
            boxContainer.trailingAnchor.constraint(equalTo: exportButton.leadingAnchor, constant: -12),
            boxContainer.topAnchor.constraint(equalTo: controlPanelContainer.bottomAnchor, constant: 12),
            boxContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -12),
            
            mediaInfomationBox.widthAnchor.constraint(equalTo: formatBox.widthAnchor),
        ])
        
        NSLayoutConstraint.activate([
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progressView.topAnchor.constraint(equalTo: controlPanel.bottomAnchor, constant: 8),
            progressView.heightAnchor.constraint(equalToConstant: 2),
        ])
    }
    
    var fixedFirstTimeInvalidSize = false
    
    func fixFirstTimeInvalidSize(view: NSView) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.005) { [weak self] in
            guard
                let self = self,
                !self.fixedFirstTimeInvalidSize else
            {
                return
            }
            
            guard
                self.viewModel.mediaPlayer.hasVideoOut,
                let frame = view.window?.frame else
            {
                self.fixFirstTimeInvalidSize(view: view) // delay
                return
            }
            
            view.setFrameSize(frame.size)
            self.fixedFirstTimeInvalidSize = true
        }
    }
}
