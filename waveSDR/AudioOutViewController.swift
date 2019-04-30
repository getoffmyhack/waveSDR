//
//  AudioOutViewController.swift
//  waveSDR
//
//  Created by Justin England on 3/14/19.
//  Copyright © 2019 GetOffMyHack. All rights reserved.
//

import Cocoa


class AudioOutViewController: DisclosureViewController {
    
    //--------------------------------------------------------------------------
    //
    // MARK: - properties
    //
    //--------------------------------------------------------------------------
    //--------------------------------------------------------------------------
    //
    // class constants
    //
    //--------------------------------------------------------------------------
    
    static var headerFontSize:  CGFloat = 10.0
    static var headerFont:      NSFont  = NSFont.boldSystemFont(ofSize: headerFontSize)
    
    static var labelFontSize:   CGFloat = 10.0
    static var labelFont:       NSFont  = NSFont.systemFont(ofSize: labelFontSize)
    
//    private let notify: NotificationCenter = NotificationCenter.default
    
    //--------------------------------------------------------------------------
    //
    // instance properties
    //
    //--------------------------------------------------------------------------
    
    override var description:   String {
        get {
            return "Audio Out"
        }
    }
    
    //--------------------------------------------------------------------------
    //
    // Exposed vars bound to views
    //
    //--------------------------------------------------------------------------
    
    @objc dynamic var highPassCutoff: Int         = 0 {
        
        didSet {
            let userInfo: [String : Any] = [highPassCutoffUpdatedKey: self.highPassCutoff]
            notify.post(name: .highPassCutoffUpdatedNotification, object: self, userInfo: userInfo)
        }
    }
    
    @objc dynamic var highPassBypass: Bool         = false {
        
        didSet {
            let userInfo: [String : Any] = [highPassBypassUpdatedKey: self.highPassBypass]
            notify.post(name: .highPassBypassUpdatedNotification, object: self, userInfo: userInfo)
        }
    }
    
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
    
    var audioOutStackView:        NSStackView = {
        let stackview           = NSStackView()
        stackview.wantsLayer    = true
        stackview.orientation   = .vertical
        stackview.spacing       = 5.0
//        stackview.translatesAutoresizingMaskIntoConstraints = false
//        stackview.layer?.backgroundColor = NSColor.red.cgColor
        return stackview
    }()
    
    //--------------------------------------------------------------------------
    //
    // container stack views
    //
    //--------------------------------------------------------------------------
    
    var audioOutHeaderStackView:     NSStackView = {
        let stackview = NSStackView()
        return stackview
    }()
    
    var highPassCutoffStackView:     NSStackView = {
        let stackview = NSStackView()
        return stackview
    }()
    
    var highPassBypassStackView:     NSStackView = {
        let stackview = NSStackView()
        return stackview
    }()
    
    //--------------------------------------------------------------------------
    //
    // MARK: - controls
    //
    //--------------------------------------------------------------------------
    
    //--------------------------------------------------------------------------
    //
    // main header label
    //
    //--------------------------------------------------------------------------
    
    var audioOutHeaderLabel:         NSTextField = {
        let label   = NSTextField(labelWithString: "Audio Out")
        label.font  = headerFont
        return label
    }()
    
    //--------------------------------------------------------------------------
    //
    // highpass cutoff frequency controls
    //
    //--------------------------------------------------------------------------
    
    var frequencyLabel:         NSTextField = {
        let label       = NSTextField(labelWithString: "High Pass Cutoff")
        label.font      = labelFont
        label.alignment = .right
        return label
    }()
    
    var frequencyTextField:     NSTextField = {
        let field           = NSTextField()
        field.controlSize   = .small
        field.font          = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        field.alignment     = .right
        return field
    }()
    
    var frequencyHzLabel:       NSTextField = {
        let label   = NSTextField(labelWithString: "Hz")
        label.font  = labelFont
        return label
    }()
    
    //--------------------------------------------------------------------------
    //
    // highpass cutoff frequency controls
    //
    //--------------------------------------------------------------------------
    
    var highpassBypassLabel:         NSTextField = {
        let label       = NSTextField(labelWithString: "High Pass Bypass")
        label.font      = labelFont
        label.alignment = .right
        return label
    }()
    
    var highpassBypassCheckbox:     NSButton = {
        let checkbox        = NSButton()
        checkbox.controlSize   = .small
        checkbox.title = ""
        checkbox.setButtonType(NSButton.ButtonType.switch)
        return checkbox
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
    
//    override func loadView() {
//
//        super.loadView()
//
//        // build stack views
//        setupStackViews()
//
//        // add subviews
//        self.mainStackView.addArrangedSubview(audioOutStackView)
//    }
    
    //--------------------------------------------------------------------------
    //
    // viewDidLoad()
    //
    //--------------------------------------------------------------------------
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Do view setup here.
        
        setupStackViews()
        self.disclosedView = audioOutStackView

        // add constraints
        setupConstraints()
        
        // config controls
        setupControls()
        
        // set up bindings
        setupBindings()
        
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
        
        //----------------------------------------------------------------------
        //
        // build internal container views
        //
        //----------------------------------------------------------------------
        
//        audioOutHeaderStackView.setViews([audioOutHeaderLabel], in: NSStackView.Gravity.leading)
        
        highPassCutoffStackView.setViews(
            [frequencyLabel, frequencyTextField, frequencyHzLabel],
            in: NSStackView.Gravity.leading
        )
        
        highPassBypassStackView.setViews(
            [highpassBypassLabel, highpassBypassCheckbox],
            in: NSStackView.Gravity.leading
        )
        
        //----------------------------------------------------------------------
        //
        // build main stack view
        //
        //----------------------------------------------------------------------
        
        audioOutStackView.setViews([/*audioOutHeaderStackView,*/ highPassCutoffStackView, highPassBypassStackView], in: .top)
        
    }
    
    //--------------------------------------------------------------------------
    //
    // setupConstraints()
    //
    // create all the constraints needed to place and align all subviews
    //
    //--------------------------------------------------------------------------
    
    func setupConstraints() {
        
        //----------------------------------------------------------------------
        //
        // constrain the main stack view
        //
        //----------------------------------------------------------------------
        
//        audioOutStackView.topAnchor.constraint(              equalTo: self.view.topAnchor        ).isActive = true
        audioOutStackView.leadingAnchor.constraint(          equalTo: self.disclosedView.leadingAnchor    ).isActive = true
        audioOutStackView.trailingAnchor.constraint(         equalTo: self.disclosedView.trailingAnchor   ).isActive = true
        
        // self.view.intrinsicContentSize
        
        //----------------------------------------------------------------------
        //
        // constrain container views within the main stack view
        //
        // stack views will automatically tightly hug the intrinsic size of
        // is included views.  These constraints make each stack view the
        // same width as it's containing stackview (it's superview)
        //
        //----------------------------------------------------------------------
        
//        audioOutHeaderStackView.leadingAnchor.constraint(   equalTo: audioOutStackView.leadingAnchor     ).isActive = true
        highPassCutoffStackView.leadingAnchor.constraint(   equalTo: audioOutStackView.leadingAnchor     ).isActive = true
        highPassBypassStackView.leadingAnchor.constraint(   equalTo: audioOutStackView.leadingAnchor     ).isActive = true
        
        //----------------------------------------------------------------------
        //
        // constrain controls within their stackviews
        //
        // each stackview is the same width as it's containing superview, these
        // constraints place the the control views within their containing
        // stackview
        //
        //----------------------------------------------------------------------
        
//        audioOutHeaderLabel.leadingAnchor.constraint(   equalTo: audioOutHeaderStackView.leadingAnchor,  constant:   5.0 ).isActive = true
//        audioOutHeaderLabel.trailingAnchor.constraint(  equalTo: audioOutHeaderStackView.trailingAnchor                  ).isActive = true
        
        frequencyLabel.leadingAnchor.constraint(        equalTo: highPassCutoffStackView.leadingAnchor,  constant:  20.0 ).isActive = true
        frequencyHzLabel.trailingAnchor.constraint(     equalTo: highPassCutoffStackView.trailingAnchor, constant: -10.0 ).isActive = true
        frequencyTextField.widthAnchor.constraint(                                   greaterThanOrEqualToConstant: 50.0 ).isActive = true
        
        highpassBypassLabel.trailingAnchor.constraint(equalTo: frequencyLabel.trailingAnchor).isActive = true
        highpassBypassCheckbox.centerYAnchor.constraint(equalTo: highpassBypassLabel.centerYAnchor).isActive = true
        
//        self.view.bottomAnchor.constraint( greaterThanOrEqualTo: audioOutStackView.bottomAnchor                          ).isActive = true
        
    }
    
    //--------------------------------------------------------------------------
    //
    // setupBindings()
    //
    // configure all the needed bindings for the views
    //
    //--------------------------------------------------------------------------
    
    func setupBindings() {
        
        frequencyTextField.bind(    NSBindingName.value,         to: self, withKeyPath: "highPassCutoff",    options: nil)
        highpassBypassCheckbox.bind(NSBindingName.value, to: self, withKeyPath: "highPassBypass", options: nil)
    }
    
    //--------------------------------------------------------------------------
    //
    // setupControls()
    //
    // do any last minute control configuration
    //
    //--------------------------------------------------------------------------
    
    func setupControls() {
        
        // add any control setup here
        
    }
}
