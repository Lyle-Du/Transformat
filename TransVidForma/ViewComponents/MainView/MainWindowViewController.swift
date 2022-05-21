//
//  MainWindowViewController.swift
//  TransVid Forma
//
//  Created by QIU DU on 21/5/22.
//  Copyright © 2022 Qiu Du. All rights reserved.
//

import Cocoa

import RxCocoa
import RxSwift

final class MainWindowViewController: NSWindowController {
    
    private let viewModel = MainWindowViewModel()
    
    private let disposeBag = DisposeBag()
    
    private let pinButton: ImageButton = {
        let button = ImageButton()
        button.padding = 4
        button.image = NSImage(named: "unpin")
        button.image?.isTemplate = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override func windowDidLoad() {
        super.windowDidLoad()
        guard
            let window = window,
            let titleBarView = window.standardWindowButton(.closeButton)?.superview else
        {
            return
        }
        
        titleBarView.addSubview(pinButton)
        NSLayoutConstraint.activate([
            pinButton.widthAnchor.constraint(equalToConstant: 24),
            pinButton.widthAnchor.constraint(equalTo: pinButton.heightAnchor),
            pinButton.topAnchor.constraint(equalTo: titleBarView.topAnchor),
            pinButton.centerYAnchor.constraint(equalTo: titleBarView.centerYAnchor),
            pinButton.trailingAnchor.constraint(equalTo: titleBarView.trailingAnchor, constant: -4),
        ])
        
        bind()
    }
    
    private func bind() {
        disposeBag.insert([
            pinButton.rx.tap.subscribe(onNext: { [weak self] _ in
                self?.viewModel.togglePinButton()
            }),
            
            viewModel.isPinned.drive(onNext: { [weak self] isPinned in
                guard let self = self else { return }
                self.pinButton.image = NSImage(named: isPinned ? Constants.pinImageName : Constants.unpinImageName)
                self.window?.level = isPinned ? .floating : .normal
            }),
        ])
    }
}

private extension MainWindowViewController {
    
    struct Constants {
        static let pinImageName = "pin"
        static let unpinImageName = "unpin"
    }
}
