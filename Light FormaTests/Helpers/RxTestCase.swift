//
//  RxTestCase.swift
//  TransVid FormaTests
//
//  Created by QIU DU on 22/5/22.
//  Copyright © 2022 Qiu Du. All rights reserved.
//

import XCTest

import RxSwift
import RxTest

class RxTestCase: XCTestCase {
    
    let disposeBag = DisposeBag()
    
    private let scheduler = TestScheduler(initialClock: .zero)
    
    func start() {
        scheduler.start()
    }
    
    func scheduleAt(_ time: TestTime, action: @escaping () -> Void) {
        scheduler.scheduleAt(time, action: action)
    }
    
    func createObserver<Element>(_ type: Element.Type) -> TestableObserver<Element> {
        scheduler.createObserver(type)
    }
}
