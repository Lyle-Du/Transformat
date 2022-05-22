//
//  MainViewModelTests.swift
//  TransVid FormaTests
//
//  Created by QIU DU on 22/5/22.
//  Copyright © 2022 Qiu Du. All rights reserved.
//

import XCTest

import VLCKit

@testable import TransVid_Forma

final class MainViewModelTests: RxTestCase {
    
    private let openPanel = NSOpenPanel()
    private let mediaPlayer = VLCMediaPlayer()

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testStaticContents() throws {
        let viewModel = makeViewModel()
        let cancelAlert = viewModel.cancelAlert
        XCTAssertEqual(cancelAlert.messageText, NSLocalizedString("Cancel Exporting", comment: ""))
        XCTAssertEqual(cancelAlert.informativeText, NSLocalizedString("Are you sure to cancel current export task?", comment: ""))
        XCTAssertEqual(cancelAlert.alertStyle, .warning)
        XCTAssertEqual(cancelAlert.okButtonTitle, NSLocalizedString("Confirm", comment: ""))
        XCTAssertEqual(cancelAlert.cancelButtonTitle, NSLocalizedString("Cancel", comment: ""))
    }

    func testWindowDidEnterFullScreenHandlerIsCalled_whenWindowDidEnterFullScreenCalled() throws {
        let expectation = self.expectation(description: #function)
        let viewModel = makeViewModel()
        viewModel.windowDidEnterFullScreenHandler = expectation.fulfill
        viewModel.windowDidEnterFullScreen()
        waitForExpectations(timeout: .zero)
    }
    
    func testWindowDidExitFullScreenHandlerIsCalled_whenWindowDidExitFullScreenCalled() throws {
        let expectation = self.expectation(description: #function)
        let viewModel = makeViewModel()
        viewModel.windowDidExitFullScreenHandler = expectation.fulfill
        viewModel.windowDidExitFullScreen()
        waitForExpectations(timeout: .zero)
    }
}

private extension MainViewModelTests {
    
    func makeViewModel() -> MainViewModel {
        MainViewModel(openPanel: openPanel, mediaPlayer: mediaPlayer)
    }
}
