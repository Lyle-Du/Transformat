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
    
    let trimControlModel: TrimControlModel
    
    let playButtonImageName: Driver<String>
    
    private let disposeBag = DisposeBag()
    private let playButtonImageNameRelay = BehaviorRelay<String>(value: Constants.playImageName)
    
    private let mediaPlayer: VLCMediaPlayer
    
    init(mediaPlayer: VLCMediaPlayer, mediaPlayerDelegator: MediaPlayerDelegator) {
        self.mediaPlayer = mediaPlayer
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
        }
    }
    
    var timeChanged: Binder<VLCMediaPlayer> {
        Binder(self) { target, mediaPlayer in
            target.trimControlModel.updateCurrentPositionRatio(CGFloat(mediaPlayer.position))
        }
    }
}
