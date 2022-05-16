//
//  ClipViewModel.swift
//  TransVidForma
//
//  Created by QIU DU on 16/5/22.
//  Copyright © 2022 Qiu Du. All rights reserved.
//

import Cocoa

import RxCocoa
import RxSwift

final class ClipViewModel {
    
    let dragHint = "Hold \"option\" + Drag from Trimmed clip to here to add multiple clips."
    let trimControlModel: TrimControlModel
    
    private let mediaInfomationBoxModel: MediaInfomationBoxModel
    
    private let clipsRelay = BehaviorRelay<[Clip]>(value: [])
    
    init(
        trimControlModel: TrimControlModel,
        mediaInfomationBoxModel: MediaInfomationBoxModel)
    {
        self.trimControlModel = trimControlModel
        self.mediaInfomationBoxModel = mediaInfomationBoxModel
    }
    
    func clip() -> Clip? {
        guard
            let startTime = mediaInfomationBoxModel.startTime?.toTimeInterval(),
            let endTime = mediaInfomationBoxModel.endTime?.toTimeInterval() else
        {
            return nil
        }
        return Clip(start: startTime, end: endTime)
    }
}

extension ClipViewModel {
    
    var clipsBinder: Binder<[Clip]> {
        Binder(self) { target, clips in
            target.clipsRelay.accept(clips)
        }
    }
}

extension ClipViewModel {
    
    var clips: [Clip] {
        clipsRelay.value
    }
}

struct Clip {
    
    let start: TimeInterval
    let end: TimeInterval
    let mid: TimeInterval
    let interval: TimeInterval
    
    init?(start: TimeInterval, end: TimeInterval) {
        guard start < end else {
            return nil
        }
        
        self.start = start
        self.end = end
        let range = (start...end)
        mid = range.mid
        interval = range.interval
    }
}
