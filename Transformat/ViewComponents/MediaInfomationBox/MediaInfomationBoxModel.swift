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
    
    let mediaPlayer: VLCMediaPlayer
    
    let resolutionLabel = "Resolution:"
    let audioTrackLabel = "Audio Track:"
    let timeLabel = "Duration:"
    
    let audioTrackNames: Driver<[String]>
    let resolutionNames: Driver<[String]>
    
    let startTimeRatio: Driver<CGFloat?>
    let endTimeRatio: Driver<CGFloat?>
    
    let startTimeTextDriver: Driver<String>
    let startTimeTextPlaceholderDriver: Driver<String?>
    let endTimeTextDriver: Driver<String>
    let endTimeTextPlaceholderDriver: Driver<String?>
    let currentAudioTrackIndex: Driver<Int>
    let currentResolutionIndex: Driver<Int>
    
    fileprivate let startTimeLimitRelay = BehaviorRelay<TimeInterval>(value: .zero)
    fileprivate private(set) var endTimeLimitRelay = BehaviorRelay<TimeInterval>(value: .zero)
    
    fileprivate let startTimeText: Driver<String>
    fileprivate let startTimeTextPlaceholder: Driver<String?>
    fileprivate let endTimeText: Driver<String>
    fileprivate let endTimeTextPlaceholder: Driver<String?>
    
    private let currentAudioTrackIndexRelay: BehaviorRelay<Int>
    private let currentResolutionIndexRelay: BehaviorRelay<Int>
    
    fileprivate let startTimeTextRelay: BehaviorRelay<String> = BehaviorRelay(value: "0")
    private let startTimeTextPlaceholderRelay: BehaviorRelay<String?> = BehaviorRelay(value: nil)
    fileprivate let endTimeTextRelay: BehaviorRelay<String> = BehaviorRelay(value: "0")
    private let endTimeTextPlaceholderRelay: BehaviorRelay<String?> = BehaviorRelay(value: nil)
    
    private let audioTrackNamesRelay = BehaviorRelay<[String]>(value: [])
    private let resolutionNamesRelay = BehaviorRelay<[String]>(value: [])
    
    private let disposeBag = DisposeBag()
    
    init(mediaPlayer: VLCMediaPlayer, mediaPlayerDelegator: MediaPlayerDelegator) {
        self.mediaPlayer = mediaPlayer
        audioTrackNames = audioTrackNamesRelay.asDriver()
        resolutionNames = resolutionNamesRelay.asDriver()
        
        let audioTracks = Self.audioTracks(media: mediaPlayer.media)
        audioTrackNamesRelay.accept(audioTracks.sorted(by: { $0.key < $1.key }).map { $0.value })
        currentAudioTrackIndexRelay = BehaviorRelay(value: audioTrackNamesRelay.value.count > 1 ? 1 : 0)
        currentAudioTrackIndex = currentAudioTrackIndexRelay.asDriver()
        
        resolutionNamesRelay.accept(Self.dismensions(media: mediaPlayer.media).map { $0.description })
        currentResolutionIndexRelay = BehaviorRelay(value: 0)
        currentResolutionIndex = currentResolutionIndexRelay.asDriver()
        
        startTimeText = startTimeLimitRelay.asDriver().map { $0.toString() ?? "" }.distinctUntilChanged()
        startTimeTextPlaceholder = startTimeLimitRelay.asDriver().map { $0.toString() ?? "" }.distinctUntilChanged()
        endTimeText = endTimeLimitRelay.asDriver().map { $0.toString() ?? "" }.distinctUntilChanged()
        endTimeTextPlaceholder = endTimeLimitRelay.asDriver().map { $0.toString() ?? "" }
        
        startTimeTextDriver = startTimeTextRelay.asDriver()
        startTimeTextPlaceholderDriver = startTimeTextPlaceholderRelay.asDriver()
        endTimeTextDriver = endTimeTextRelay.asDriver()
        endTimeTextPlaceholderDriver = endTimeTextPlaceholderRelay.asDriver()
        
        let startAndEndTimeinterval = Driver.combineLatest(
            startTimeLimitRelay.asDriver(),
            endTimeLimitRelay.asDriver())
            .map { $1 - $0 }
            .distinctUntilChanged()
        
        startTimeRatio = Driver.combineLatest(
            startTimeTextRelay.asDriver(),
            startAndEndTimeinterval)
        .map { [startTimeLimitRelay] startTimeText, timeInterval -> CGFloat? in
            guard
                let startTimeInterval = startTimeText.toTimeInterval(),
                timeInterval != .zero else
            {
                return nil
            }
            return (startTimeInterval - startTimeLimitRelay.value) / timeInterval
        }
        
        endTimeRatio = Driver.combineLatest(
            endTimeTextRelay.asDriver(),
            startAndEndTimeinterval)
            .map { [startTimeLimitRelay] endTimeText, timeInterval -> CGFloat? in
                guard
                    let endTimeInterval = endTimeText.toTimeInterval(),
                    timeInterval != .zero else
                {
                    return nil
                }
                return (endTimeInterval - startTimeLimitRelay.value) / timeInterval
            }
            .distinctUntilChanged()
        
        let isPlaying = mediaPlayerDelegator.stateChangedDriver
            .map { $0.isPlaying }
            
        let mappedCurrentAudioTrackIndex = currentAudioTrackIndex.map { Int32($0 <= 0 ? -1 : $0) }
        
        let currentAudioTrackIndexUpdater = Driver.combineLatest(
            isPlaying,
            mappedCurrentAudioTrackIndex.distinctUntilChanged())
            .map { $0.1 }
            .filter { [mediaPlayer] in mediaPlayer.currentAudioTrackIndex != $0 }
        
        disposeBag.insert([
            currentAudioTrackIndexUpdater.drive(mediaPlayer.rx.currentAudioTrackIndex),
        ])
        
        disposeBag.insert([
            startTimeText.drive(startTimeTextRelay),
            startTimeTextPlaceholder.drive(startTimeTextPlaceholderRelay),
            endTimeText.drive(endTimeTextRelay),
            endTimeTextPlaceholder.drive(endTimeTextPlaceholderRelay),
        ])
    }
    
    func setMedia(_ media: VLCMedia) {
        let startTime = FFprobeKit.startTime(media: media) ?? .zero
        let endTime = FFprobeKit.endTime(media: media) ?? .zero
        startTimeLimitRelay.accept(startTime)
        endTimeLimitRelay.accept(endTime)
        
        let audioTracks = Self.audioTracks(media: mediaPlayer.media)
        audioTrackNamesRelay.accept(audioTracks.sorted(by: { $0.key < $1.key }).map { $0.value })
        currentAudioTrackIndexRelay.accept(audioTrackNamesRelay.value.count > 1 ? 1 : 0)
        
        resolutionNamesRelay.accept(Self.dismensions(media: mediaPlayer.media).map { $0.description })
        currentResolutionIndexRelay.accept(0)
    }
}

private extension MediaInfomationBoxModel {
    
    static func dismensions(media: VLCMedia?) -> [MediaResolution] {
        guard
            let media = media,
            let dimension = FFprobeKit.resolution(media: media) else
        {
            return []
        }
        
        return [
            dimension,
            MediaResolution(mediaDimension: dimension, scaled: 0.9),
            MediaResolution(mediaDimension: dimension, scaled: 0.8),
            MediaResolution(mediaDimension: dimension, scaled: 0.7),
            MediaResolution(mediaDimension: dimension, scaled: 0.6),
            MediaResolution(mediaDimension: dimension, scaled: 0.5),
            MediaResolution(mediaDimension: dimension, scaled: 0.4),
            MediaResolution(mediaDimension: dimension, scaled: 0.3),
            MediaResolution(mediaDimension: dimension, scaled: 0.2),
            MediaResolution(mediaDimension: dimension, scaled: 0.1),
        ]
    }
    
    static func audioTracks(media: VLCMedia?) -> AudioTracks {
        guard let media = media else {
            return [:]
        }
        
        return FFprobeKit.audioTracks(media: media)
    }
}

extension MediaInfomationBoxModel {
    
    var startTimeTextBinder: Binder<String?> {
        Binder(self) { target, text in
            
            guard let startTimeText = text else {
                if let startTimeLimitText = target.startTimeLimitRelay.value.toString() {
                    target.startTimeTextRelay.accept(startTimeLimitText)
                }
                return
            }
            
            guard
                let endTimeIntervalLimit = target.endTimeTextRelay.value.toTimeInterval(),
                let startTimeInterval = startTimeText.toTimeInterval()?.clamped(to: target.startTimeLimitRelay.value...endTimeIntervalLimit),
                let startTimeText = startTimeInterval.toString() else
            {
                if let startTimeLimitText = target.startTimeLimitRelay.value.toString() {
                    target.startTimeTextRelay.accept(startTimeLimitText)
                }
                return
            }
            
            target.startTimeTextRelay.accept(startTimeText)
        }
    }
    
    var endTimeTextBinder: Binder<String?> {
        Binder(self) { target, text in
            
            guard let endTimeText = text else {
                if let endTimeLimitText = target.endTimeLimitRelay.value.toString() {
                    target.endTimeTextRelay.accept(endTimeLimitText)
                }
                return
            }
            
            guard
                let startTimeIntervalLimit = target.startTimeTextRelay.value.toTimeInterval(),
                let endTimeInterval = endTimeText.toTimeInterval()?.clamped(to: startTimeIntervalLimit...target.endTimeLimitRelay.value),
                let endTimeText = endTimeInterval.toString() else
            {
                if let endTimeLimitText = target.endTimeLimitRelay.value.toString() {
                    target.endTimeTextRelay.accept(endTimeLimitText)
                }
                return
            }
            
            target.endTimeTextRelay.accept(endTimeText)
        }
    }
    
    var startTimeLimitBinder: Binder<TimeInterval> {
        Binder(self) { target, timeInterval in
            target.startTimeLimitRelay.accept(timeInterval)
        }
    }
    
    var endTimeLimitBinder: Binder<TimeInterval> {
        Binder(self) { target, timeInterval in
            target.endTimeLimitRelay.accept(timeInterval)
        }
    }
    
    var startTimeRatioBinder: Binder<CGFloat> {
        Binder(self) { target, ratio in
            let startTimeInterval = (target.endTimeLimitRelay.value - target.startTimeLimitRelay.value) * ratio + target.startTimeLimitRelay.value
            guard let startTimeText = startTimeInterval.toString() else {
                return
            }
            target.startTimeTextRelay.accept(startTimeText)
        }
    }
    
    var endTimeRatioBinder: Binder<CGFloat> {
        Binder(self) { target, ratio in
            let endTimeInterval = (target.endTimeLimitRelay.value - target.startTimeLimitRelay.value) * ratio + target.startTimeLimitRelay.value
            guard let endTimeText = endTimeInterval.toString() else {
                return
            }
            target.endTimeTextRelay.accept(endTimeText)
        }
    }
    
    var currentAudioTrackIndexBinder: Binder<Int> {
        Binder(self) { target, index in
            target.currentAudioTrackIndexRelay.accept(index)
        }
    }
    
    var currentResolutionIndexBinder: Binder<Int> {
        Binder(self) { target, index in
            target.currentResolutionIndexRelay.accept(index)
        }
    }
}

extension MediaInfomationBoxModel {
    
    var audioTrackIndex: Int {
        currentAudioTrackIndexRelay.value
    }
    
    var resolution: MediaResolution {
        Self.dismensions(media: mediaPlayer.media)[currentResolutionIndexRelay.value]
    }
    
    var startTime: String {
        startTimeTextRelay.value
    }
    
    var endTime: String {
        endTimeTextRelay.value
    }
}
