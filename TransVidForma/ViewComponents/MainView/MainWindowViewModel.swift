//
//  MainWindowViewModel.swift
//  TransVid Forma
//
//  Created by QIU DU on 21/5/22.
//  Copyright © 2022 Qiu Du. All rights reserved.
//

import Cocoa
import RxCocoa

final class MainWindowViewModel {
    
    let title = NSLocalizedString("TransVid Forma", comment: "")
    let isPinButtonHidden: Driver<Bool>
    let isPinned: Driver<Bool>
    
    private let isPinButtonHiddenRelay = BehaviorRelay<Bool>(value: false)
    private let isPinnedRelay: BehaviorRelay<Bool>
    private let userDefaults: UserDefaults
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        isPinButtonHidden = isPinButtonHiddenRelay.asDriver()
        isPinnedRelay = BehaviorRelay(value: userDefaults.bool(forKey: StoreKey.isPinned))
        isPinned = isPinnedRelay.asDriver()
    }
    
    func togglePinButton() {
        isPinnedRelay.accept(!isPinnedRelay.value)
        userDefaults.set(isPinnedRelay.value, forKey: StoreKey.isPinned)
    }
}

extension MainWindowViewModel {
    
    func windowDidExitFullScreen() {
        isPinButtonHiddenRelay.accept(false)
    }
    
    func windowDidEnterFullScreen() {
        isPinButtonHiddenRelay.accept(true)
    }
}

private extension MainWindowViewModel {
    
    struct StoreKey {
        static let isPinned = "isPinned"
    }
}
