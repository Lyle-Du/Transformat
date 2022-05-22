//
//  OpenPanel.swift
//  TransVid FormaTests
//
//  Created by QIU DU on 22/5/22.
//  Copyright © 2022 Qiu Du. All rights reserved.
//

import Cocoa

protocol OpenPanel: AnyObject {
    var url: URL? { get }
    var allowedFileTypes: [String]? { get set }
    func runModal() -> NSApplication.ModalResponse
}

extension NSOpenPanel: OpenPanel {}
