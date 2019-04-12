//
//  DisclosureViewController.swift
//  waveSDR
//
//  Copyright © 2019 GetOffMyHack. All rights reserved.
//

import Cocoa

class DisclosureViewController: NSViewController {
    
    private static var disclosureFontSize:  CGFloat     = 12.0
    private static var disclosureFont:      NSFont      = NSFont.boldSystemFont(ofSize: disclosureFontSize)
    
    var disclosedView:                      NSView      = NSView()
    
    let mainStackView:      NSStackView = {
        let stackview           = NSStackView()
        stackview.wantsLayer    = true
        stackview.orientation   = .vertical
        stackview.spacing       = 5.0
        stackview.translatesAutoresizingMaskIntoConstraints = false
        return stackview
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
}
