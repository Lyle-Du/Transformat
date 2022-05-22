//
//  MediaPlayer.swift
//  TransVid FormaTests
//
//  Created by QIU DU on 22/5/22.
//  Copyright © 2022 Qiu Du. All rights reserved.
//

import VLCKit
import RxSwift

/// VLCMediaPlayer interface wrapper
protocol MediaPlayer: AnyObject {
    
    /// Does the current media have a video output?
    var hasVideoOut: Bool { get }
    
    /// property whether the currently playing media can be paused (or not)
    var canPause: Bool { get }
    
    /// Playback state flag identifying that the stream is currently playing.
    var isPlaying: Bool { get }
    
    /// Playback's current state.
    var state: VLCMediaPlayerState { get }
    
    /// the delegate object implementing the optional protocol
    var delegate: VLCMediaPlayerDelegate? { get set }
    
    /// The currently media instance set to play
    var media: VLCMedia? { get set }
    
    /// set/retrieve a video view for rendering This can be any UIView or NSView or instances of VLCVideoView / VLCVideoLayer if running on macOS
    var drawable: Any? { get set }
    
    /// Returns the receiver's position in the reading.
    var position: Float { get set }
    
    /// Return the current audio track index
    /// Pass -1 to disable.
    var currentAudioTrackIndex: Int32 { get set }
    
    /// Return the current video subtitle index
    ///  Pass -1 to disable.
    var currentVideoSubTitleIndex: Int32 { get set }
    
    /// Get the requested movie play rate.
    ///
    /// Warning:
    /// Depending on the underlying media, the requested rate may be different from the real playback rate. Due to limitations of some protocols this option may not be taken into account at all, if set.
    var rate: Float { get set }
    
    /// Set the pause state of the feed. Do nothing if already paused.
    func pause()
    
    /// Plays a media resource using the currently selected media controller (or default controller. If feed was paused then the feed resumes at the position it was paused in.
    func play()
}

extension VLCMediaPlayer: MediaPlayer {}
