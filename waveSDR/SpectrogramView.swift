//
//  SpectrogramView.swift
//  waveSDR
//
//  Copyright © 2017 GetOffMyHack. All rights reserved.
//

import Cocoa

protocol SpectrogramViewDelegate {
    
    func getSpectrogramImage()->CGImage
    func togglePause()
    func goLive()
//    func getFrequencyAndSnapLineFor(point: NSPoint, inView: NSView) -> (frequency: Double, snapLine: Float)
    func isRunning()->Bool
    
}

class SpectrogramView: NSView {
    
    var delegate: SpectrogramViewDelegate!
    
    override var canDraw: Bool {
        get {
            return true
        }
    }

    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------
    
    override init(frame frameRect: NSRect) {
        
        super.init(frame: frameRect)
        
        // set up layer backed view
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.black.cgColor
        
        self.canDrawConcurrently = true

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------

    override func draw(_ dirtyRect: NSRect) {
        
        let image = self.delegate.getSpectrogramImage()

        if let graphicsContext = NSGraphicsContext.current?.cgContext {
            graphicsContext.draw(image, in: self.bounds)
        }
    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------

    func updateView() {
        self.needsDisplay = true
    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------
    
    override func mouseUp(with theEvent: NSEvent) {
        
        super.mouseUp(with: theEvent)
        
        if(theEvent.clickCount == 1) {

            self.delegate.togglePause()
            
        } else if(theEvent.clickCount == 2) {
            
            self.delegate.goLive()
            
        }
        
    }


    
}
