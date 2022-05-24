//
//  ControlPanelViewModel.swift
//  Transformat
//
//  Created by QIU DU on 3/5/22.
//

import ffmpegkit
import RxCocoa
import RxSwift
import VLCKit

final class ControlPanelViewModel {
    
    let mediaReset: Observable<()>
    
    let currentAudioTrackIndex: Driver<Int>
    let currentSubtitleIndex: Driver<Int>
    
    let audioTrackLabel = NSLocalizedString("Audio Track:", comment: "")
    let subtitleLabel = NSLocalizedString("Subtitle:", comment: "")
    
    let audioTrackNames: Driver<[String]>
    let subtitleNames: Driver<[String]>
    
    let trimControlModel: TrimControlModel
    let playButtonImageName: Driver<String>
    
    private let disposeBag = DisposeBag()
    private let playButtonImageNameRelay = BehaviorRelay<String>(value: Constants.playImageName)
    private let mediaResetSubject = PublishSubject<()>()
    
    private let currentAudioTrackIndexRelay: BehaviorRelay<Int>
    private let currentSubtitleIndexRelay: BehaviorRelay<Int>
    
    private let audioTracksRelay = BehaviorRelay<[AudioTrack]>(value: [])
    private let audioTrackNamesRelay = BehaviorRelay<[String]>(value: [])
    
    private let subtitlesRelay = BehaviorRelay<[Subtitle]>(value: [])
    private let subtitleNamesRelay = BehaviorRelay<[String]>(value: [])
    
    private let mediaPlayer: MediaPlayer
    
    init(mediaPlayer: MediaPlayer, mediaPlayerDelegator: MediaPlayerDelegator) {
        self.mediaPlayer = mediaPlayer
        mediaReset = mediaResetSubject.asObserver()
        trimControlModel = TrimControlModel(mediaPlayer: mediaPlayer, mediaPlayerDelegator: mediaPlayerDelegator)
        playButtonImageName = playButtonImageNameRelay.asDriver()
        
        audioTrackNames = audioTrackNamesRelay.asDriver()
        subtitleNames = subtitleNamesRelay.asDriver()
        
        let audioTracks = Self.audioTracks(media: mediaPlayer.media)
        audioTracksRelay.accept(audioTracks)
        currentAudioTrackIndexRelay = BehaviorRelay(value: audioTracks.count > 1 ? 1 : 0)
        currentAudioTrackIndex = currentAudioTrackIndexRelay.asDriver()
        
        let subtitles = Self.subtitles(media: mediaPlayer.media)
        subtitlesRelay.accept(subtitles)
        currentSubtitleIndexRelay = BehaviorRelay(value: subtitles.count > 1 ? 1 : 0)
        currentSubtitleIndex = currentSubtitleIndexRelay.asDriver()
        
        let isPlaying = mediaPlayerDelegator.stateChangedDriver
            .map { $0.isPlaying }
            
        let mappedCurrentAudioTrackIndex = currentAudioTrackIndex.compactMap { [audioTracksRelay] index -> Int32? in
            let audioTracks = audioTracksRelay.value
            guard index < audioTracks.count && index >= 0 else {
                return -1
            }
            return Int32(audioTracks[index].streamID)
        }
        
        let currentAudioTrackIndexUpdater = Driver.combineLatest(
            isPlaying,
            mappedCurrentAudioTrackIndex.distinctUntilChanged())
            .map { $0.1 }
            .filter { [mediaPlayer] in mediaPlayer.currentAudioTrackIndex != $0 }
        
        let mappedCurrentSubtitleIndex = currentSubtitleIndex.compactMap { [subtitlesRelay] index -> Int32? in
            let subtitles = subtitlesRelay.value
            guard index < subtitles.count && index >= 0 else {
                return -1
            }
            return Int32(subtitles[index].streamID)
        }
        
        let currentSubtitleIndexUpdater = Driver.combineLatest(
            isPlaying,
            mappedCurrentSubtitleIndex.distinctUntilChanged())
            .map { $0.1 }
            .filter { [mediaPlayer] in mediaPlayer.currentVideoSubTitleIndex != $0 }
        
        disposeBag.insert([
            audioTracksRelay.map { $0.sorted(by: { $0.titleID < $1.titleID }).map(\.name) }.bind(to: audioTrackNamesRelay),
            currentAudioTrackIndexUpdater.drive(onNext: { [mediaPlayer] currentAudioTrackIndex in
                mediaPlayer.currentAudioTrackIndex = currentAudioTrackIndex
            }),
            
            subtitlesRelay.map { $0.sorted(by: { $0.titleID < $1.titleID }).map(\.name) }.bind(to: subtitleNamesRelay),
            currentSubtitleIndexUpdater.drive(onNext: { [mediaPlayer] currentVideoSubTitleIndex in
                mediaPlayer.currentVideoSubTitleIndex = currentVideoSubTitleIndex
            }),
        ])
    }
    
    func playClicked() {
        if mediaPlayer.isPlaying {
            if mediaPlayer.canPause {
                mediaPlayer.pause()
            }
        } else {
            mediaPlayer.play()
        }
    }
    
    func setMedia(_ media: VLCMedia) {
        trimControlModel.loadThumbnails(media)
        playButtonImageNameRelay.accept(Constants.playImageName)
        
        let audioTracks = Self.audioTracks(media: media)
        audioTracksRelay.accept(audioTracks)
        currentAudioTrackIndexRelay.accept(audioTracks.count > 1 ? 1 : 0)
        let subtitles = Self.subtitles(media: media)
        subtitlesRelay.accept(subtitles)
        currentSubtitleIndexRelay.accept(subtitles.count > 1 ? 1 : 0)
    }
}

private extension ControlPanelViewModel {
    
    static func audioTracks(media: VLCMedia?) -> [AudioTrack] {
        guard let media = media else {
            return []
        }
        
        return FFprobeKit.audioTracks(media: media, includeDisabled: true)
    }
    
    static func subtitles(media: VLCMedia?) -> [Subtitle] {
        guard let media = media else {
            return []
        }
        
        return FFprobeKit.subtitles(media: media, includeDisabled: true)
    }
}

extension ControlPanelViewModel {
    
    struct Constants {
        static let playImageName = "play"
        static let pauseImageName = "pause"
    }
}

extension ControlPanelViewModel {
    
    var currentAudioTrackIndexBinder: Binder<Int> {
        Binder(self) { target, index in
            target.currentAudioTrackIndexRelay.accept(index)
        }
    }
    
    var currentSubtitleIndexBinder: Binder<Int> {
        Binder(self) { target, index in
            target.currentSubtitleIndexRelay.accept(index)
        }
    }
    
    var stateChanged: Binder<MediaPlayer> {
        Binder(self) { target, mediaPlayer in
            let imageName: String
            if mediaPlayer.isPlaying {
                imageName = Constants.pauseImageName
            } else {
                imageName = Constants.playImageName
            }
            target.playButtonImageNameRelay.accept(imageName)
            
            // Note: This mediaPlayer.state switch case fixes mediaplayer is not able to replay after a playback ended
            switch mediaPlayer.state {
            case .ended:
                if let url = mediaPlayer.media?.url {
                    let media = VLCMedia(url: url)
                    mediaPlayer.media = media
                    target.mediaResetSubject.onNext(())
                    mediaPlayer.play()
                }
            default:
                break
            }
        }
    }
    
    var timeChanged: Binder<MediaPlayer> {
        Binder(self) { target, mediaPlayer in
            target.trimControlModel.updateCurrentPositionRatio(CGFloat(mediaPlayer.position))
        }
    }
}

extension ControlPanelViewModel {
    
    var audioTrackIndex: Int {
        let audioTracks = audioTracksRelay.value
        let index = currentAudioTrackIndexRelay.value
        if index < 0 || index >= audioTracks.count {
            return -1
        }
        return audioTracks[index].streamID
    }
}
