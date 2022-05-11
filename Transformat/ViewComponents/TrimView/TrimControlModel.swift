//
//  TrimControlModel.swift
//  Transformat
//
//  Created by QIU DU on 3/5/22.
//

import RxCocoa
import RxSwift
import ffmpegkit
import VLCKit

final class TrimControlModel {
    
    let frame: Driver<NSRect>
    
    let relativeCurrentPosition: Driver<CGFloat>
    
    let startTimePositionRatio: Driver<CGFloat>
    let endTimePositionRatio: Driver<CGFloat>
    
    let images: Driver<[Int: NSImage]>
    
    private let mediaPlayer: VLCMediaPlayer
    
    private let mediaPlayerRelativeCurrentPositionRelay = BehaviorRelay<CGFloat>(value: Constants.buttonWidth)
    
    private let relativeCurrentPositionRatioRelay = BehaviorRelay<CGFloat>(value: .zero)
    
    private let startTimePositionRatioRelay = BehaviorRelay<CGFloat>(value: .zero)
    private let startTimePositionRatioBinderRelay = BehaviorRelay<CGFloat>(value: .zero)
    private let endTimePositionRatioRelay = BehaviorRelay<CGFloat>(value: 1)
    private let endTimePositionRatioBinderRelay = BehaviorRelay<CGFloat>(value: 1)
    
    private let boundsRelay = BehaviorRelay<NSRect>(value: .zero)
    private let frameRelay = BehaviorRelay<NSRect>(value: .zero)
    
    private let thumbnailsRelay = BehaviorRelay<[Int: NSImage]>(value: [:])
    
    private let disposeBag = DisposeBag()
    
    init(mediaPlayer: VLCMediaPlayer, mediaPlayerDelegator: MediaPlayerDelegator, scheduler: MainScheduler = .instance) {
        self.mediaPlayer = mediaPlayer
        
        frame = Driver.combineLatest(
            startTimePositionRatioBinderRelay.asDriver(),
            endTimePositionRatioBinderRelay.asDriver(),
            boundsRelay.asDriver().distinctUntilChanged())
        .map { startTimeRatio, endTimeRatio, bounds -> NSRect in
            let rect = NSRect(
                x: bounds.minX + startTimeRatio * (bounds.width - 2 * Constants.buttonWidth),
                y: bounds.minY,
                width: (endTimeRatio - startTimeRatio) * (bounds.width - 2 * Constants.buttonWidth) + 2 * Constants.buttonWidth,
                height: bounds.height)
            return rect
        }
        .distinctUntilChanged()
        
        startTimePositionRatio = startTimePositionRatioRelay.asDriver()
        endTimePositionRatio = endTimePositionRatioRelay.asDriver()
        
        let relativeCurrentRatioToPosition = Driver.combineLatest(
            relativeCurrentPositionRatioRelay.asDriver(),
            frameRelay.asDriver())
            .map { ratio, frame -> CGFloat in
                let position = (frame.width - 2 * Constants.buttonWidth) * ratio + Constants.buttonWidth
                return position
            }
        
        relativeCurrentPosition = Driver.merge(
            relativeCurrentRatioToPosition,
            mediaPlayerRelativeCurrentPositionRelay.asDriver())
        
        let absoluteCurrentPositionRatio = Driver.combineLatest(
            mediaPlayerDelegator.stateChangedDriver.map { $0.isPlaying }.filter { $0 == true }.asObservable().take(1).asDriver(onErrorJustReturn: false),
            startTimePositionRatioBinderRelay.asDriver().distinctUntilChanged(),
            endTimePositionRatioBinderRelay.asDriver().distinctUntilChanged(),
            relativeCurrentPositionRatioRelay.asDriver())
            .map { _, startTimePositionRatio, endTimePositionRatio, relativeCurrentPositionRatio -> CGFloat in
                let absoluteCurrentPositionRatio = startTimePositionRatio + (endTimePositionRatio - startTimePositionRatio) * relativeCurrentPositionRatio
                return absoluteCurrentPositionRatio
            }
            .map { Float($0) }
        
        Driver.combineLatest(
            boundsRelay.asDriver(),
            startTimePositionRatioBinderRelay.asDriver().distinctUntilChanged(),
            endTimePositionRatioBinderRelay.asDriver().distinctUntilChanged())
        .map { bounds, startTimeRatio, endTimeRatio -> NSRect in
            let rect = NSRect(
                x: bounds.minX + startTimeRatio * (bounds.width - 2 * Constants.buttonWidth),
                y: bounds.minY,
                width: (endTimeRatio - startTimeRatio) * (bounds.width - 2 * Constants.buttonWidth) + 2 * Constants.buttonWidth,
                height: bounds.height)
            return rect
        }
        .drive(frameRelay)
        .disposed(by: disposeBag)
        
        images = thumbnailsRelay.asDriver()
        
        disposeBag.insert([
            boundsRelay.bind(to: frameRelay),
            startTimePositionRatioRelay.bind(to: startTimePositionRatioBinderRelay),
            endTimePositionRatioRelay.bind(to: endTimePositionRatioBinderRelay),
            absoluteCurrentPositionRatio.drive(mediaPlayer.rx.position),
        ])
    }
    
    func loadThumbnails(_ media: VLCMedia) {
        let thumbnails = FFmpegKit.thumbnails(media: media, count: 15)
        thumbnailsRelay.accept(thumbnails)
    }
    
    private var wasPlaying = false
    
    func indicatorMoved(x: CGFloat, type: NSEvent.EventType) {
        if type == .leftMouseDown {
            wasPlaying = mediaPlayer.isPlaying
            if mediaPlayer.isPlaying {
                mediaPlayer.pause()
            }
        } else if type == .leftMouseUp {
            if wasPlaying {
                mediaPlayer.play()
            }
        }
        
        let rect = frameRelay.value
        let range = Constants.buttonWidth...(rect.width - Constants.buttonWidth)
        let clampedX = x.clamped(to: range)
        let ratio = ((clampedX - Constants.buttonWidth) / (rect.width - Constants.buttonWidth * 2)).clamped(to: .zero...1.0)
        relativeCurrentPositionRatioRelay.accept(ratio)
    }
    
    func startTimeButtonMoved(x: CGFloat) {
        if mediaPlayer.canPause {
            mediaPlayer.pause()
        }
        
        let rect = frameRelay.value
        let range = boundsRelay.value.minX...(rect.maxX - Constants.buttonWidth * 2)
        let clampedX = x.clamped(to: range)
        let ratio = (clampedX / (boundsRelay.value.width - Constants.buttonWidth * 2)).clamped(to: .zero...1.0)
        startTimePositionRatioRelay.accept(ratio)
        relativeCurrentPositionRatioRelay.accept(.zero)
    }
    
    func endTimeButtonMoved(x: CGFloat) {
        if mediaPlayer.canPause {
            mediaPlayer.pause()
        }
        
        let rect = frameRelay.value
        let range = (rect.minX + Constants.buttonWidth * 2)...boundsRelay.value.maxX
        let clampedX = x.clamped(to: range)
        let ratio = ((clampedX - Constants.buttonWidth * 2) / (boundsRelay.value.width - Constants.buttonWidth * 2)).clamped(to: .zero...1.0)
        endTimePositionRatioRelay.accept(ratio)
        relativeCurrentPositionRatioRelay.accept(1.0)
    }
    
    func updateCurrentPositionRatio(_ ratio: CGFloat) {
        let startRatio = startTimePositionRatioBinderRelay.value
        let endRatio = endTimePositionRatioBinderRelay.value
        guard ratio > endRatio else {
            let width = endRatio - startRatio
            let mediaPlayerRelativeCurrentPositionRatio: CGFloat
            if width == .zero {
                mediaPlayerRelativeCurrentPositionRatio = .zero
            } else {
                mediaPlayerRelativeCurrentPositionRatio = ((ratio - startRatio) / width).clamped(to: .zero...1.0)
            }
            let position = (frameRelay.value.width - 2 * Constants.buttonWidth) * mediaPlayerRelativeCurrentPositionRatio + Constants.buttonWidth
            mediaPlayerRelativeCurrentPositionRelay.accept(position)
            return
        }
        relativeCurrentPositionRatioRelay.accept(.zero)
    }
}

private extension TrimControlModel {
    
    static func convertToRatio(_ bounds: NSRect, _ position: CGFloat) -> CGFloat {
        let minX = bounds.minX + Constants.buttonWidth
        let maxX = bounds.maxX - Constants.buttonWidth
        let x = position - minX
        let width = maxX - minX
        let ratio = x / width
        return ratio
    }
    
    static func width(startTimePositionRatio: CGFloat, endTimePositionRatio: CGFloat, bounds: NSRect, frame: NSRect) -> CGFloat {
        let validWidth = bounds.width - Constants.buttonWidth * 2
        return validWidth * (endTimePositionRatio - startTimePositionRatio) + Constants.buttonWidth * 2
    }
}

extension TrimControlModel {
    
    struct Constants {
        static let buttonNormalColor = NSColor.white
        static let buttonHighlitedColor = NSColor(white: 0.8, alpha: 1)
        static let timelineIndicatorWidth = CGFloat(2)
        static let buttonWidth = CGFloat(10)
        static let timelineIndicatorColor = NSColor.orange
        static let borderColor = Constants.buttonNormalColor
        static let borderWidth = CGFloat(2)
    }
}

extension TrimControlModel {
    
    var boundsBinder: Binder<NSRect> {
        Binder(self) { target, bounds in
            target.boundsRelay.accept(bounds)
        }
    }
    
    var frameBinder: Binder<NSRect> {
        Binder(self) { target, frame in
            target.frameRelay.accept(frame)
        }
    }
    
    var startTimeRatio: Binder<CGFloat?> {
        Binder(self) { target, ratio in
            if let ratio = ratio {
                target.startTimePositionRatioBinderRelay.accept(ratio.clamped(to: .zero...1.0))
                target.relativeCurrentPositionRatioRelay.accept(.zero)
            } else {
                target.startTimePositionRatioBinderRelay.accept(.zero)
            }
        }
    }
    
    var endTimeRatio: Binder<CGFloat?> {
        Binder(self) { target, ratio in
            if let ratio = ratio {
                target.endTimePositionRatioBinderRelay.accept(ratio.clamped(to: .zero...1.0))
                target.relativeCurrentPositionRatioRelay.accept(1.0)
            } else {
                target.endTimePositionRatioBinderRelay.accept(1.0)
            }
        }
    }
}
