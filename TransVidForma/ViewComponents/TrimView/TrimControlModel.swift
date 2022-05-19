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
    
    var canAddClip = false
    
    let dragHint = NSLocalizedString("Hold \"command\" + Drag to shift the trimmed clip.", comment: "")
    
    let frame: Driver<NSRect>
    
    let relativeCurrentPosition: Driver<CGFloat>

    let timePositionRatioRange: Driver<ClosedRange<CGFloat>>
    
    let images: Driver<[Int: NSImage]>
    
    private let mediaPlayer: VLCMediaPlayer
    
    private let mediaPlayerRelativeCurrentPositionRelay = BehaviorRelay<CGFloat>(value: Constants.buttonWidth)
    private let relativeCurrentPositionRatioRelay = BehaviorRelay<CGFloat>(value: .zero)
    
    private let timePositionRatioRangeRelay = BehaviorRelay<ClosedRange<CGFloat>>(value: .zero...1.0)
    private let timePositionRatioRangeBinderRelay = BehaviorRelay<ClosedRange<CGFloat>>(value: .zero...1.0)
    
    private let boundsRelay = BehaviorRelay<NSRect>(value: .zero)
    private let frameRelay = BehaviorRelay<NSRect>(value: .zero)
    
    private let thumbnailsRelay = BehaviorRelay<[Int: NSImage]>(value: [:])
    
    private let disposeBag = DisposeBag()
    
    init(mediaPlayer: VLCMediaPlayer, mediaPlayerDelegator: MediaPlayerDelegator, scheduler: MainScheduler = .instance) {
        self.mediaPlayer = mediaPlayer
        
        frame = Driver.combineLatest(
            timePositionRatioRangeBinderRelay.asDriver(),
            boundsRelay.asDriver().distinctUntilChanged())
        .map { range, bounds -> NSRect in
            let rect = NSRect(
                x: bounds.minX + range.lowerBound * (bounds.width - 2 * Constants.buttonWidth),
                y: bounds.minY,
                width: range.interval * (bounds.width - 2 * Constants.buttonWidth) + 2 * Constants.buttonWidth,
                height: bounds.height)
            return rect
        }
        .distinctUntilChanged()
        
        timePositionRatioRange = timePositionRatioRangeRelay.asDriver()
        
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
            timePositionRatioRangeBinderRelay.asDriver().distinctUntilChanged(),
            relativeCurrentPositionRatioRelay.asDriver())
            .map { _, range, relativeCurrentPositionRatio -> CGFloat in
                let absoluteCurrentPositionRatio = range.lowerBound + range.interval * relativeCurrentPositionRatio
                return absoluteCurrentPositionRatio
            }
            .map { Float($0) }
        
        Driver.combineLatest(
            boundsRelay.asDriver(),
            timePositionRatioRangeBinderRelay.asDriver().distinctUntilChanged())
        .map { bounds, range -> NSRect in
            let rect = NSRect(
                x: bounds.minX + range.lowerBound * (bounds.width - 2 * Constants.buttonWidth),
                y: bounds.minY,
                width: range.interval * (bounds.width - 2 * Constants.buttonWidth) + 2 * Constants.buttonWidth,
                height: bounds.height)
            return rect
        }
        .drive(frameRelay)
        .disposed(by: disposeBag)
        
        images = thumbnailsRelay.asDriver()
        
        disposeBag.insert([
            boundsRelay.bind(to: frameRelay),
            timePositionRatioRangeRelay.bind(to: timePositionRatioRangeBinderRelay),
            absoluteCurrentPositionRatio.drive(mediaPlayer.rx.position),
        ])
    }
    
    func loadThumbnails(_ media: VLCMedia) {
        DispatchQueue.main.async { [weak self] in
            let thumbnails = FFmpegKit.thumbnails(media: media, count: 15)
            self?.thumbnailsRelay.accept(thumbnails)
        }
        timePositionRatioRangeRelay.accept(.zero...1)
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
        guard mediaPlayer.media != nil else { return }
        if mediaPlayer.canPause {
            mediaPlayer.pause()
        }
        
        let rect = frameRelay.value
        let range = boundsRelay.value.minX...(rect.maxX - Constants.buttonWidth * 2)
        let clampedX = x.clamped(to: range)
        let upperBound = timePositionRatioRangeRelay.value.upperBound
        let ratio = (clampedX / (boundsRelay.value.width - Constants.buttonWidth * 2)).clamped(to: .zero...upperBound)
        timePositionRatioRangeRelay.accept(ratio...upperBound)
        relativeCurrentPositionRatioRelay.accept(.zero)
    }
    
    func endTimeButtonMoved(x: CGFloat) {
        guard mediaPlayer.media != nil else { return }
        if mediaPlayer.canPause {
            mediaPlayer.pause()
        }
        
        let rect = frameRelay.value
        let range = (rect.minX + Constants.buttonWidth * 2)...boundsRelay.value.maxX
        let clampedX = x.clamped(to: range)
        let lowerBound = timePositionRatioRangeRelay.value.lowerBound
        let ratio = ((clampedX - Constants.buttonWidth * 2) / (boundsRelay.value.width - Constants.buttonWidth * 2)).clamped(to: lowerBound...1.0)
        timePositionRatioRangeRelay.accept(lowerBound...ratio)
        relativeCurrentPositionRatioRelay.accept(1.0)
    }
    
    func updateCurrentPositionRatio(_ ratio: CGFloat) {
        let startRatio = timePositionRatioRangeBinderRelay.value.lowerBound
        let endRatio = timePositionRatioRangeBinderRelay.value.upperBound
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
    
    func shift(deltaX: CGFloat) {
        guard mediaPlayer.media != nil else { return }
        if mediaPlayer.canPause {
            mediaPlayer.pause()
        }
        let rect = boundsRelay.value
        let range = (rect.minX + Constants.buttonWidth)...(rect.maxX - Constants.buttonWidth)
        let delta = range.interval != .zero ? deltaX / range.interval : .zero
        var lowerBound = timePositionRatioRangeRelay.value.lowerBound + delta
        var upperBound = timePositionRatioRangeRelay.value.upperBound + delta
        let interval = upperBound - lowerBound
        
        if lowerBound < .zero {
            lowerBound = .zero
            upperBound = lowerBound + interval
        }
        
        if upperBound > 1.0 {
            upperBound = 1.0
            lowerBound = upperBound - interval
        }
        timePositionRatioRangeRelay.accept(lowerBound...upperBound)
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
            let upperBound = target.timePositionRatioRangeBinderRelay.value.upperBound
            if let ratio = ratio?.clamped(to: .zero...upperBound) {
                target.timePositionRatioRangeBinderRelay.accept(ratio...upperBound)
                target.relativeCurrentPositionRatioRelay.accept(.zero)
            } else {
                target.timePositionRatioRangeBinderRelay.accept(.zero...upperBound)
            }
        }
    }
    
    var endTimeRatio: Binder<CGFloat?> {
        Binder(self) { target, ratio in
            let lowerBound = target.timePositionRatioRangeBinderRelay.value.lowerBound
            if let ratio = ratio?.clamped(to: lowerBound...1.0) {
                target.timePositionRatioRangeBinderRelay.accept(lowerBound...ratio)
                target.relativeCurrentPositionRatioRelay.accept(1.0)
            } else {
                target.timePositionRatioRangeBinderRelay.accept(lowerBound...1.0)
            }
        }
    }
}
