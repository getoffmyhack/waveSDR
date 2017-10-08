//
//  AnalyzerView.swift
//  waveSDR
//
//  Copyright © 2017 GetOffMyHack. All rights reserved.
//

import Cocoa

protocol AnalyzerViewDelegate {

    func getAnalyzerPath()->NSBezierPath
    func getTunedLocation(inView view: NSView)->Float
    func getFrequencyAndSnapLineFor(point: NSPoint, inView view: NSView) -> (frequency: Int, snapLine: Float)
    func getPowerFor(point: NSPoint, inView: NSView) -> Float
    func requestMixerChangeFrom(point: NSPoint, inView view: NSView)
    func requestFrequencyChangeFrom(point: NSPoint, inView: NSView)
    func requestFrequencyChangeWithScrollSpeed(_ speed: Int)
    func isRunning()->Bool
    
    //    func getPowerAt(point: NSPoint, inView: NSView)->Float
    
}

class AnalyzerView: NSView {

    override var isFlipped:Bool {
        get {
            return true
        }
    }
    
    override var canDraw: Bool {
        get {
            return true
        }
    }
    
    var delegate: AnalyzerViewDelegate!
    
    fileprivate         var mouseInView:            Bool    = false
    fileprivate         var mouseLocation:          NSPoint = NSPoint.zero
    fileprivate         var mouseFrequency:         Double  = 0.0
                        var tunedLineLocation:      CGFloat = 0.0
    
    fileprivate static  let resumeMouseLineTime:    TimeInterval    = 1.25
    fileprivate         var mouseLineTimer:         Timer           = Timer()
    fileprivate         var cursorIsHidden:         Bool            = false
    
    var lineColor: NSColor = NSColor.white

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
        
        self.tunedLineLocation = self.frame.width / 2

    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------

    override func draw(_ dirtyRect: NSRect) {
        
//        let points = self.delegate.getDisplayPoints()
        
        if(mouseInView == true) {
            
            // get power under mouse
//            var power     = self.delegate.getPowerAt(x: mouselocation.x)
//            unfilledRect                = unfilledRect.insetBy(dx: 0.0, dy: 1.0)

            // check if centered
            var centered: Bool = false
            if(mouseLocation.x == self.frame.width / 2) {
                centered = true
            }
            
            // draw mouse line
            let frequencyLine: NSBezierPath = NSBezierPath()
            if(centered) {
                let frequencyLineColor = NSColor.white.withAlphaComponent(1.0)
                frequencyLineColor.set()
            } else {
                let frequencyLineColor = NSColor.white.withAlphaComponent(0.6)
                frequencyLineColor.set()
            }
            
            frequencyLine.move(to: NSPoint(x: mouseLocation.x, y:  0 ))
            frequencyLine.line(to: NSPoint(x: mouseLocation.x, y: mouseLocation.y - 2.0))
            frequencyLine.move(to: NSPoint(x: mouseLocation.x, y: mouseLocation.y + 2.0))
            frequencyLine.line(to: NSPoint(x: mouseLocation.x, y: self.bounds.height   ))
            frequencyLine.lineWidth = 1.0
            frequencyLine.stroke()
            
            let crossLineMargin: CGFloat = 10.0
            let crossLine: NSBezierPath = NSBezierPath()
            let crossLineColor = NSColor.white.withAlphaComponent(0.6)
            crossLineColor.set()
            
            crossLine.move(to: NSPoint(x: mouseLocation.x - crossLineMargin,    y: mouseLocation.y))
            crossLine.line(to: NSPoint(x: mouseLocation.x - 2,                  y: mouseLocation.y))
            crossLine.move(to: NSPoint(x: mouseLocation.x + 2,                  y: mouseLocation.y))
            crossLine.line(to: NSPoint(x: mouseLocation.x + crossLineMargin,    y: mouseLocation.y))
            crossLine.lineWidth = 1.0
            crossLine.stroke()
            
            // create text attributes for frequency and power text
            
            let channelTextParagraphStyle = NSMutableParagraphStyle()
            channelTextParagraphStyle.alignment = .right
            
            var channelTextAttributes: [NSAttributedStringKey : Any]

            if(centered) {
                channelTextAttributes = [
                    NSAttributedStringKey(rawValue: NSAttributedStringKey.font.rawValue):            NSFont.boldSystemFont(ofSize: NSFont.smallSystemFontSize),
                    NSAttributedStringKey(rawValue: NSAttributedStringKey.paragraphStyle.rawValue):  channelTextParagraphStyle,
                    NSAttributedStringKey(rawValue: NSAttributedStringKey.foregroundColor.rawValue): NSColor.white.withAlphaComponent(1.00)
                ]
            } else {
                channelTextAttributes = [
                    NSAttributedStringKey(rawValue: NSAttributedStringKey.font.rawValue):            NSFont.boldSystemFont(ofSize: NSFont.smallSystemFontSize),
                    NSAttributedStringKey(rawValue: NSAttributedStringKey.paragraphStyle.rawValue):  channelTextParagraphStyle,
                    NSAttributedStringKey(rawValue: NSAttributedStringKey.foregroundColor.rawValue): NSColor.white.withAlphaComponent(0.85)
                ]
            }
            
            
            let margin: CGFloat  = 5.0

//            let channelDBValue                      = self.delegate!.getPowerFor(point: mouseLocation, inView: self)
//            let channelString:          NSString    = String(format: "%3.6f MHz\n@ -%3.2f dBFS", self.mouseFrequency, channelDBValue) as NSString

            let channelString:          NSString    = String(format: "%3.6f MHz", self.mouseFrequency) as NSString
            let channelStringSize:      NSSize      = channelString.size(withAttributes: channelTextAttributes)
            
            // calculate the size of the NSRect needed to contain the text string
            let channelTextRectWidth:   CGFloat = channelStringSize.width  + margin
            let channelTextRectHeight:  CGFloat = channelStringSize.height + margin
            let channelTextRectSize:    NSSize  = NSSize(width: channelTextRectWidth, height: channelTextRectHeight)
            
            //------------------------------------------------------------------
            //
            // calculate the location to position the channel / power text and
            // catch edge cases where the text would potentially pass the frame
            // of the view
            //
            //------------------------------------------------------------------
            
            var channelStringStartX = mouseLocation.x + margin
            
            // check if text is at right edge of view
            if( (channelStringStartX + channelStringSize.width + margin) > self.bounds.width ) {
                // if so, keep text at far right edge of view
                let startLocation = self.frame.width - margin - channelStringSize.width
                channelStringStartX = startLocation
            }
            
            var channelStringStartY = mouseLocation.y - channelStringSize.height - margin
            
            // check if text is at top of view
            if(channelStringStartY < margin) {
                // if so, keep text at top of view
                channelStringStartY = margin
            }
            
            let channelStringStartPoint: NSPoint = NSPoint(x: channelStringStartX, y: channelStringStartY)
            let channelTextRect: NSRect = NSRect(origin: channelStringStartPoint, size: channelTextRectSize)
            channelString.draw(in: channelTextRect, withAttributes: channelTextAttributes)

        }
        
        // draw tuned line
        
        let tunedLocation = CGFloat(self.delegate.getTunedLocation(inView: self))
        let tunedLine: NSBezierPath = NSBezierPath()
        let tunedLineColor = NSColor.red.withAlphaComponent(0.6)
        
        tunedLineColor.set()
        tunedLine.move(to: NSPoint(x: tunedLocation, y: 0.0))
        tunedLine.line(to: NSPoint(x: tunedLocation, y: self.frame.height))

        tunedLine.lineWidth = 1.0
        tunedLine.stroke()

        
        // draw spectrum line
        
        let spectrumLineColor: NSColor = NSColor.cyan
        spectrumLineColor.set()
        
        let path = self.delegate.getAnalyzerPath()
        path.stroke()

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

    override func cursorUpdate(with event: NSEvent) {
        super.cursorUpdate(with: event)
    }

    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------

    override func mouseEntered(with theEvent: NSEvent) {
        
        super.mouseEntered(with: theEvent)
        
        self.mouseInView = true
        self.mouseLocation = convert(theEvent.locationInWindow, from: nil)
        if(self.cursorIsHidden == false){
            NSCursor.hide()
            self.cursorIsHidden = true
        }
        
        if self.delegate.isRunning() == false {
            self.needsDisplay = true
        }
        
    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------

    override func mouseExited(with theEvent: NSEvent) {
        
        super.mouseExited(with: theEvent)
        
        self.mouseInView = false
        
        if(self.cursorIsHidden == true){
            NSCursor.unhide()
            self.cursorIsHidden = false
        }
        
        if(self.mouseLineTimer.isValid == true) {
            self.mouseLineTimer.invalidate()
        }
        
        if self.delegate.isRunning() == false {
            self.needsDisplay = true
        }
        
        
    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------

    override func mouseUp(with theEvent: NSEvent) {
        
        super.mouseUp(with: theEvent)
        
        self.mouseLocation = convert(theEvent.locationInWindow, from: nil)

        if(theEvent.clickCount == 1) {
            
            self.delegate.requestMixerChangeFrom(point: mouseLocation, inView: self)
        
            let (frequency, snapLine)   = self.delegate.getFrequencyAndSnapLineFor(point: mouseLocation, inView: self)
            let mouseOverChannel        = Double(frequency) / 1000000.0
        
            self.mouseFrequency         = mouseOverChannel
            self.mouseLocation.x        = CGFloat(snapLine)
            self.tunedLineLocation      = mouseLocation.x
            
        } else if(theEvent.clickCount == 2) {
            
            self.delegate.requestFrequencyChangeFrom(point: mouseLocation, inView: self)
            
            let (frequency, snapLine)   = self.delegate.getFrequencyAndSnapLineFor(point: mouseLocation, inView: self)
            let mouseOverChannel        = Double(frequency) / 1000000.0

            self.mouseFrequency         = mouseOverChannel
            self.mouseLocation.x        = CGFloat(snapLine)
            
        }

    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------

    override func mouseMoved(with theEvent: NSEvent) {
        super.mouseMoved(with: theEvent)
        
        if(self.mouseLineTimer.isValid == true) {
            self.mouseLineTimer.fire()
        }
        
        self.mouseLocation          = convert(theEvent.locationInWindow, from: nil)

        // get frequency under mouse
        let (frequency, snapLine)   = self.delegate.getFrequencyAndSnapLineFor(point: mouseLocation, inView: self)
        let mouseOverChannel        = Double(frequency) / 1000000.0

        self.mouseFrequency         = mouseOverChannel
        self.mouseLocation.x        = CGFloat(snapLine)
        
        if self.delegate.isRunning() == false {
            self.needsDisplay = true
        }
       
    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------

    override func scrollWheel(with event: NSEvent) {
        
        if(event.phase == NSEvent.Phase.began) {
            if(self.mouseLineTimer.isValid == true) {
                self.mouseLineTimer.invalidate()
            }
            self.mouseInView = false
        }
        
        if(event.momentumPhase == NSEvent.Phase.began) {
            if(self.mouseLineTimer.isValid == true) {
                self.mouseLineTimer.invalidate()
            }
        }
        
        if(event.phase == NSEvent.Phase.ended || event.momentumPhase == NSEvent.Phase.ended) {
            
            if(self.mouseLineTimer.isValid == true) {
                self.mouseLineTimer.invalidate()
            }
            
            self.mouseLineTimer = Timer.scheduledTimer(
                timeInterval:   1.0,
                target:         self,
                selector:       #selector(resumeMouseLineAfterScroll),
                userInfo:       nil,
                repeats:        false
            )
        }

        let scrollSpeed = Int(ceil(abs(event.deltaX / 2.0)))
        if (event.deltaX < 0) {
            self.delegate.requestFrequencyChangeWithScrollSpeed(scrollSpeed)
        } else if (event.deltaX > 0) {
            self.delegate.requestFrequencyChangeWithScrollSpeed(-scrollSpeed)
        }
    
    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------

    @objc func resumeMouseLineAfterScroll() {
        
        let (frequency, snapLine) = self.delegate.getFrequencyAndSnapLineFor(point: mouseLocation, inView: self)
        let mouseOverChannel = Double(frequency) / 1000000.0
        
        self.mouseFrequency  = mouseOverChannel
        self.mouseLocation.x = CGFloat(snapLine)

        self.mouseInView = true
        
    }
}
