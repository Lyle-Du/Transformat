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
    
    override func loadView() {
        view = NSView()
    }
    
    var viewModel: MainViewModel! {
        didSet {
            bind()
        }
    }
    
    private let disposeBag = DisposeBag()
    private let cursorShouldHideSubject = PublishSubject<()>()
    private let isCursorHidden = PublishSubject<Bool>()
    
    private let mainContainer: NSStackView = {
        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.spacing = 0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private let playAreaContainer: NSView = {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.black.cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let playerView: VLCVideoView = {
        let view = VLCVideoView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let controlPanelContainer: NSView = {
        let view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let controlPanel: ControlPanel = {
        let panel = ControlPanel()
        panel.translatesAutoresizingMaskIntoConstraints = false
        return panel
    }()
    
    private let optionAreaContainer: NSView = {
        let view = NSVisualEffectView.makeDarkBlurView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
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
        button.bezelStyle = .roundRect
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let clipView: ClipView = {
        let view = ClipView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let panel = NSOpenPanel()
    private let alert = NSAlert()
    
    override func viewDidLoad() {
        setupViews()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(togglePlayerMode),
            name: .playerViewDoubleClicked,
            object: nil)
    }
    
    private func setupViews() {
        view.addSubview(mainContainer)
        mainContainer.pinEdgesTo(view: view)
        addPlayerArea()
        addOptionArea()
    }
    
    @objc private func togglePlayerMode(_ sender: Any) {
        viewModel.togglePlayerMode(
            isWindowFullScreen: isWindowFullScreen,
            window: view.window)
    }
    
    func bind() {
        clipView.viewModel = viewModel.clipViewModel
        controlPanel.viewModel = viewModel.controlPanelViewModel
        mediaInfomationBox.viewModel = viewModel.mediaInfomationBoxModel
        formatBox.viewModel = viewModel.formatBoxModel
        cancelButton.title = viewModel.cancleButtonTitle
        
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
            viewModel.isOptionAreaContainerHidden.drive(optionAreaContainer.rx.isHidden),
            viewModel.isOptionAreaContainerHidden.drive(onNext: { [weak self] isHidden in
                guard let self = self else { return }
                self.view.window?.acceptsMouseMovedEvents = isHidden
                guard isHidden else {
                    self.isCursorHidden.onNext(false)
                    return
                }
                self.cursorShouldHideSubject.onNext(())
            }),
            
            cursorShouldHideSubject.withLatestFrom(viewModel.isOptionAreaContainerHidden)
                .subscribe(onNext: { [weak self] isOptionAreaContainerHidden in
                    guard let self = self, isOptionAreaContainerHidden else { return }
                    self.isCursorHidden.onNext(false)
                }),
            cursorShouldHideSubject.debounce(.seconds(3), scheduler: MainScheduler.instance)
                .withLatestFrom(viewModel.isOptionAreaContainerHidden)
                .subscribe(onNext: { [weak self] isOptionAreaContainerHidden in
                    guard let self = self, isOptionAreaContainerHidden else { return }
                    self.isCursorHidden.onNext(true)
                }),
            
            isCursorHidden.subscribe(onNext: { [weak self] isHidden in
                guard let self = self else { return }
                isHidden ? NSCursor.hide() : NSCursor.unhide()
                let controlPanelContainerAlpha = CGFloat(isHidden && self.optionAreaContainer.isHidden ? 0.4 : 1)
                self.controlPanelContainer.alphaValue = controlPanelContainerAlpha
            }),
            
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
        view.window?.delegate = self
    }
    
    private var isCenteredAtLaunching = false
    
    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.acceptsMouseMovedEvents = true
        guard !isCenteredAtLaunching else { return }
        view.window?.center()
        isCenteredAtLaunching = true
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .playerViewDoubleClicked, object: nil)
    }
    
    //Mark: Fix vlc player size
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

private extension MainViewController {
    
    var isWindowFullScreen: Bool {
        guard let window = view.window else {
            return false
        }
        return window.styleMask.contains(.fullScreen)
    }
}

private extension MainViewController {
    
    func addPlayerArea() {
        mainContainer.addArrangedSubview(playAreaContainer)
        playAreaContainer.addSubview(playerView)
        NSLayoutConstraint.activate([
            playAreaContainer.widthAnchor.constraint(equalTo: mainContainer.widthAnchor),
        ])
        controlPanelContainer.addSubview(controlPanel)
        controlPanel.pinEdgesTo(view: controlPanelContainer, padding: 8)
        playAreaContainer.addSubview(controlPanelContainer)
        NSLayoutConstraint.activate([
            playerView.centerXAnchor.constraint(equalTo: playAreaContainer.centerXAnchor),
            playerView.topAnchor.constraint(equalTo: playAreaContainer.topAnchor),
            playerView.leadingAnchor.constraint(equalTo: playAreaContainer.leadingAnchor),
            playerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 400),
            playerView.widthAnchor.constraint(greaterThanOrEqualToConstant: 600),
        ])
        
        NSLayoutConstraint.activate([
            controlPanelContainer.leadingAnchor.constraint(equalTo: playAreaContainer.leadingAnchor),
            controlPanelContainer.trailingAnchor.constraint(equalTo: playAreaContainer.trailingAnchor),
            controlPanelContainer.topAnchor.constraint(equalTo: playerView.bottomAnchor),
            controlPanelContainer.heightAnchor.constraint(equalToConstant: 60),
            controlPanelContainer.bottomAnchor.constraint(equalTo: playAreaContainer.bottomAnchor),
        ])
    }
    
    func addOptionArea() {
        mainContainer.addArrangedSubview(optionAreaContainer)
        
        NSLayoutConstraint.activate([
            optionAreaContainer.widthAnchor.constraint(equalTo: mainContainer.widthAnchor)
        ])
        
        exportButton.addSubview(cancelButton)
        NSLayoutConstraint.activate([
            cancelButton.leadingAnchor.constraint(equalTo: exportButton.leadingAnchor, constant: 4),
            cancelButton.trailingAnchor.constraint(equalTo: exportButton.trailingAnchor, constant: -4),
            cancelButton.heightAnchor.constraint(lessThanOrEqualToConstant: 30),
            cancelButton.bottomAnchor.constraint(equalTo: exportButton.bottomAnchor, constant: -4),
        ])
        
        boxContainer.addArrangedSubview(mediaInfomationBox)
        boxContainer.addArrangedSubview(formatBox)
        optionAreaContainer.addSubview(importButton)
        optionAreaContainer.addSubview(exportButton)
        optionAreaContainer.addSubview(clipView)
        optionAreaContainer.addSubview(boxContainer)
        
        NSLayoutConstraint.activate([
            importButton.leadingAnchor.constraint(equalTo: optionAreaContainer.leadingAnchor, constant: 12),
            importButton.topAnchor.constraint(equalTo: clipView.topAnchor),
            importButton.bottomAnchor.constraint(equalTo: optionAreaContainer.bottomAnchor, constant: -12),
            importButton.widthAnchor.constraint(equalToConstant: 120),
        ])
        
        NSLayoutConstraint.activate([
            exportButton.trailingAnchor.constraint(equalTo: optionAreaContainer.trailingAnchor, constant: -12),
            exportButton.topAnchor.constraint(equalTo: clipView.topAnchor),
            exportButton.bottomAnchor.constraint(equalTo: optionAreaContainer.bottomAnchor, constant: -12),
            exportButton.widthAnchor.constraint(equalToConstant: 120),
        ])
        
        NSLayoutConstraint.activate([
            clipView.leadingAnchor.constraint(equalTo: importButton.trailingAnchor, constant: 12),
            clipView.trailingAnchor.constraint(equalTo: exportButton.leadingAnchor, constant: -12),
            clipView.topAnchor.constraint(equalTo: controlPanelContainer.bottomAnchor, constant: 12),
            clipView.heightAnchor.constraint(equalToConstant: 50),
        ])
        
        NSLayoutConstraint.activate([
            boxContainer.leadingAnchor.constraint(equalTo: importButton.trailingAnchor, constant: 12),
            boxContainer.trailingAnchor.constraint(equalTo: exportButton.leadingAnchor, constant: -12),
            boxContainer.centerXAnchor.constraint(equalTo: optionAreaContainer.centerXAnchor),
            boxContainer.topAnchor.constraint(equalTo: clipView.bottomAnchor, constant: 4),
            boxContainer.bottomAnchor.constraint(equalTo: optionAreaContainer.bottomAnchor, constant: -12),
        ])
        
        NSLayoutConstraint.activate([
            mediaInfomationBox.widthAnchor.constraint(equalTo: formatBox.widthAnchor),
        ])
    }
}

extension MainViewController {
    
    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        let point = event.locationInWindow
        guard playAreaContainer.hitTest(point) != nil, event.clickCount == 2 else { return }
        NotificationCenter.default.post(name: .playerViewDoubleClicked, object: self)
    }
    
    override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        guard isWindowFullScreen, optionAreaContainer.isHidden else { return }
        cursorShouldHideSubject.onNext(())
    }
}

extension NSNotification.Name {
    static let playerViewDoubleClicked = NSNotification.Name(rawValue: "playerViewDoubleClicked")
}

extension MainViewController: NSWindowDelegate {
    
    func windowDidExitFullScreen(_ notification: Notification) {
        viewModel.setPlayerMode(false)
    }
}
