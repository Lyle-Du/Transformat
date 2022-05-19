//
//  ControlPanelViewModel.swift
//  Transformat
//
//  Created by QIU DU on 3/5/22.
//

import RxCocoa
import RxSwift
import VLCKit

final class ControlPanelViewModel {
    
    let mediaReset: Observable<()>
    
    private let mediaResetSubject = PublishSubject<()>()
    
    let trimControlModel: TrimControlModel
    let playButtonImageName: Driver<String>
    
    private let disposeBag = DisposeBag()
    private let playButtonImageNameRelay = BehaviorRelay<String>(value: Constants.playImageName)
    
    private let mediaPlayer: VLCMediaPlayer
    private var wasPlaying = false
    
    init(mediaPlayer: VLCMediaPlayer, mediaPlayerDelegator: MediaPlayerDelegator) {
        self.mediaPlayer = mediaPlayer
        mediaReset = mediaResetSubject.asObserver()
        trimControlModel = TrimControlModel(mediaPlayer: mediaPlayer, mediaPlayerDelegator: mediaPlayerDelegator)
        playButtonImageName = playButtonImageNameRelay.asDriver()
    }
    
    func playClicked() {
        if mediaPlayer.isPlaying {
            if mediaPlayer.canPause {
                mediaPlayer.pause()
                wasPlaying = false
            }
        } else {
            mediaPlayer.play()
            wasPlaying = true
        }
    }
}

extension ControlPanelViewModel {
    struct Constants {
        static let playImageName = "play"
        static let pauseImageName = "pause"
    }
}

extension ControlPanelViewModel {
    
    var stateChanged: Binder<VLCMediaPlayer> {
        Binder(self) { target, mediaPlayer in
            let imageName: String
            if mediaPlayer.isPlaying {
                imageName = Constants.pauseImageName
            } else {
                imageName = Constants.playImageName
            }
            target.playButtonImageNameRelay.accept(imageName)
            
            // Note: This mediaPlayer.state switch case fixes mediaplayer does not loop back to the beginning of video when video playback is ended.
            switch mediaPlayer.state {
            case .ended:
                if let url = mediaPlayer.media?.url {
                    let media = VLCMedia(url: url)
                    mediaPlayer.media = media
                    if target.wasPlaying {
                        mediaPlayer.play()
                    }
                }
            case .paused:
                if target.wasPlaying {
                    mediaPlayer.play()
                    target.mediaResetSubject.onNext(())
                }
            default:
                break
            }
        }
    }
    
    var timeChanged: Binder<VLCMediaPlayer> {
        Binder(self) { target, mediaPlayer in
            target.trimControlModel.updateCurrentPositionRatio(CGFloat(mediaPlayer.position))
        }
    }
}
