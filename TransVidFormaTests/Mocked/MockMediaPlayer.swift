//
//  MockMediaPlayer.swift
//  TransVid FormaTests
//
//  Created by QIU DU on 22/5/22.
//  Copyright © 2022 Qiu Du. All rights reserved.
//

import VLCKit

@testable import TransVid_Forma

final class MockMediaPlayer: MediaPlayer {
    
    var stubPauseHandler: (() -> Void)?
    var stubPlayHandler: (() -> Void)?
    
    var hasVideoOut: Bool = false
    var canPause: Bool = false
    var isPlaying: Bool = false
    var state: VLCMediaPlayerState = .opening
    var delegate: VLCMediaPlayerDelegate?
    var media: VLCMedia?
    var drawable: Any?
    var position: Float = .zero
    var currentAudioTrackIndex: Int32 = -1
    var currentVideoSubTitleIndex: Int32 = -1
    var rate: Float = 1.0
    
    func pause() {
        stubPauseHandler?()
    }
    
    func play() {
        stubPlayHandler?()
    }
}
