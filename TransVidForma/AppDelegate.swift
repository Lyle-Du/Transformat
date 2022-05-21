//
//  AppDelegate.swift
//  Transformat
//
//  Created by QIU DU on 18/4/22.
//

import Cocoa

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    
    private let windowController = MainWindowViewController()
    private let mainViewController = MainViewController()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        windowController.viewModel = MainWindowViewModel()
        mainViewController.viewModel = MainViewModel()
        windowController.loadWindow(contentViewController: mainViewController)
        windowController.window?.makeKeyAndOrderFront(nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        windowController.window?.makeKeyAndOrderFront(nil)
        return true
    }
}

