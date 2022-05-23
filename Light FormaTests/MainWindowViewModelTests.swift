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

final class MainWindowViewModelTests: RxTestCase {
    
    private var userDefaults: UserDefaults!

    override func setUpWithError() throws {
        userDefaults = UserDefaults(suiteName: #file)
    }

    override func tearDownWithError() throws {
        userDefaults.removeSuite(named: #file)
    }
    
    func testStaticContents() throws {
        let viewModel = MainWindowViewModel(userDefaults: userDefaults)
        XCTAssertEqual(viewModel.title, NSLocalizedString("Light Forma", comment: ""))
    }

    func testIsPinnedIsFalseByDefault() throws {
        let viewModel = MainWindowViewModel(userDefaults: userDefaults)
        let observer = createObserver(Bool.self)
        viewModel.isPinned.drive(observer).disposed(by: disposeBag)
        XCTAssertEqual(observer.events, [.next(0, false)])
    }
    
    func testIsPinnedIsTrue_givenStoredIsPinnedAsTrue() throws {
        userDefaults.set(true, forKey: "isPinned")
        let viewModel = MainWindowViewModel(userDefaults: userDefaults)
        let observer = createObserver(Bool.self)
        viewModel.isPinned.drive(observer).disposed(by: disposeBag)
        XCTAssertEqual(observer.events, [.next(0, true)])
    }
    
    func testIsPinnedIsStored_whenTogglePinButtonCalled() throws {
        let viewModel = MainWindowViewModel(userDefaults: userDefaults)
        XCTAssertFalse(userDefaults.bool(forKey: "isPinned"))
        viewModel.togglePinButton()
        XCTAssertTrue(userDefaults.bool(forKey: "isPinned"))
        viewModel.togglePinButton()
        XCTAssertFalse(userDefaults.bool(forKey: "isPinned"))
    }

    func testIsPinnedChanged_whenTogglePinButtonCalled() throws {
        let viewModel = MainWindowViewModel(userDefaults: userDefaults)
        let observer = createObserver(Bool.self)
        viewModel.isPinned.drive(observer).disposed(by: disposeBag)
        
        scheduleAt(1) { viewModel.togglePinButton() }
        scheduleAt(2) { viewModel.togglePinButton() }
        start()
        
        XCTAssertEqual(observer.events, [
            .next(0, false),
            .next(1, true),
            .next(2, false),
        ])
    }
    
    func testIsPinButtonHiddenIsFalse_whenWindowDidExitFullScreenCalled() throws {
        let viewModel = MainWindowViewModel(userDefaults: userDefaults)
        let observer = createObserver(Bool.self)
        viewModel.isPinButtonHidden.drive(observer).disposed(by: disposeBag)
        
        scheduleAt(1) { viewModel.windowDidExitFullScreen() }
        start()
        
        XCTAssertEqual(observer.events, [
            .next(0, false),
            .next(1, false),
        ])
    }
    
    func testIsPinButtonHiddenIsTrue_whenWindowDidEnterFullScreenCalled() throws {
        let viewModel = MainWindowViewModel(userDefaults: userDefaults)
        let observer = createObserver(Bool.self)
        viewModel.isPinButtonHidden.drive(observer).disposed(by: disposeBag)
        
        scheduleAt(1) { viewModel.windowDidEnterFullScreen() }
        start()
        
        XCTAssertEqual(observer.events, [
            .next(0, false),
            .next(1, true),
        ])
    }
}
