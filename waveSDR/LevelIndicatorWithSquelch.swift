//
//  LevelIndicatorWithSquelch.swift
//
//  Copyright © 2017 Justin England. All rights reserved.
//

import Cocoa

class LevelIndicatorWithSquelch: NSLevelIndicator {
    
    var useFilledRect:              Bool    = false
    
    var squelchValue:               Double  = -0.0 {
        didSet {

            // check if value to small
            if (squelchValue < self.minValue) {
                squelchValue = self.minValue
            }
            
            // check if value too large
            if(squelchValue > self.maxValue) {
                squelchValue = self.maxValue
            }
            
            // update view
            self.needsDisplay = true
        }
    }
    
    private let squelchLineWidth:   CGFloat = 3.0
    private var squelchLocation:    CGFloat = 0.0
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------
    
    override func draw(_ dirtyRect: NSRect) {
        
        super.draw(dirtyRect)
        
        calculateSquelchLine()
        
        //
        // create new background for the indicator's unfilled area
        //
        
        // new background color
        let newBackGroundColor = NSColor.black.withAlphaComponent(1.0)
        newBackGroundColor.setFill()
        
        // get size of unfilled region and fill with new background color
        let unfilledSquareStart     = calculateUnfilledSquareStart()
        var unfilledRect: CGRect    = dirtyRect
        unfilledRect.size.width     = unfilledRect.size.width - unfilledSquareStart
        unfilledRect.origin.x       = unfilledSquareStart
        unfilledRect                = unfilledRect.insetBy(dx: 0.0, dy: 1.0)
        NSBezierPath.fill(unfilledRect)
        
        // set color for squelch marker
        let squelchColor = NSColor.red.withAlphaComponent(1.0)
        
        // check to use fill or line for squelch level
//        if(useFilledRect == true) {
//            
//            // create rect and and fill
//            squelchColor.setFill()
//            var squelchRect: NSRect = dirtyRect
//            squelchRect.size.width = self.squelchLocation
//            squelchRect = squelchRect.insetBy(dx: 0, dy: 2.0)
//            
//            NSBezierPath.fill(squelchRect)
//            
//        } else {
        
            // draw squelch line
            squelchColor.set()
            let squelchLine: NSBezierPath = NSBezierPath()
            let squelchLineLocation = squelchLocation

            squelchLine.move(to: NSPoint(x: squelchLineLocation, y: 0.0))
            squelchLine.line(to: NSPoint(x: squelchLineLocation, y: dirtyRect.height))
            squelchLine.lineWidth = squelchLineWidth
            squelchLine.stroke()
            
//        }
        
    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------
    
    private func calculateSquelchLine() {
        
        // get the % of squelchValue to the range of values
        let range           = self.maxValue - self.minValue
        let valueInRange    = self.squelchValue - self.minValue
        let squelchPercent  = valueInRange / range
        
        // set the location of the squelch as a % of self's width
        self.squelchLocation   = CGFloat(squelchPercent) * self.bounds.width
    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------

    private func calculateUnfilledSquareStart() -> CGFloat {
        
        // get the % of unfilled area to the range of values
        let range           = self.maxValue     - self.minValue
        let valueInRange    = self.doubleValue  - self.minValue
        let unfilledPercent = valueInRange      / range
        
        // return start of unfilled region
        return CGFloat(unfilledPercent) * self.bounds.width
    }
    
}
