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
    let isPinned: Driver<Bool>
    
    private let isPinnedRelay: BehaviorRelay<Bool>
    private let userDefaults: UserDefaults
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        isPinnedRelay = BehaviorRelay(value: userDefaults.bool(forKey: StoreKey.isPinned))
        isPinned = isPinnedRelay.asDriver()
    }
    
    func togglePinButton() {
        isPinnedRelay.accept(!isPinnedRelay.value)
        userDefaults.set(isPinnedRelay.value, forKey: StoreKey.isPinned)
    }
}

private extension MainWindowViewModel {
    
    struct StoreKey {
        static let isPinned = "isPinned"
    }
}
