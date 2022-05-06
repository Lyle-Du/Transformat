//
//  TrimControl.swift
//  Transformat
//
//  Created by QIU DU on 22/4/22.
//

import Cocoa

import ffmpegkit
import RxCocoa
import RxSwift

final class TrimControl: NSControl {
    
    var viewModel: TrimControlModel! {
        didSet {
            bind()
        }
    }
    
    private let disposeBag = DisposeBag()
    private let trackerViewBounds = BehaviorRelay<NSRect>(value: .zero)
    private let trackerViewFrame = BehaviorRelay<NSRect>(value: .zero)
    
    private let trackerView: NSStackView = {
        let view = NSStackView()
        view.spacing = .zero
        view.distribution = .fillEqually
        view.orientation = .horizontal
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.black.cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let trimView: NSView = {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.clear.cgColor
        view.layer?.borderWidth = TrimControlModel.Constants.borderWidth
        view.layer?.borderColor = TrimControlModel.Constants.borderColor.cgColor
        view.layer?.cornerRadius = CGFloat(TrimControlModel.Constants.buttonWidth * 0.5)
        return view
    }()
    
    private let startTimeButton: TrimButton = {
        let button = TrimButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let endTimeButton: TrimButton = {
        let button = TrimButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let timelineIndicator: NSView = {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = TrimControlModel.Constants.timelineIndicatorColor.cgColor
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
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        layer?.cornerRadius = CGFloat(TrimControlModel.Constants.buttonWidth * 0.5)
        
        addSubview(trackerView)
        trackerView.addSubview(trimView)
        trackerView.pinEdgesTo(view: self)
        
        trimView.addSubview(timelineIndicator)
        trimView.addSubview(startTimeButton)
        trimView.addSubview(endTimeButton)
        
        NSLayoutConstraint.activate([
            startTimeButton.leadingAnchor.constraint(equalTo: trimView.leadingAnchor),
            startTimeButton.widthAnchor.constraint(equalToConstant: TrimControlModel.Constants.buttonWidth),
            startTimeButton.topAnchor.constraint(equalTo: trimView.topAnchor),
            startTimeButton.bottomAnchor.constraint(equalTo: trimView.bottomAnchor),

            endTimeButton.trailingAnchor.constraint(equalTo: trimView.trailingAnchor),
            endTimeButton.widthAnchor.constraint(equalToConstant: TrimControlModel.Constants.buttonWidth),
            endTimeButton.topAnchor.constraint(equalTo: trimView.topAnchor),
            endTimeButton.bottomAnchor.constraint(equalTo: trimView.bottomAnchor),
        ])
    }
    
    private func bind() {
        disposeBag.insert([
            trackerViewBounds.distinctUntilChanged().bind(to: viewModel.boundsBinder),
            trackerViewFrame.distinctUntilChanged().bind(to: viewModel.frameBinder),
            viewModel.frame.drive(trimView.rx.frame),
        ])
        
        if let timelineIndicatorLayer = timelineIndicator.layer {
            let currentPositionInBeginning = Driver.combineLatest(
                viewModel.relativeCurrentPosition,
                viewDidDrawOnce.asDriver(onErrorJustReturn: ()))
                .map(\.0)
            
            Driver.merge(
                currentPositionInBeginning,
                viewModel.relativeCurrentPosition)
            .map {CGFloat($0) - TrimControlModel.Constants.timelineIndicatorWidth / 2 }
            .drive(onNext: {
                timelineIndicatorLayer.position.x = $0
            })
            .disposed(by: disposeBag)
        }
    }
    
    override func layout() {
        super.layout()
        let bounds = trackerView.bounds
        trackerViewBounds.accept(bounds)
        trackerViewFrame.accept(trackerView.frame)
        timelineIndicator.frame = NSRect(
            origin: .zero,
            size: CGSize(width: TrimControlModel.Constants.timelineIndicatorWidth, height: bounds.height))
    }
    
    private let viewDidDrawOnce = PublishSubject<Void>()
    
    override func draw(_ dirtyRect: NSRect) {
        viewDidDrawOnce.onNext(())
        viewDidDrawOnce.onCompleted()
        super.draw(dirtyRect)
    }
}

extension TrimControl {
    
    override func mouseDown(with event: NSEvent) {
        mouseEvent(event)
    }
    
    override func mouseDragged(with event: NSEvent) {
        mouseEvent(event)
    }
    
    override func mouseUp(with event: NSEvent) {
        mouseEvent(event)
    }
    
    private func mouseEvent(_ event: NSEvent) {
        let converted = convert(event.locationInWindow, from: nil).x
        let offset = TrimControlModel.Constants.buttonWidth / 2
        if startTimeButton.isHighlighted {
            viewModel.startTimeButtonMoved(x: converted - offset)
        } else if endTimeButton.isHighlighted {
            viewModel.endTimeButtonMoved(x: converted + offset)
        } else {
            let x = trimView.convert(event.locationInWindow, from: nil).x
            viewModel.indicatorMoved(x: x, type: event.type)
        }
    }
}

private extension TrimControl {
    
    var buttonSize: NSSize {
        NSSize(width: TrimControlModel.Constants.buttonWidth, height: bounds.height)
    }
}
