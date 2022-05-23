//
//  MockOpenPanel.swift
//  TransVid FormaTests
//
//  Created by QIU DU on 22/5/22.
//  Copyright © 2022 Qiu Du. All rights reserved.
//

import Cocoa

@testable import TransVid_Forma

final class MockOpenPanel: OpenPanel {
    
    var stubRunModalResponse: NSApplication.ModalResponse = .OK
    var stubRunModalHandler: (() -> Void)?
    
    var url: URL?
    
    var allowedFileTypes: [String]?
    
    func runModal() -> NSApplication.ModalResponse {
        stubRunModalHandler?()
        return stubRunModalResponse
    }
}
