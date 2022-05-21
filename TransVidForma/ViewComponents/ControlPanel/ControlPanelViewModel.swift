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
    
    let trimControlModel: TrimControlModel
    let playButtonImageName: Driver<String>
    
    private let disposeBag = DisposeBag()
    private let playButtonImageNameRelay = BehaviorRelay<String>(value: Constants.playImageName)
    private let mediaResetSubject = PublishSubject<()>()
    
    private let mediaPlayer: VLCMediaPlayer
    
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
            }
        } else {
            mediaPlayer.play()
        }
    }
    
    func setMedia(_ media: VLCMedia) {
        trimControlModel.loadThumbnails(media)
        playButtonImageNameRelay.accept(Constants.playImageName)
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
    
    var timeChanged: Binder<VLCMediaPlayer> {
        Binder(self) { target, mediaPlayer in
            target.trimControlModel.updateCurrentPositionRatio(CGFloat(mediaPlayer.position))
        }
    }
}
