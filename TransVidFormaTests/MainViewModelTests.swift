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
    
    private let openPanel = MockOpenPanel()
    private let mediaPlayer = MockMediaPlayer()

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
    
    func testMediaPlayerDrawableSet_whenUpdateDrawableCalled() throws {
        let viewModel = makeViewModel()
        let view = NSView(frame: .zero)
        viewModel.updateDrawable(view)
        XCTAssertEqual(mediaPlayer.drawable as? NSView, view)
    }
    
    func testRunModalCalled_whenImportButtonClickedCalled() throws {
        let expectation = self.expectation(description: #function)
        openPanel.stubRunModalHandler = expectation.fulfill
        let viewModel = makeViewModel()
        viewModel.importButtonClicked()
        waitForExpectations(timeout: .zero)
    }
    
    func testMediaURLSet_whenImportButtonClickedCalled_givenRunModalResponseIsOKAndOpenPanelURLIsAvailable() throws {
        let expectation = self.expectation(description: #function)
        openPanel.url = URL(string: "test")
        openPanel.stubRunModalResponse = .OK
        openPanel.stubRunModalHandler = expectation.fulfill
        let viewModel = makeViewModel()
        viewModel.importButtonClicked()
        waitForExpectations(timeout: .zero)
        XCTAssertEqual(mediaPlayer.media?.url, URL(string: "test"))
    }
    
    func testMediaURLNotSet_whenImportButtonClickedCalled_givenRunModalResponseIsCancel() throws {
        let expectation = self.expectation(description: #function)
        openPanel.url = URL(string: "test")
        openPanel.stubRunModalResponse = .cancel
        openPanel.stubRunModalHandler = expectation.fulfill
        let viewModel = makeViewModel()
        viewModel.importButtonClicked()
        waitForExpectations(timeout: .zero)
        XCTAssertNil(mediaPlayer.media?.url)
    }
    
    func testIsImportExportDisabledIsFalseByDefault() throws {
        let viewModel = makeViewModel()
        let observer = createObserver(Bool.self)
        viewModel.isImportDisabled.drive(observer).disposed(by: disposeBag)
        XCTAssertEqual(observer.events, [.next(0, false)])
    }
    
    func testIsExportDisabledIsTrueByDefault() throws {
        let viewModel = makeViewModel()
        let observer = createObserver(Bool.self)
        viewModel.isExportDisabled.drive(observer).disposed(by: disposeBag)
        XCTAssertEqual(observer.events, [.next(0, true)])
    }
    
    func testHasVideoOutIsSameAsMediaPlayerHasVideoOut() throws {
        let viewModel = makeViewModel()
        mediaPlayer.hasVideoOut = false
        XCTAssertEqual(viewModel.hasVideoOut, false)
        mediaPlayer.hasVideoOut = true
        XCTAssertEqual(viewModel.hasVideoOut, true)
    }
    
    func testIsOptionAreaContainerHiddenUpdated_whenTogglePlayerModeCalled_givenValidWindowAndIsWindowFullScreen() throws {
        let window = NSWindow()
        let viewModel = makeViewModel()
        let observer = createObserver(Bool.self)
        viewModel.isOptionAreaContainerHidden.drive(observer).disposed(by: disposeBag)
        scheduleAt(10) { viewModel.togglePlayerMode(isWindowFullScreen: true, window: nil) }
        scheduleAt(20) { viewModel.togglePlayerMode(isWindowFullScreen: false, window: nil) }
        scheduleAt(30) { viewModel.togglePlayerMode(isWindowFullScreen: true, window: window) }
        scheduleAt(40) { viewModel.togglePlayerMode(isWindowFullScreen: false, window: window) }
        start()
        XCTAssertEqual(observer.events, [
            .next(0, false),
            .next(30, true),
            .next(40, false),
        ])
    }
}

private extension MainViewModelTests {
    
    func makeViewModel() -> MainViewModel {
        MainViewModel(openPanel: openPanel, mediaPlayer: mediaPlayer)
    }
}
