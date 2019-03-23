//
//  AppDelegate.swift
//  waveSDR
//
//  Copyright © 2017 GetOffMyHack. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var windowControllers: [MainWindowController] = []

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication)-> Bool {
     
        return true
    
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        // Insert code here to initialize your application
        
//        mainWindowController = MainWindowController()
//        mainWindowController?.showWindow(self)

        addWindowController()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    // MARK: - Helpers
    
    func addWindowController() {
        
        let windowController = MainWindowController()
        windowController.showWindow(self)
        windowControllers.append(windowController)
        
    }
    
    // MARK - Actions
    
    @IBAction func displayNewWindow(_ send: NSMenuItem) {
        
        addWindowController()
    }


}

