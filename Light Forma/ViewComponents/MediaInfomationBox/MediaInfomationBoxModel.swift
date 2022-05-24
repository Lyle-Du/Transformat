//
//  AudioBoxModel.swift
//  Transformat
//
//  Created by QIU DU on 5/5/22.
//

import ffmpegkit
import RxCocoa
import RxSwift
import VLCKit

final class MediaInfomationBoxModel {
    
    let mediaPlayer: MediaPlayer
    
    let resolutionLabel = NSLocalizedString("Resolution:", comment: "")
    let customResolutionLabel = NSLocalizedString("Custom Resolution:", comment: "")
    
    let timeLabel = NSLocalizedString("Duration:", comment: "")
    
    let resolutionNames: Driver<[String]>
    let currentResolutionIndex: Driver<Int>
    
    let customResolutionWidthText: Driver<String>
    let customResolutionHeightText: Driver<String>
    
    private let customResolutionWidthRelay = BehaviorRelay<String>(value: "")
    private let customResolutionHeightRelay = BehaviorRelay<String>(value: "")
    
    let timeRatioRange: Driver<ClosedRange<CGFloat>>
    
    let startTimeTextDriver: Driver<String?>
    let startTimeTextPlaceholderDriver: Driver<String?>
    let endTimeTextDriver: Driver<String?>
    let endTimeTextPlaceholderDriver: Driver<String?>
    
    let speedTextDriver: Driver<String>
    let speedDriver: Driver<Double>
    let speedSliderRange: Driver<ClosedRange<Double>>
    
    private let speedSliderRangeRelay = BehaviorRelay<ClosedRange<Double>>(value: 0.1...10)
    private let speedRelay: BehaviorRelay<Double>
    
    private let timeLimitRangeRelay = BehaviorRelay<ClosedRange<TimeInterval>>(value: .zero...(.zero))
    
    fileprivate let startTimeText: Driver<String>
    fileprivate let startTimeTextPlaceholder: Driver<String?>
    fileprivate let endTimeText: Driver<String>
    fileprivate let endTimeTextPlaceholder: Driver<String?>
    
    private let currentResolutionIndexRelay: BehaviorRelay<Int>
    
    fileprivate let startTimeTextRelay: BehaviorRelay<String?> = BehaviorRelay(value: nil)
    private let startTimeTextPlaceholderRelay: BehaviorRelay<String?> = BehaviorRelay(value: nil)
    fileprivate let endTimeTextRelay: BehaviorRelay<String?> = BehaviorRelay(value: nil)
    private let endTimeTextPlaceholderRelay: BehaviorRelay<String?> = BehaviorRelay(value: nil)
    
    private let resolutionsRelay: BehaviorRelay<[MediaResolution]>
    private let resolutionNamesRelay = BehaviorRelay<[String]>(value: [])
    
    private let disposeBag = DisposeBag()
    
    init(mediaPlayer: MediaPlayer, mediaPlayerDelegator: MediaPlayerDelegator) {
        self.mediaPlayer = mediaPlayer
        resolutionNames = resolutionNamesRelay.asDriver()
        
        resolutionsRelay = BehaviorRelay(value: Self.resolutions(media: mediaPlayer.media))
        currentResolutionIndexRelay = BehaviorRelay(value: 0)
        currentResolutionIndex = currentResolutionIndexRelay.asDriver()
        
        speedSliderRange = speedSliderRangeRelay.asDriver()
        speedRelay = BehaviorRelay(value: 1)
        speedDriver = speedRelay.asDriver()
        speedTextDriver = speedDriver.map { String.localizedStringWithFormat(NSLocalizedString("Speed ✕%.2f", comment: ""), $0)
        }
        
        let selectedResolution = currentResolutionIndexRelay
            .asDriver()
            .filter { $0 > 0 }
            .compactMap { [resolutionsRelay] index -> MediaResolution? in
                guard index < resolutionsRelay.value.count else {
                    return nil
                }
                return resolutionsRelay.value[index]
            }
        
        customResolutionWidthText = customResolutionWidthRelay.asDriver()
        customResolutionHeightText = customResolutionHeightRelay.asDriver()
        
        startTimeText = timeLimitRangeRelay.asDriver().map { $0.lowerBound.toTimeString() ?? "" }.distinctUntilChanged()
        startTimeTextPlaceholder = timeLimitRangeRelay.asDriver().map { $0.lowerBound.toTimeString() ?? "" }.distinctUntilChanged()
        endTimeText = timeLimitRangeRelay.asDriver().map { $0.upperBound.toTimeString() ?? "" }.distinctUntilChanged()
        endTimeTextPlaceholder = timeLimitRangeRelay.asDriver().map { $0.upperBound.toTimeString() ?? "" }
        
        startTimeTextDriver = startTimeTextRelay.asDriver()
        startTimeTextPlaceholderDriver = startTimeTextPlaceholderRelay.asDriver()
        endTimeTextDriver = endTimeTextRelay.asDriver()
        endTimeTextPlaceholderDriver = endTimeTextPlaceholderRelay.asDriver()
        
        timeRatioRange = Driver.combineLatest(
            startTimeTextRelay.asDriver(),
            endTimeTextRelay.asDriver(),
            timeLimitRangeRelay.asDriver())
        .map { startTimeText, endTimeText, limitRange in
            let timeInterval = limitRange.interval
            guard
                let startTimeInterval = startTimeText?.toTimeInterval(),
                let endTimeInterval = endTimeText?.toTimeInterval(),
                startTimeInterval <= endTimeInterval,
                timeInterval > .zero else
            {
                return .zero...(1)
            }
            let startRatio = (startTimeInterval - limitRange.lowerBound) / timeInterval
            let endRatio = (endTimeInterval - limitRange.lowerBound) / timeInterval
            return startRatio...endRatio
        }
        .distinctUntilChanged()
        
        disposeBag.insert([
            startTimeText.drive(startTimeTextRelay),
            startTimeTextPlaceholder.drive(startTimeTextPlaceholderRelay),
            endTimeText.drive(endTimeTextRelay),
            endTimeTextPlaceholder.drive(endTimeTextPlaceholderRelay),
            resolutionsRelay.map { $0.map(\.descriptionWithScale) }.bind(to: resolutionNamesRelay),
            
            selectedResolution.map { String($0.width) }.drive(customResolutionWidthRelay),
            selectedResolution.map { String($0.height) }.drive(customResolutionHeightRelay),
            
            speedDriver.drive(onNext: { [weak self] rate in
                self?.mediaPlayer.rate = Float(rate)
            }),
        ])
    }
    
    func setMedia(_ media: VLCMedia) {
        let startTime = FFprobeKit.startTime(media: media) ?? .zero
        let endTime = FFprobeKit.endTime(media: media) ?? .zero
        let timeLimitRange = startTime...endTime
        timeLimitRangeRelay.accept(timeLimitRange)
        
        timeLimitRangeRelay.accept(startTime...endTime)
        timeRatioRangeBinder.onNext(.zero...1)
        
        resolutionsRelay.accept(Self.resolutions(media: media))
        currentResolutionIndexRelay.accept(1)
    }
}

private extension MediaInfomationBoxModel {
    
    static func resolutions(media: VLCMedia?) -> [MediaResolution] {
        guard
            let media = media,
            let dimension = FFprobeKit.resolution(media: media) else
        {
            return []
        }
        let scales = stride(from: 1, to: .zero, by: -0.1).map { CGFloat($0) }
        let resolutions = scales.map { MediaResolution(width: dimension.width, height: dimension.height, scaled: $0) }
        return [.custom] + resolutions
    }
}

extension MediaInfomationBoxModel {
    
    var startTimeTextBinder: Binder<String?> {
        Binder(self) { target, text in
            let text = text?.toTimeInterval()?.toTimeString()
            let startLimit = target.timeLimitRangeRelay.value.lowerBound
            guard let startTimeText = text else {
                if let startTimeLimitText = startLimit.toTimeString() {
                    target.startTimeTextRelay.accept(startTimeLimitText)
                }
                return
            }
            
            guard
                let endTimeIntervalLimit = target.endTimeTextRelay.value?.toTimeInterval(),
                let startTimeInterval = startTimeText.toTimeInterval()?.clamped(to: startLimit...endTimeIntervalLimit),
                let startTimeText = startTimeInterval.toTimeString() else
            {
                if let startTimeLimitText = startLimit.toTimeString() {
                    target.startTimeTextRelay.accept(startTimeLimitText)
                }
                return
            }

            target.startTimeTextRelay.accept(startTimeText)
        }
    }
    
    var endTimeTextBinder: Binder<String?> {
        Binder(self) { target, text in
            let text = text?.toTimeInterval()?.toTimeString()
            let endLimit = target.timeLimitRangeRelay.value.upperBound
            guard let endTimeText = text else {
                if let endTimeLimitText = endLimit.toTimeString() {
                    target.endTimeTextRelay.accept(endTimeLimitText)
                }
                return
            }
            
            guard
                let startTimeIntervalLimit = target.startTimeTextRelay.value?.toTimeInterval(),
                let endTimeInterval = endTimeText.toTimeInterval()?.clamped(to: startTimeIntervalLimit...endLimit),
                let endTimeText = endTimeInterval.toTimeString() else
            {
                if let endTimeLimitText = endLimit.toTimeString() {
                    target.endTimeTextRelay.accept(endTimeLimitText)
                }
                return
            }
            
            target.endTimeTextRelay.accept(endTimeText)
        }
    }
    
    var timeRatioRangeBinder: Binder<ClosedRange<CGFloat>> {
        Binder(self) { target, ratioRange in
            let limitRange = target.timeLimitRangeRelay.value
            let startTimeInterval = limitRange.interval * ratioRange.lowerBound + limitRange.lowerBound
            if let startTimeText = startTimeInterval.toTimeString() {
                target.startTimeTextRelay.accept(startTimeText)
            }
            
            let endTimeInterval = limitRange.interval * ratioRange.upperBound + limitRange.lowerBound
            if let endTimeText = endTimeInterval.toTimeString() {
                target.endTimeTextRelay.accept(endTimeText)
            }
        }
    }
    
    var currentResolutionIndexBinder: Binder<Int> {
        Binder(self) { target, index in
            target.currentResolutionIndexRelay.accept(index)
        }
    }
    
    var customResolutionWidthBinder: Binder<String?> {
        Binder(self) { target, string in
            guard
                let string = string,
                let width = Int(string),
                let height = Int(target.customResolutionHeightRelay.value) else
            {
                return
            }
            
            if width <= 0 {
                target.customResolutionWidthRelay.accept("1")
            } else {
                target.customResolutionWidthRelay.accept(string)
            }
            
            let dimension = MediaResolution(width: width, height: height)
            guard let index = target.resolutionsRelay.value.firstIndex(of: dimension) else {
                target.currentResolutionIndexRelay.accept(0)
                return
            }
            
            target.currentResolutionIndexRelay.accept(index)
        }
    }
    
    var customResolutionHeightBinder: Binder<String?> {
        Binder(self) { target, string in
            guard
                let string = string,
                let width = Int(target.customResolutionWidthRelay.value),
                let height = Int(string) else
            {
                return
            }
            if height <= 0 {
                target.customResolutionHeightRelay.accept("1")
            } else {
                target.customResolutionHeightRelay.accept(string)
            }
            target.customResolutionHeightRelay.accept(string)
            let dimension = MediaResolution(width: width, height: height)
            guard let index = target.resolutionsRelay.value.firstIndex(of: dimension) else {
                target.currentResolutionIndexRelay.accept(0)
                return
            }
            target.currentResolutionIndexRelay.accept(index)
        }
    }
    
    var speedBinder: Binder<Double> {
        Binder(self) { target, value in
            target.speedRelay.accept(value)
        }
    }
}

private extension MediaInfomationBoxModel {
    
    struct Constants {
        static let twoDigitsFractionFormat = "%.2f"
    }
}

extension MediaInfomationBoxModel {
    
    var resolution: MediaResolution? {
        guard
            let width = Int(customResolutionWidthRelay.value),
            let height = Int(customResolutionHeightRelay.value) else
        {
            return nil
        }
        
        return MediaResolution(width: width, height: height)
    }
    
    var startTime: String? {
        startTimeTextRelay.value
    }
    
    var endTime: String? {
        endTimeTextRelay.value
    }
    
    var speed: Double {
        speedRelay.value
    }
}
