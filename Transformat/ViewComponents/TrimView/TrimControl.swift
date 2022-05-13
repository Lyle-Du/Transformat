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
    
    private let topBorder: NSView = {
        return makeBorder()
    }()

    private let bottomBorder: NSView = {
        return makeBorder()
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
        trackerView.addSubview(thumbnailsContainer)
        trackerView.addSubview(trimView)
        trackerView.pinEdgesTo(view: self)
        trimView.addSubview(timelineIndicator)
        trimView.addSubview(topBorder)
        trimView.addSubview(bottomBorder)
        trimView.addSubview(startTimeButton)
        trimView.addSubview(endTimeButton)
        
        NSLayoutConstraint.activate([
            topBorder.topAnchor.constraint(equalTo: trimView.topAnchor),
            topBorder.heightAnchor.constraint(equalToConstant: TrimControlModel.Constants.borderWidth),
            topBorder.leadingAnchor.constraint(equalTo: trimView.leadingAnchor),
            topBorder.trailingAnchor.constraint(equalTo: trimView.trailingAnchor),
            
            bottomBorder.bottomAnchor.constraint(equalTo: trimView.bottomAnchor),
            bottomBorder.heightAnchor.constraint(equalToConstant: TrimControlModel.Constants.borderWidth),
            bottomBorder.leadingAnchor.constraint(equalTo: trimView.leadingAnchor),
            bottomBorder.trailingAnchor.constraint(equalTo: trimView.trailingAnchor),
        ])
        
        NSLayoutConstraint.activate([
            thumbnailsContainer.leadingAnchor.constraint(equalTo: trackerView.leadingAnchor, constant: TrimControlModel.Constants.buttonWidth),
            thumbnailsContainer.trailingAnchor.constraint(equalTo: trackerView.trailingAnchor, constant: -TrimControlModel.Constants.buttonWidth),
            thumbnailsContainer.topAnchor.constraint(equalTo: trackerView.topAnchor),
            thumbnailsContainer.bottomAnchor.constraint(equalTo: trackerView.bottomAnchor),
            
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
    
    private let thumbnailsContainer: NSStackView = {
        let stackView = NSStackView()
        stackView.orientation = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = .zero
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
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
        
        viewModel.images.drive(onNext: { [weak self] images in
            guard let self = self else { return }
            self.thumbnailsContainer.removeAllArrangedSubviews()
            images.mapValues { image -> NSImageView in
                let view = NSImageView(image: image)
                view.imageScaling = .scaleProportionallyUpOrDown
                view.setContentCompressionResistancePriority(.fittingSizeCompression, for: .horizontal)
                return view
            }
            .sorted(by: { $0.key < $1.key  })
            .forEach {
                self.thumbnailsContainer.addArrangedSubview($0.1)
            }
        })
        .disposed(by: disposeBag)
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
        super.draw(dirtyRect)
        viewDidDrawOnce.onNext(())
        viewDidDrawOnce.onCompleted()
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
    
    static func makeBorder() -> NSView {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = TrimControlModel.Constants.borderColor.cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }
}


extension NSStackView {
    
    func removeAllArrangedSubviews() {
        
        let removedSubviews = arrangedSubviews.reduce([]) { (allSubviews, subview) -> [NSView] in
            self.removeArrangedSubview(subview)
            return allSubviews + [subview]
        }
        
        // Deactivate all constraints
        NSLayoutConstraint.deactivate(removedSubviews.flatMap({ $0.constraints }))
        
        // Remove the views from self
        removedSubviews.forEach({ $0.removeFromSuperview() })
    }
}
