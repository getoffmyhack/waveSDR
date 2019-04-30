//
//  SidebarViewController.swift
//  waveSDR
//
//  Copyright © 2017 GetOffMyHack. All rights reserved.
//

import Cocoa

class SidebarViewController: NSViewController {
    
    //--------------------------------------------------------------------------
    //
    // MARK: - properties
    //
    //--------------------------------------------------------------------------
    
    //--------------------------------------------------------------------------
    //
    //
    //--------------------------------------------------------------------------
    
    var lastSelectedIndex:              Int = 0
    @objc var selectedIndex:                  Int = 0 {
        didSet {
            
            let oldView = children[lastSelectedIndex].view
            let newView = children[selectedIndex].view
            
            self.containerView.replaceSubview(oldView, with: newView)
            self.constrainInContainerView(newView)
            
            lastSelectedIndex = selectedIndex
        }
    }
    
    //--------------------------------------------------------------------------
    //
    // class constants
    //
    //--------------------------------------------------------------------------
    
    static var headerFontSize:  CGFloat = 10.0
    static var headerFont:      NSFont  = NSFont.boldSystemFont(ofSize: headerFontSize)
    
    static var labelFontSize:   CGFloat = NSFont.smallSystemFontSize
    static var labelFont:       NSFont  = NSFont.systemFont(ofSize: labelFontSize)

    //--------------------------------------------------------------------------
    //
    // MARK: - container views
    //
    //--------------------------------------------------------------------------
    
    //--------------------------------------------------------------------------
    //
    // main container view
    //
    //--------------------------------------------------------------------------
    
    var sidebarStackView:       NSStackView = {
        let view            = NSStackView()
        view.wantsLayer     = true
        view.orientation    = .vertical
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    //--------------------------------------------------------------------------
    //
    // container stack views
    //
    //--------------------------------------------------------------------------
    
    var selectionStackView:     NSStackView = {
        let view = NSStackView()
        return view
    }()
    
    var separatorLineStackView: NSStackView = {
        let view = NSStackView()
        return view
    }()
    
    var containerViewStackView: NSStackView = {
        let view = NSStackView()
        return view
    }()
    
    var bottomLineStackView:    NSStackView = {
        let view = NSStackView()
        return view
    }()
    
    //--------------------------------------------------------------------------
    //
    // sidebar container view
    //
    //--------------------------------------------------------------------------
    
    var containerView:          NSView = {
        let view        = NSView()
        view.wantsLayer = true
        return view
    }()

    //--------------------------------------------------------------------------
    //
    // MARK: - controls
    //
    //--------------------------------------------------------------------------
    
    var selectionPopUp:         NSPopUpButton = {
        let control             = NSPopUpButton()
        control.controlSize     = .small
        control.font            = labelFont
        return control
    }()
    
    var separatorLine:          NSBox = {
        let box     = NSBox()
        box.boxType = .separator
        return box
    }()
    
    var bottomLine:             NSBox = {
        let box     = NSBox()
        box.boxType = .separator
        return box
    }()
    
    //--------------------------------------------------------------------------
    //
    // MARK: - init / deinit
    //
    //--------------------------------------------------------------------------
    
    override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {

        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        
    }
    
    //--------------------------------------------------------------------------
    //
    // MARK: - override methods
    //
    //--------------------------------------------------------------------------
    
    //--------------------------------------------------------------------------
    //
    // loadView()
    //
    //--------------------------------------------------------------------------
    
    override func loadView() {
            
        self.view = NSView()
        self.view.wantsLayer    = true
        
        // build stack views
        setupStackViews()
        
        // add views
        view.addSubview(sidebarStackView)
        
    }
    
    //--------------------------------------------------------------------------
    //
    // viewDidLoad()
    //
    //--------------------------------------------------------------------------
    
    override func viewDidLoad() {

        super.viewDidLoad()
        
        // Do view setup here.
        
        // build constraints
        setupConstraints()

        // setup view bindings
        setupBindings()

        // set up inital view
        let selectedView = self.children[selectedIndex].view
        containerView.addSubview(selectedView)
        constrainInContainerView(selectedView)
        
    }
    
    //--------------------------------------------------------------------------
    //
    // MARK: - setup methods
    //
    // <setup> methods are called during the various phases of loading
    // and displaying the view controller's views
    //
    //--------------------------------------------------------------------------
    
    //--------------------------------------------------------------------------
    //
    // setupStackViews()
    //
    // create the stack views that contain all the controls for the view
    //
    //--------------------------------------------------------------------------
    
    func setupStackViews() {
        
        selectionStackView.setViews(    [selectionPopUp],   in: .center)
        separatorLineStackView.setViews([separatorLine],    in: .center)
        containerViewStackView.setViews([containerView],    in: NSStackView.Gravity.leading)
        bottomLineStackView.setViews(   [bottomLine],       in: .center)
        
        sidebarStackView.setViews(
            [selectionStackView, separatorLineStackView, containerViewStackView, bottomLineStackView],
            in: .top
        )

    }
    
    //--------------------------------------------------------------------------
    //
    // setupConstraints()
    //
    // create all the constraints needed to place and align all subviews
    //
    //--------------------------------------------------------------------------
    
    func setupConstraints() {
        
        sidebarStackView.topAnchor.constraint(              equalTo: self.view.topAnchor                                ).isActive = true
        sidebarStackView.leadingAnchor.constraint(          equalTo: self.view.leadingAnchor                            ).isActive = true
        sidebarStackView.trailingAnchor.constraint(         equalTo: self.view.trailingAnchor                           ).isActive = true
//        sidebarStackView.bottomAnchor.constraint(           equalTo: self.view.bottomAnchor                             ).isActive = true
        
        selectionStackView.topAnchor.constraint(            equalTo: sidebarStackView.topAnchor,        constant:  10.0 ).isActive = true
        selectionStackView.leadingAnchor.constraint(        equalTo: sidebarStackView.leadingAnchor                     ).isActive = true
        selectionStackView.trailingAnchor.constraint(       equalTo: sidebarStackView.trailingAnchor                    ).isActive = true
        
        containerViewStackView.leadingAnchor.constraint(    equalTo: sidebarStackView.leadingAnchor                     ).isActive = true
        containerViewStackView.trailingAnchor.constraint(   equalTo: sidebarStackView.trailingAnchor                    ).isActive = true
        
        bottomLineStackView.bottomAnchor.constraint(        equalTo: sidebarStackView.bottomAnchor,     constant: -5.0 ).isActive = true
        
        selectionPopUp.leadingAnchor.constraint(            equalTo: selectionStackView.leadingAnchor,  constant:  20.0 ).isActive = true
        selectionPopUp.trailingAnchor.constraint(           equalTo: selectionStackView.trailingAnchor, constant: -10.0 ).isActive = true
        
        containerView.leadingAnchor.constraint(             equalTo: containerViewStackView.leadingAnchor               ).isActive = true
        containerView.trailingAnchor.constraint(            equalTo: containerViewStackView.trailingAnchor              ).isActive = true
        
    }
    
    //--------------------------------------------------------------------------
    //
    // setupBindings()
    //
    // configure all the needed bindings for the views
    //
    //--------------------------------------------------------------------------
    
    func setupBindings(){
        
        selectionPopUp.bind(NSBindingName.content,       to: self, withKeyPath: "childViewControllers",  options: nil)
        selectionPopUp.bind(NSBindingName.selectedIndex, to: self, withKeyPath: "selectedIndex",         options: nil)

    }
    
    //--------------------------------------------------------------------------
    //
    // MARK: - utility methods
    //
    //--------------------------------------------------------------------------
    
    //--------------------------------------------------------------------------
    //
    // constrainInContainerView()
    //
    // setup constraints when each time a new view is swapped in
    //
    //--------------------------------------------------------------------------
    
    func constrainInContainerView(_ targetView: NSView) {
        
        targetView.translatesAutoresizingMaskIntoConstraints = false
        
        targetView.topAnchor.constraint(                    equalTo: containerView.topAnchor        ).isActive = true
        targetView.leadingAnchor.constraint(                equalTo: containerView.leadingAnchor    ).isActive = true
        targetView.trailingAnchor.constraint(               equalTo: containerView.trailingAnchor   ).isActive = true
//        containerView.bottomAnchor.constraint( greaterThanOrEqualTo: targetView.bottomAnchor        ).isActive = true

        targetView.bottomAnchor.constraint(                 equalTo: containerView.bottomAnchor     ).isActive = true

    }
    
}
