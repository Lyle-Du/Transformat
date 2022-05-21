//
//  MainWindowViewModelTests.swift
//  TransVid FormaTests
//
//  Created by QIU DU on 21/5/22.
//  Copyright © 2022 Qiu Du. All rights reserved.
//

import XCTest

import RxSwift
import RxTest

@testable import TransVid_Forma

final class MainWindowViewModelTests: XCTestCase {
    
    private var userDefaults: UserDefaults!
    private let scheduler = TestScheduler(initialClock: .zero)
    private let disposeBag = DisposeBag()

    override func setUpWithError() throws {
        userDefaults = UserDefaults(suiteName: #file)
    }

    override func tearDownWithError() throws {
        userDefaults.removeSuite(named: #file)
    }

    func testExample1() throws {
        let viewModel = MainWindowViewModel(userDefaults: userDefaults)
        let observer = scheduler.createObserver(Bool.self)
        viewModel.isPinned.drive(observer).disposed(by: disposeBag)
        XCTAssertEqual(observer.events, [.next(0, false)])
    }
    
    func testExample2() throws {
        userDefaults.set(true, forKey: "isPinned")
        let viewModel = MainWindowViewModel(userDefaults: userDefaults)
        let observer = scheduler.createObserver(Bool.self)
        viewModel.isPinned.drive(observer).disposed(by: disposeBag)
        XCTAssertEqual(observer.events, [.next(0, true)])
    }

    func testPerformanceExample() throws {
        let viewModel = MainWindowViewModel(userDefaults: userDefaults)
        let observer = scheduler.createObserver(Bool.self)
        viewModel.isPinned.drive(observer).disposed(by: disposeBag)
        
        scheduler.scheduleAt(1) { viewModel.togglePinButton() }
        scheduler.scheduleAt(2) { viewModel.togglePinButton() }
        scheduler.start()
        
        XCTAssertEqual(observer.events, [
            .next(0, false),
            .next(1, true),
            .next(2, false),
        ])
    }
}
