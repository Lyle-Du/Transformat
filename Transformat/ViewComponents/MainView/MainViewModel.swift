//
//  MainViewModel.swift
//  Transformat
//
//  Created by QIU DU on 7/5/22.
//

import ffmpegkit
import RxCocoa
import RxSwift
import VLCKit

final class MainViewModel {
    
    let importButtonTitle = "► Import ►"
    let exportButtonTitle = "► Export ►"
    
    let mediaPlayer: VLCMediaPlayer
    
    let stateChangedDriver: Driver<VLCMediaPlayer>
    
    private(set) var controlPanelViewModel: ControlPanelViewModel
    private(set) var mediaInfomationBoxModel: MediaInfomationBoxModel
    
    private let disposeBag = DisposeBag()
    private let startTimeRelay = BehaviorRelay<TimeInterval>(value: .zero)
    private let endTimeRelay = BehaviorRelay<TimeInterval>(value: .zero)
    
    private let openPanel: NSOpenPanel
    private let mediaPlayerDelegator: MediaPlayerDelegator
    
    init(openPanel: NSOpenPanel = NSOpenPanel(), mediaPlayer: VLCMediaPlayer = VLCMediaPlayer()) {
        self.openPanel = openPanel
        self.mediaPlayer = mediaPlayer
        self.mediaPlayerDelegator = MediaPlayerDelegator(mediaPlayer: self.mediaPlayer)
        controlPanelViewModel = ControlPanelViewModel(mediaPlayer: mediaPlayer, mediaPlayerDelegator: mediaPlayerDelegator)
        mediaInfomationBoxModel = MediaInfomationBoxModel(mediaPlayer: mediaPlayer, mediaPlayerDelegator: mediaPlayerDelegator)
        stateChangedDriver = mediaPlayerDelegator.stateChangedDriver
        
        disposeBag.insert([
            mediaPlayerDelegator.stateChangedDriver.drive(controlPanelViewModel.stateChanged),
            mediaPlayerDelegator.timeChangedDriver.drive(controlPanelViewModel.timeChanged),
            startTimeRelay.asDriver().drive(mediaInfomationBoxModel.startTimeLimitBinder),
            endTimeRelay.asDriver().drive(mediaInfomationBoxModel.endTimeLimitBinder),
            mediaInfomationBoxModel.startTimeRatio.drive(controlPanelViewModel.trimControlModel.startTimeRatio),
            mediaInfomationBoxModel.endTimeRatio.drive(controlPanelViewModel.trimControlModel.endTimeRatio),
            controlPanelViewModel.trimControlModel.startTimePositionRatio.drive(mediaInfomationBoxModel.startTimeRatioBinder),
            controlPanelViewModel.trimControlModel.endTimePositionRatio.drive(mediaInfomationBoxModel.endTimeRatioBinder),
        ])
    }
    
    func importButtonClicked() {
        guard
            openPanel.runModal() == .OK,
            let url = openPanel.url else
        {
            return
        }
        
        setMedia(url: url)
    }
    
    private func setMedia(url: URL) {
        guard mediaPlayer.media?.url != url else {
            return
        }
        mediaPlayer.stop()
        let media = VLCMedia(url: url)
        mediaPlayer.media = media
        mediaInfomationBoxModel.setMedia(media)
    }
}
