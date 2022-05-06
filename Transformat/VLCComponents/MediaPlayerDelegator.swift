//
//  MediaPlayerDelegator.swift
//  Transformat
//
//  Created by QIU DU on 28/4/22.
//

import Foundation

import RxCocoa
import RxSwift
import VLCKit

final class MediaPlayerDelegator: NSObject, VLCMediaPlayerDelegate {
    
    let stateChangedDriver: Driver<VLCMediaPlayer>
    let timeChangedDriver: Driver<VLCMediaPlayer>
    
    private let stateChanged = PublishSubject<VLCMediaPlayer>()
    private let timeChanged = PublishSubject<VLCMediaPlayer>()
    
    private weak var mediaPlayer: VLCMediaPlayer!
    
    init(mediaPlayer: VLCMediaPlayer) {
        self.mediaPlayer = mediaPlayer
        stateChangedDriver = stateChanged.asDriver(onErrorJustReturn: self.mediaPlayer)
        timeChangedDriver = timeChanged.asDriver(onErrorJustReturn: self.mediaPlayer)
        super.init()
        self.mediaPlayer.delegate = self
    }
    
    func mediaPlayerStateChanged(_ notification: Notification) {
        guard let mediaPlayer = notification.object as? VLCMediaPlayer else { return }
        stateChanged.onNext(mediaPlayer)
    }
    
    func mediaPlayerTimeChanged(_ notification: Notification) {
        guard let mediaPlayer = notification.object as? VLCMediaPlayer else { return }
        timeChanged.onNext(mediaPlayer)
    }
}
