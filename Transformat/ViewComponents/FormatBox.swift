//
//  FormatBox.swift
//  Transformat
//
//  Created by QIU DU on 2/5/22.
//

import Cocoa

import RxCocoa
import RxSwift
import VLCKit
import ffmpegkit

final class FormatBox: NSBox {
    
    private let disposeBag = DisposeBag()
    
    private lazy var formatsPopUpBotton: NSPopUpButton = {
        let button = NSPopUpButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setContentCompressionResistancePriority(.fittingSizeCompression, for: .horizontal)
        button.setContentHuggingPriority(.fittingSizeCompression, for: .horizontal)
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
        
        let padding = CGFloat(12)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: padding),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -padding),
        ])
        
        disposeBag.insert([
            formatsPopUpBotton.rx.selectedIndex.bind(to: rx.currentFormatIndex),
        ])
        
        
        formatsPopUpBotton.addItems(withTitles: ["gif", "mp4", "mov"])
    }
    
    private func setupPopupButtoon(_ button: NSPopUpButton, _ names: [String], completion: (Int) -> Void) {
        button.removeAllItems()
        button.addItems(withTitles: names)
        let index = 1.clamped(to: 0...(names.count-1))
        button.selectItem(at: index)
        completion(index)
    }
}

private extension Reactive where Base: FormatBox {
    
    var currentFormatIndex: Binder<Int> {
        Binder(base) { base, index in
//            let currentIndex = index <= 0 ? -1 : Int32(index)
//            base.mediaPlayer?.currentAudioTrackIndex = currentIndex
        }
    }
}
