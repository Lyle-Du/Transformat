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
    
    private let playerView: VLCVideoView = {
        let view = VLCVideoView()
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
    
    private let importButton: NSButton = {
        let button = NSButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let exportButton: NSButton = {
        let button = NSButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let panel = NSOpenPanel()
    
    override func viewDidLoad() {
        setupViews()
        bind()
    }
    
    func bind() {
        importButton.title = viewModel.importButtonTitle
        exportButton.title = viewModel.exportButtonTitle
        controlPanel.viewModel = viewModel.controlPanelViewModel
        mediaInfomationBox.viewModel = viewModel.mediaInfomationBoxModel
        
        importButton.rx.tap
            .asDriver()
            .drive(onNext: { [weak self] in
                self?.importButtonClicked()
            })
            .disposed(by: disposeBag)
        
        // Note: This is to fix incorrect video size
        viewModel.stateChangedDriver
            .drive(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.fixedFirstTimeInvalidSize = false
                self.fixFirstTimeInvalidSize(view: self.playerView)
            })
            .disposed(by: disposeBag)
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

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    private func importButtonClicked() {
        viewModel.importButtonClicked()
    }
    
    private func setupViews() {
        view.addSubview(importButton)
        view.addSubview(exportButton)
        view.addSubview(playerView)
        view.addSubview(controlPanel)
        view.addSubview(boxContainer)
        view.addSubview(mediaInfomationBox)
        view.addSubview(formatBox)
        boxContainer.addArrangedSubview(mediaInfomationBox)
        boxContainer.addArrangedSubview(formatBox)
        
        NSLayoutConstraint.activate([
            importButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            importButton.trailingAnchor.constraint(equalTo: playerView.leadingAnchor, constant: -12),
            importButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            importButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -12),
            importButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 150)
        ])
        
        NSLayoutConstraint.activate([
            exportButton.leadingAnchor.constraint(equalTo: playerView.trailingAnchor, constant: 12),
            exportButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            exportButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            exportButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -12),
            exportButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 150),
        ])
        
        NSLayoutConstraint.activate([
            playerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playerView.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            playerView.widthAnchor.constraint(equalTo: playerView.heightAnchor, multiplier: 4 / 3),
            playerView.widthAnchor.constraint(greaterThanOrEqualToConstant: 500),
            
            controlPanel.leadingAnchor.constraint(equalTo: playerView.leadingAnchor, constant: 12),
            controlPanel.trailingAnchor.constraint(equalTo: playerView.trailingAnchor, constant: -12),
            controlPanel.bottomAnchor.constraint(equalTo: playerView.bottomAnchor, constant: -12),
            controlPanel.heightAnchor.constraint(equalToConstant: 36),
            
            boxContainer.leadingAnchor.constraint(equalTo: playerView.leadingAnchor),
            boxContainer.trailingAnchor.constraint(equalTo: playerView.trailingAnchor),
            boxContainer.topAnchor.constraint(equalTo: playerView.bottomAnchor, constant: 12),
            boxContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -12),
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
