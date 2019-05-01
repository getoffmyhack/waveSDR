//
//  DisclosureViewController.swift
//  waveSDR
//
//  Copyright © 2019 GetOffMyHack. All rights reserved.
//

import Cocoa

class DisclosureViewController: NSViewController {
    
    let notify: NotificationCenter = NotificationCenter.default
    
    //--------------------------------------------------------------------------
    //
    // class constants
    //
    //--------------------------------------------------------------------------
    
    static let headerFontSize:  CGFloat     = 10.0
    static let headerFont:      NSFont      = NSFont.boldSystemFont(ofSize: headerFontSize)
    
    static let labelFontSize:   CGFloat     = 10.0
    static let labelFont:       NSFont      = NSFont.systemFont(ofSize: labelFontSize)
    
    static let disclosureFontSize:  CGFloat = 10.0
    static let disclosureFont:      NSFont  = NSFont.boldSystemFont(ofSize: disclosureFontSize)
    
    let labelWidth:      CGFloat     = 80.0
    
    var disclosureIsClosed:     Bool                = false

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
    
    let mainStackView:      NSStackView = {
        let stackview           = NSStackView()
        stackview.orientation   = .vertical
//        stackview.spacing       = 5.0
        stackview.translatesAutoresizingMaskIntoConstraints = false
        stackview.wantsLayer = true
//        stackview.layer?.backgroundColor = NSColor.blue.cgColor
        return stackview
    }()
    
    //--------------------------------------------------------------------------
    //
    // container stack views
    //
    //--------------------------------------------------------------------------
    
    var headerStackView:     NSStackView = {
        let stackview = NSStackView()
        stackview.wantsLayer = true
//        stackview.layer?.backgroundColor = NSColor.orange.cgColor
        return stackview
    }()
    
    var disclosedStackView:     NSStackView = {
        let stackview = NSStackView()
        stackview.wantsLayer = true
        return stackview
    }()
    
    var bottomLineStackView:    NSStackView = {
        let view = NSStackView()
        return view
    }()
    
    var disclosedView:      NSView      = NSView() {
        didSet {
            
            self.disclosedStackView.addView(self.disclosedView, in: .top)
            self.mainStackView.addView(self.disclosedStackView, in: .top)
            self.mainStackView.addView(self.bottomLineStackView, in: .top)
            
            // set up constraints for the disclosed
            self.disclosedView.topAnchor.constraint(equalTo: self.disclosedStackView.topAnchor).isActive = true
            self.disclosedView.leadingAnchor.constraint(equalTo: self.disclosedStackView.leadingAnchor).isActive = true
            self.disclosedView.trailingAnchor.constraint(equalTo: self.disclosedStackView.trailingAnchor).isActive = true
            
            self.disclosedStackView.topAnchor.constraint(equalTo: self.headerStackView.bottomAnchor, constant: 8.0).isActive = true
            self.disclosedStackView.leadingAnchor.constraint(equalTo: self.mainStackView.leadingAnchor).isActive = true
            self.disclosedStackView.trailingAnchor.constraint(equalTo: self.mainStackView.trailingAnchor).isActive = true
            
            
            
        }
    }
    
    //--------------------------------------------------------------------------
    //
    // MARK: - controls
    //
    //--------------------------------------------------------------------------
    
    //--------------------------------------------------------------------------
    //
    // disclosure header controls
    //
    //--------------------------------------------------------------------------
    
    
    let disclosureLabel:         NSTextField     = {
        let label   = NSTextField(labelWithString: "Disclosure")
        label.font  = disclosureFont
        return label
    }()
    
    var disclosureButton:           NSButton      = {
        let button = NSButton()
        button.setButtonType(.onOff)
        button.bezelStyle   = .inline
        button.controlSize  = .small
        button.title        = "Hide"
        button.font         = NSFont.systemFont(ofSize: 10.0)
        button.alignment    = NSTextAlignment.center
        return button
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
        self.view.wantsLayer = true
        
        headerStackView.setViews([disclosureLabel, disclosureButton], in: .leading)
        mainStackView.addView(headerStackView, in: .top)
        bottomLineStackView.addView(bottomLine, in: .center)

        // build main stack view
        self.view.addSubview(mainStackView)

        self.constrainViews()

    }
    
    @objc func toggleDisclosureView() {
        
        disclosureIsClosed.toggle();
        
        if(disclosureIsClosed == true) {
            
            disclosureButton.title = "Show"
            disclosedStackView.isHidden = true
            
        } else {
            
            disclosureButton.title = "Hide"
            disclosedStackView.isHidden = false

//            NSAnimationContext.runAnimationGroup({ (context) in
//                context.duration = 0.20
//                self.disclosedStackView.animator().isHidden = false
//            })
            
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.disclosureButton.target = self
        self.disclosureButton.action = #selector(toggleDisclosureView)
    
        self.disclosureLabel.stringValue = self.description

    }
    
    //--------------------------------------------------------------------------
    //
    // setupConstraints()
    //
    // create all the constraints needed to place and align all subviews
    //
    //--------------------------------------------------------------------------
    
    func constrainViews() {
        
        //----------------------------------------------------------------------
        //
        //
        //----------------------------------------------------------------------
        
        mainStackView.topAnchor.constraint(         equalTo: self.view.topAnchor            ).isActive = true
        mainStackView.leadingAnchor.constraint(     equalTo: self.view.leadingAnchor        ).isActive = true
        mainStackView.trailingAnchor.constraint(    equalTo: self.view.trailingAnchor       ).isActive = true
        mainStackView.bottomAnchor.constraint(      equalTo: self.view.bottomAnchor         ).isActive = true
        
        headerStackView.topAnchor.constraint(       equalTo: mainStackView.topAnchor        ).isActive = true
        headerStackView.leadingAnchor.constraint(   equalTo: mainStackView.leadingAnchor    ).isActive = true
        headerStackView.trailingAnchor.constraint(  equalTo: mainStackView.trailingAnchor   ).isActive = true
        
        disclosureLabel.topAnchor.constraint(       equalTo: headerStackView.topAnchor      ).isActive = true
        disclosureLabel.leadingAnchor.constraint(   equalTo: headerStackView.leadingAnchor, constant: 5.0).isActive = true
        
        disclosureButton.trailingAnchor.constraint(     equalTo: headerStackView.trailingAnchor, constant: -5.0).isActive = true
        disclosureButton.lastBaselineAnchor.constraint( equalTo: disclosureLabel.lastBaselineAnchor).isActive = true
        disclosureButton.widthAnchor.constraint(        equalToConstant: 40.0               ).isActive = true
        
        disclosureButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    }

}
