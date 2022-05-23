//
//  MediaPlayerDelegator.swift
//  Transformat
//
//  Created by QIU DU on 28/4/22.
//

import IOKit.pwr_mgt

import Foundation

import RxCocoa
import RxSwift
import VLCKit

final class MediaPlayerDelegator: NSObject, VLCMediaPlayerDelegate {
    
    var shouldPause = false
    
    let stateChangedDriver: Driver<MediaPlayer>
    let timeChangedDriver: Driver<MediaPlayer>
    
    private let stateChanged = PublishSubject<MediaPlayer>()
    private let timeChanged = PublishSubject<MediaPlayer>()
    
    private weak var mediaPlayer: MediaPlayer!
    
    private var assertionID = IOPMAssertionID(0)
    private let reasonForActivity = "Video is playing" as CFString
    private let kIOPMAssertPreventUserIdleDisplaySleep = "PreventUserIdleDisplaySleep" as CFString
    private var preventUserIdleDisplaySleepSuccess: IOReturn?
    
    init(mediaPlayer: MediaPlayer) {
        self.mediaPlayer = mediaPlayer
        stateChangedDriver = stateChanged.asDriver(onErrorJustReturn: self.mediaPlayer)
        timeChangedDriver = timeChanged.asDriver(onErrorJustReturn: self.mediaPlayer)
        super.init()
        self.mediaPlayer.delegate = self
    }
    
    func mediaPlayerStateChanged(_ notification: Notification) {
        guard let mediaPlayer = notification.object as? VLCMediaPlayer else { return }
        
        if mediaPlayer.isPlaying {
            if preventUserIdleDisplaySleepSuccess != kIOReturnSuccess {
                preventUserIdleDisplaySleepSuccess = IOPMAssertionCreateWithName(
                    kIOPMAssertPreventUserIdleDisplaySleep,
                    IOPMAssertionLevel(kIOPMAssertionLevelOn),
                    reasonForActivity,
                    &assertionID)
            }
        } else {
            if preventUserIdleDisplaySleepSuccess == kIOReturnSuccess {
                IOPMAssertionRelease(assertionID)
            }
        }
        
        stateChanged.onNext(mediaPlayer)
        handleViewDidDisappear(mediaPlayer)
    }
    
    func mediaPlayerTimeChanged(_ notification: Notification) {
        guard let mediaPlayer = notification.object as? VLCMediaPlayer else { return }
        timeChanged.onNext(mediaPlayer)
        handleViewDidDisappear(mediaPlayer)
    }
    
    private func handleViewDidDisappear(_ mediaPlayer: MediaPlayer) {
        guard shouldPause && mediaPlayer.isPlaying else {
            return
        }
        mediaPlayer.pause()
    }
}
