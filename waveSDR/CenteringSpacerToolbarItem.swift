//
//  CenteringSpacerToolbarItem.swift
//  waveSDR
//
// This NSToolbarItem subclass creates a blank spacer item that will consume
// enough space on the toolbar such that the following toolbar item will
// be centered within the toolbar frame.
//
// https://github.com/timothyarmes/TAAdaptiveSpaceItem
// http://stackoverflow.com/questions/6789257/can-i-center-a-nstoolbaritem-in-a-toolbar
//
//  Copyright © 2017 GetOffMyHack. All rights reserved.
//

import Cocoa


class CenteringSpacerToolbarItem: NSToolbarItem {
    
    private var _minSize: CGSize {

        // make sure that the toolbar exists and get the [NSToolbarItems] array
        guard let toolbarItems = self.toolbar?.items else {
            fatalError("Unable to get toolbar instance!!")
        }
        
        // get my index into the toolbarItems array
        let myIndex = toolbarItems.index(of: self)!
        
        // get the frame for the view's superview (an instance of NSToolbarItemViewer)
        let myFrame = self.view!.superview!.frame
        
        // get minSize from superclass
        var size = super.minSize
        
        if myFrame.origin.x > 0.0 {
            
            var space: CGFloat = 0
            
            // check to make sure the next item in the tool bar exists
            if (toolbarItems.count > myIndex + 1) {
                
                // get the next tool bar item and it's frame
                let nextToolbarItem = toolbarItems[myIndex + 1]
                let nextItemFrame   = nextToolbarItem.view!.superview!.frame
                
                // get the frame for the entire toolbar
                let toolbarFrame    = self.view!.superview!.superview!.frame;
                
                // calculate the space needed for my toolbaritem so that the
                // following toolbaritem is centered
                space = (toolbarFrame.size.width - nextItemFrame.size.width) / 2 - myFrame.origin.x - 6
               
                if( space < 0 ) {
                    space = 0
                }

                // update the width
                size.width = space
            }
        }
        
        // return the size needed so the next item is centered
        return size
        
    }
    
    private var _maxSize: NSSize {
        
        let size = super.maxSize
        return NSMakeSize(self._minSize.width, size.height);
        
    }
    
    //--------------------------------------------------------------------------
    //
    // updateWidth()
    //
    // computes the size needed and updates [min,max]Size
    //
    //--------------------------------------------------------------------------

    public func updateWidth() {
        
        self.minSize = _minSize
        self.maxSize = _maxSize

    }
    
    //--------------------------------------------------------------------------
    //
    // initCenteringSpacerItem()
    //
    // initalizes and sets the "dummy" view for this toolbar item
    //
    //--------------------------------------------------------------------------

    private func initCenteringSpacerItem() {
        
        self.label = ""
        self.paletteLabel = "Centering Space"
        
        let centeringView = CenteringSpacerToolbarItemView(frame: NSMakeRect(0.0, 0.0, 1.0, 1.0))
        centeringView.centeringSpacerItem = self
        self.view = centeringView
        
    }
    
    //--------------------------------------------------------------------------
    //
    // init()
    //
    //--------------------------------------------------------------------------

    override init(itemIdentifier: String) {
    
        super.init(itemIdentifier: itemIdentifier)
        initCenteringSpacerItem()
        
    }
    
    //--------------------------------------------------------------------------
    //
    // awakeFromNib()
    //
    //--------------------------------------------------------------------------

    override func awakeFromNib() {
        
        initCenteringSpacerItem()
        
    }
    

}

class CenteringSpacerToolbarItemView: NSView {
    
    weak var centeringSpacerItem: CenteringSpacerToolbarItem!
    
    override var acceptsFirstResponder: Bool {
        
        return false
        
    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------
    
    deinit {
        
        NotificationCenter.default.removeObserver(self)
        
    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------

    override func viewDidMoveToWindow() {
        
        NotificationCenter.default.addObserver(
            self,
            selector:   #selector(windowResized),
            name:       NSNotification.Name.NSWindowDidResize,
            object:     self.window
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector:   #selector(windowResized),
            name:       NSNotification.Name.NSWindowDidEnterFullScreen,
            object:     self.window
        )
        
    }
    
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------
    
    func windowResized() {

        self.centeringSpacerItem.updateWidth()
        
    }
    
}

