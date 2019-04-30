//
//  DisclosureViewController.swift
//  waveSDR
//
//  Copyright © 2019 GetOffMyHack. All rights reserved.
//

import Cocoa

class DisclosureViewController: NSViewController {
    
    let notify: NotificationCenter = NotificationCenter.default
    
    private static var disclosureFontSize:  CGFloat = 10.0
    private static var disclosureFont:      NSFont  = NSFont.boldSystemFont(ofSize: disclosureFontSize)
    
    var disclosureIsClosed:     Bool                = false
    var closingConstraint:      NSLayoutConstraint  = NSLayoutConstraint()
    var disclosureViewHeight:   CGFloat             = 0.0
    
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
        stackview.spacing       = 5.0
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
    
    
//    var headerView:         NSView      = NSView()
    var disclosedView:      NSView      = NSView() {
        didSet {

            self.mainStackView.addView(self.disclosedView, in: .top)
            
            // set up constraints for the disclosed
//            self.disclosedView.topAnchor.constraint(equalTo: self.headerStackView.bottomAnchor).isActive = true
            self.disclosedView.leadingAnchor.constraint(equalTo: self.mainStackView.leadingAnchor).isActive = true
            self.disclosedView.trailingAnchor.constraint(equalTo: self.mainStackView.trailingAnchor).isActive = true
            
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
        button.setButtonType(NSButton.ButtonType.onOff)
        button.bezelStyle   = NSButton.BezelStyle.inline
        button.controlSize  = .small
        button.title        = "Hide"
        button.font         = NSFont.systemFont(ofSize: 10.0)
        button.alignment    = NSTextAlignment.center
        return button
    }()
    
    //--------------------------------------------------------------------------
    //
    // MARK: - init / deinit
    //
    //--------------------------------------------------------------------------
    
    override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        // set up notification observers as soon as possible
//        initObservers()
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
//        notify.removeObserver(self)
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
//        self.view.layer?.backgroundColor = NSColor.black.cgColor
        
        headerStackView.setViews([disclosureLabel, disclosureButton], in: .leading)
        mainStackView.addView(headerStackView, in: .top)
        
        //----------------------------------------------------------------------
        //
        // build main stack view
        //
        //----------------------------------------------------------------------
        
//        audioOutStackView.setViews([audioOutHeaderStackView, highPassCutoffStackView, highPassBypassStackView], in: .top)
        
        
        self.view.addSubview(mainStackView)

        self.constrainViews()
        
   
        
    }
    
    @objc func toggleDisclosureView() {
        
        disclosureIsClosed.toggle();
        
        if(disclosureIsClosed == true) {
            disclosureButton.title = "Show"
            disclosedView.isHidden = true
//            disclosedView.bottomAnchor.constraint(equalTo: headerStackView.bottomAnchor).isActive = true

        } else {
            disclosureButton.title = "Hide"
            disclosedView.isHidden = false

//            disclosedView.bottomAnchor.constraint(equalTo: headerStackView.bottomAnchor).isActive = false

        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.disclosureButton.target = self
        self.disclosureButton.action = #selector(toggleDisclosureView)
    
        self.disclosureLabel.stringValue = self.description

        // Do view setup here.
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
        mainStackView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -5).isActive = true
        
        headerStackView.topAnchor.constraint(        equalTo: mainStackView.topAnchor       ).isActive = true
        headerStackView.leadingAnchor.constraint(    equalTo: mainStackView.leadingAnchor   ).isActive = true
        headerStackView.trailingAnchor.constraint(   equalTo: mainStackView.trailingAnchor  ).isActive = true
        
        disclosureLabel.topAnchor.constraint(equalTo: headerStackView.topAnchor).isActive = true
        disclosureLabel.leadingAnchor.constraint(equalTo: headerStackView.leadingAnchor, constant: 5.0).isActive = true
        
        disclosureButton.trailingAnchor.constraint(equalTo: headerStackView.trailingAnchor, constant: -5.0).isActive = true
        disclosureButton.lastBaselineAnchor.constraint(equalTo: disclosureLabel.lastBaselineAnchor).isActive = true
        disclosureButton.widthAnchor.constraint(equalToConstant: 45.0).isActive = true
        disclosureButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    }

}
