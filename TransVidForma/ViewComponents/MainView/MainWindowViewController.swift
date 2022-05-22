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
    
    var viewModel: MainWindowViewModel!
    
    private let disposeBag = DisposeBag()
    
    private let pinButton: ImageButton = {
        let button = ImageButton()
        button.padding = 4
        button.image = NSImage(named: "unpin")
        button.image?.isTemplate = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    func loadWindow(contentViewController: NSViewController) {
        window = NSWindow(contentViewController: contentViewController)
        
        guard
            let window = window,
            let titleBarView = window.standardWindowButton(.closeButton)?.superview else
        {
            return
        }
        
        window.styleMask = [.miniaturizable, .closable, .resizable, .titled]
        
        titleBarView.addSubview(pinButton)
        NSLayoutConstraint.activate([
            pinButton.widthAnchor.constraint(equalToConstant: 24),
            pinButton.widthAnchor.constraint(equalTo: pinButton.heightAnchor),
            pinButton.centerYAnchor.constraint(equalTo: titleBarView.centerYAnchor),
            pinButton.trailingAnchor.constraint(equalTo: titleBarView.trailingAnchor, constant: -4),
        ])
        
        bind()
    }
    
    private func bind() {
        window?.title = viewModel.title
        disposeBag.insert([
            pinButton.rx.tap.subscribe(onNext: { [weak self] _ in
                self?.viewModel.togglePinButton()
            }),
            
            viewModel.isPinned.drive(onNext: { [weak self] isPinned in
                guard let self = self else { return }
                let image = NSImage(named: isPinned ? Constants.pinImageName : Constants.unpinImageName)
                image?.isTemplate = true
                self.pinButton.image = image
                self.window?.level = isPinned ? .floating : .normal
            }),
            
            viewModel.isPinButtonHidden.drive(pinButton.rx.isHidden),
        ])
    }
}

private extension MainWindowViewController {
    
    struct Constants {
        static let pinImageName = "pin"
        static let unpinImageName = "unpin"
    }
}
