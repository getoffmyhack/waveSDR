//
//  TunerViewController.swift
//  waveSDR
//
//  Copyright © 2017 GetOffMyHack. All rights reserved.
//


//------------------------------------------------------------------------------
//
// MARK: - Notifications
//
//------------------------------------------------------------------------------


import Cocoa

class TunerViewController: DisclosureViewController {
    
    //--------------------------------------------------------------------------
    //
    // MARK: - properties
    //
    //--------------------------------------------------------------------------
    
    //--------------------------------------------------------------------------
    //
    // Exposed vars bound to views
    //
    //--------------------------------------------------------------------------
    
    @objc dynamic var tunedFrequency: Int         = 0 {

        didSet(previousFrequency) {
            
            var newFrequency = self.tunedFrequency
            
            // check if new freq is greater than maximum freq
            if(self.tunedFrequency > self.maximumFrequency) {

                // if current freq is < than max freq, set new freq to max freq
                if(previousFrequency < self.maximumFrequency) {
                    newFrequency = self.maximumFrequency
                }
                    
                    // if current freq == max freq, then wrap to min freq
                else if(previousFrequency == self.maximumFrequency) {
                    newFrequency = self.minimumFrequency
                }
            }
                
            // check if new freq is less than minimum freq
            else if(self.tunedFrequency < self.minimumFrequency) {

                // if current freq is > than min freq, set new freq to min freq
                if(previousFrequency > self.minimumFrequency) {
                    newFrequency = self.minimumFrequency
                }
                    // if current freq == min freq, then wrap to max freq
                else if(previousFrequency == self.minimumFrequency) {
                    newFrequency = self.maximumFrequency
                }
            }

            let userInfo: [String : Any] = [frequencyUpdatedKey: newFrequency]
            notify.post(name: .frequencyUpdatedNotification, object: self, userInfo: userInfo)
            
            self.tunedFrequency = newFrequency
        }
    }
    
    var minimumFrequency:       Int             = 0 {
        didSet {
            self.frequencyFormatter.minimum = minimumFrequency as NSNumber?
        }
    }
    var maximumFrequency:       Int             = 5000000000 {
        didSet {
            self.frequencyFormatter.maximum = maximumFrequency as NSNumber?
        }
    }

    var frequencyFormatter:     NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.format = "0,000,000,000"
        formatter.numberStyle = NumberFormatter.Style.none
        formatter.thousandSeparator = "."
        return formatter
    }()
    
    @objc var demodModeList:          [String]    = ["AM", "NFM", "WFM"]
    @objc var demodSelected:          Int         = 1 {
        didSet {
            let userInfo: [String : Any] = [demodModeUpdatedKey: self.demodModeList[self.demodSelected] ]
            notify.post(name: .demodModeUpdatedNotification, object: self, userInfo: userInfo)
        }
    }
    
    var frequencyStep:          Double      = 1000.0 {
        didSet {
            let userInfo: [String : Any] = [frequencyStepUpdatedKey: self.frequencyStep]
            notify.post(name:.frequencyStepUpdatedNotification, object: self, userInfo: userInfo)
        }
    }
    
    @objc var stepBaseList:           [String]    = [ "Hz", "kHz", "MHz" ]
    @objc var stepSizeList:           [Double]    = [1.0, 2.5, 5.0, 6.25, 7.5, 8.33, 10.0, 12.5, 15.0, 20.0, 25.0, 50.0, 100.0]
    var stepBase:               Int         = 1000
    
    @objc var selectedStepSize:       Double         = 1.0 {
        didSet {
            frequencyStep = Double(stepBase) * selectedStepSize
        }
    }
    
    @objc var selectedStepBase:       String      = "kHz" {
        didSet {
            switch selectedStepBase {
            case "Hz":
                stepBase = 1
            case "kHz":
                stepBase = 1000
            case "MHz":
                stepBase = 1000000
            default:
                stepBase = 1
            }
            frequencyStep = Double(stepBase) * selectedStepSize
        }
    }

    @objc var converterFrequency: Int             = 0 {
        didSet {
            let userInfo: [String : Any] = [converterUpdatedKey: converterFrequency]
            notify.post(name: .converterUpdatedNotification, object: self, userInfo: userInfo)
        }
    }
    
    var converterFormatter:     NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.format = "0,000,000,000"
        formatter.numberStyle = NumberFormatter.Style.none
        formatter.thousandSeparator = "."
        return formatter
    }()
    
    //--------------------------------------------------------------------------
    //
    // class constants
    //
    //--------------------------------------------------------------------------
    
//    static var headerFontSize:  CGFloat = 10.0
//    static var headerFont:      NSFont  = NSFont.boldSystemFont(ofSize: headerFontSize)
//    
//    static var labelFontSize:   CGFloat = 10.0
//    static var labelFont:       NSFont  = NSFont.systemFont(ofSize: labelFontSize)
//    
    
    //--------------------------------------------------------------------------
    //
    // instance properties
    //
    //--------------------------------------------------------------------------
    
    override var description:   String {
        get {
            return "Tuner"
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
    
    var vfoStackView:           NSStackView = {
        let stackview           = NSStackView()
        stackview.wantsLayer    = true
        stackview.orientation   = .vertical
        stackview.spacing       = 5.0
        stackview.translatesAutoresizingMaskIntoConstraints = false
        return stackview
    }()
    
    //--------------------------------------------------------------------------
    //
    // container stack views
    //
    //--------------------------------------------------------------------------
    
    var vfoHeaderStackView:     NSStackView = {
        let stackview = NSStackView()
        return stackview
    }()
    
    var frequencyStackView:     NSStackView = {
        let stackview = NSStackView()
        return stackview
    }()
    
    var stepStackView:          NSStackView = {
        let stackview = NSStackView()
        return stackview
    }()
    
    var tuneStackView:          NSStackView = {
        let stackView = NSStackView()
        return stackView
    }()
    
    var demodStackView:         NSStackView = {
        let stackView = NSStackView()
        return stackView
    }()
    
    var converterStackView:     NSStackView = {
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
    
    var vfoHeaderLabel:         NSTextField = {
        let label   = NSTextField(labelWithString: "VFO")
        label.font  = headerFont
        return label
    }()
    
    //--------------------------------------------------------------------------
    //
    // frequency controls
    //
    //--------------------------------------------------------------------------
    
    var frequencyLabel:         NSTextField = {
        let label       = NSTextField(labelWithString: "Frequency")
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
    // tuning step size controls
    //
    //--------------------------------------------------------------------------
    
    var stepLabel:              NSTextField   = {
        let label       = NSTextField(labelWithString: "Step")
        label.font      = labelFont
        label.alignment = .right
        return label
    }()
    
    var stepSizePopUp:          NSPopUpButton = {
        let control         = NSPopUpButton()
        control.controlSize = .small
        control.alignment   = .center
        control.font        = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    var stepBasePopUp:          NSPopUpButton = {
        let control         = NSPopUpButton()
        control.controlSize = .small
        control.alignment   = .center
        control.font        = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    //--------------------------------------------------------------------------
    //
    // tuning buttons
    //
    //--------------------------------------------------------------------------
    
    var tuneLabel:              NSTextField   = {
        let label       = NSTextField(labelWithString: "Tune")
        label.font      = labelFont
        label.alignment = .right
        return label
    }()
    
    var tuneDownButton:         NSButton      = {
        let button = NSButton()
        button.setButtonType(NSButton.ButtonType.momentaryPushIn)
        button.bezelStyle   = NSButton.BezelStyle.rounded
        button.controlSize  = .small
        button.title        = "-"
        button.font         = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        button.alignment    = NSTextAlignment.center
        button.isContinuous = true
        
        return button
    }()

    var tuneUpButton:           NSButton      = {
        let button = NSButton()
        button.setButtonType(NSButton.ButtonType.momentaryPushIn)
        button.bezelStyle   = NSButton.BezelStyle.rounded
        button.controlSize  = .small
        button.title        = "+"
        button.font         = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        button.alignment    = NSTextAlignment.center
        button.isContinuous = true
        return button
    }()
    
    //--------------------------------------------------------------------------
    //
    // demod control
    //
    //--------------------------------------------------------------------------
    
    var demodLabel:             NSTextField   = {
        let label       = NSTextField(labelWithString: "Demod")
        label.font      = labelFont
        label.alignment = .right
        return label
    }()
    
    var demodSelction:          NSPopUpButton = {
        let control         = NSPopUpButton()
        control.alignment   = .center
        control.controlSize = .small
        control.font        = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        return control
    }()
    
    //--------------------------------------------------------------------------
    //
    // converter controls
    //
    //--------------------------------------------------------------------------
    
    var converterLabel:         NSTextField = {
        let label       = NSTextField(labelWithString: "Converter")
        label.font      = labelFont
        label.alignment = .right
        return label
    }()
    
    var converterTextField:     NSTextField = {
        let field           = NSTextField()
        field.controlSize   = .small
        field.font          = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        field.alignment     = .right
        
        return field
    }()
    
    var converterHzLabel:       NSTextField = {
        let label           = NSTextField(labelWithString: "Hz")
        label.font          = labelFont
        return label
    }()

    
    //--------------------------------------------------------------------------
    //
    // MARK: - init / deinit
    //
    //--------------------------------------------------------------------------
    
    override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        // set up notification observers as soon as possible
        initObservers()
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        notify.removeObserver(self)
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
//        self.view = NSView()
//        self.view.wantsLayer    = true
//
//        // build stack views
//        setupStackViews()
//
//        // add subviews
//        view.addSubview(vfoStackView)
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
        self.disclosedView = vfoStackView
        
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
        
        vfoHeaderStackView.setViews([vfoHeaderLabel], in: NSStackView.Gravity.leading)
        
        frequencyStackView.setViews(
            [frequencyLabel, frequencyTextField, frequencyHzLabel],
            in: NSStackView.Gravity.leading
        )
        
        stepStackView.setViews([stepLabel, stepSizePopUp, stepBasePopUp], in: NSStackView.Gravity.leading)
        
        tuneStackView.setViews([tuneLabel, tuneDownButton, tuneUpButton], in: NSStackView.Gravity.leading)
        
        demodStackView.setViews([demodLabel, demodSelction], in: NSStackView.Gravity.leading)
        
        converterStackView.setViews(
            [converterLabel, converterTextField, converterHzLabel],
            in: NSStackView.Gravity.leading
        )
        converterStackView.isHidden = true
        
        //----------------------------------------------------------------------
        //
        // build main stack view
        //
        //----------------------------------------------------------------------
        
        vfoStackView.setViews([/*vfoHeaderStackView,*/ frequencyStackView, stepStackView, tuneStackView, demodStackView, converterStackView], in: .top)

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
        
//        vfoStackView.topAnchor.constraint(              equalTo: self.view.topAnchor        ).isActive = true
        vfoStackView.leadingAnchor.constraint(          equalTo: self.disclosedView.leadingAnchor    ).isActive = true
        vfoStackView.trailingAnchor.constraint(         equalTo: self.disclosedView.trailingAnchor   ).isActive = true
        
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
        
//        vfoHeaderStackView.leadingAnchor.constraint(    equalTo: vfoStackView.leadingAnchor     ).isActive = true
        frequencyStackView.leadingAnchor.constraint(    equalTo: vfoStackView.leadingAnchor     ).isActive = true
        stepStackView.leadingAnchor.constraint(         equalTo: vfoStackView.leadingAnchor     ).isActive = true
        tuneStackView.leadingAnchor.constraint(         equalTo: vfoStackView.leadingAnchor     ).isActive = true
        demodStackView.leadingAnchor.constraint(        equalTo: vfoStackView.leadingAnchor     ).isActive = true
        converterStackView.leadingAnchor.constraint(    equalTo: vfoStackView.leadingAnchor     ).isActive = true
        
        //----------------------------------------------------------------------
        //
        // constrain controls within their stackviews
        //
        // each stackview is the same width as it's containing superview, these
        // constraints place the the control views within their containing 
        // stackview
        //
        //----------------------------------------------------------------------
        
//        vfoHeaderLabel.leadingAnchor.constraint(        equalTo: vfoHeaderStackView.leadingAnchor,  constant:   5.0 ).isActive = true
//        vfoHeaderLabel.trailingAnchor.constraint(       equalTo: vfoHeaderStackView.trailingAnchor                  ).isActive = true
        
        frequencyLabel.widthAnchor.constraint(equalToConstant: labelWidth).isActive = true
        frequencyLabel.leadingAnchor.constraint(        equalTo: frequencyStackView.leadingAnchor,  constant:  20.0 ).isActive = true
        frequencyHzLabel.trailingAnchor.constraint(     equalTo: frequencyStackView.trailingAnchor, constant: -10.0 ).isActive = true
        frequencyTextField.widthAnchor.constraint(                              greaterThanOrEqualToConstant: 100.0 ).isActive = true
        
        stepLabel.trailingAnchor.constraint(            equalTo: frequencyLabel.trailingAnchor                      ).isActive = true
        stepSizePopUp.widthAnchor.constraint(           equalTo: stepBasePopUp.widthAnchor                          ).isActive = true
        stepSizePopUp.leadingAnchor.constraint(         equalTo: frequencyTextField.leadingAnchor                   ).isActive = true
        stepBasePopUp.trailingAnchor.constraint(        equalTo: frequencyHzLabel.trailingAnchor                    ).isActive = true
        
        tuneLabel.trailingAnchor.constraint(            equalTo: frequencyLabel.trailingAnchor                      ).isActive = true
        tuneDownButton.widthAnchor.constraint(          equalTo: stepSizePopUp.widthAnchor                          ).isActive = true
        tuneDownButton.leadingAnchor.constraint(        equalTo: frequencyTextField.leadingAnchor                   ).isActive = true
        tuneUpButton.widthAnchor.constraint(            equalTo: tuneDownButton.widthAnchor                         ).isActive = true
        tuneUpButton.trailingAnchor.constraint(         equalTo: frequencyHzLabel.trailingAnchor                    ).isActive = true
        
        demodLabel.trailingAnchor.constraint(           equalTo: frequencyLabel.trailingAnchor                      ).isActive = true
        demodSelction.widthAnchor.constraint(           equalTo: stepSizePopUp.widthAnchor                          ).isActive = true
        
        converterLabel.leadingAnchor.constraint(        equalTo: converterStackView.leadingAnchor,  constant:  20.0 ).isActive = true
        converterHzLabel.trailingAnchor.constraint(     equalTo: converterStackView.trailingAnchor, constant: -10.0 ).isActive = true
        converterTextField.widthAnchor.constraint(                              greaterThanOrEqualToConstant: 100.0 ).isActive = true
        
//        self.view.bottomAnchor.constraint( greaterThanOrEqualTo: vfoStackView.bottomAnchor                          ).isActive = true

    }
    
    //--------------------------------------------------------------------------
    //
    // setupBindings()
    //
    // configure all the needed bindings for the views
    //
    //--------------------------------------------------------------------------
    
    func setupBindings() {

        frequencyTextField.bind(    .value,         to: self, withKeyPath: "tunedFrequency",    options: nil)
        stepSizePopUp.bind(         .contentValues, to: self, withKeyPath: "stepSizeList",      options: nil)
        stepSizePopUp.bind(         .selectedValue, to: self, withKeyPath: "selectedStepSize",  options: nil)
        stepBasePopUp.bind(         .contentValues, to: self, withKeyPath: "stepBaseList",      options: nil)
        stepBasePopUp.bind(         .selectedValue, to: self, withKeyPath: "selectedStepBase",  options: nil)
        demodSelction.bind(         .content,       to: self, withKeyPath: "demodModeList",     options: nil)
        demodSelction.bind(         .selectedIndex, to: self, withKeyPath: "demodSelected",     options: nil)
        converterTextField.bind(    .value,         to: self, withKeyPath: "converterFrequency",options: nil)
        
    }
    
    //--------------------------------------------------------------------------
    //
    // setupControls()
    //
    // do any last minute control configuration
    //
    //--------------------------------------------------------------------------
    
    func setupControls() {
    
        // add  number formatter to the frequency text field
        self.frequencyTextField.formatter = frequencyFormatter
        self.converterTextField.formatter = converterFormatter
        
        // set target / action for tuning buttons
        self.tuneDownButton.target = self
        self.tuneDownButton.action = #selector(frequencyStepDown)
        
        self.tuneUpButton.target   = self
        self.tuneUpButton.action   = #selector(frequencyStepUp)
    }
    
    //--------------------------------------------------------------------------
    //
    // MARK: - init methods
    //
    // <init> methods are called duing object instantiation
    //
    //--------------------------------------------------------------------------
    
    //--------------------------------------------------------------------------
    //
    // initObservers()
    //
    // set up notifcation observers
    //
    //--------------------------------------------------------------------------
    
    func initObservers() {
        
        // add observer for device selected notification
        notify.addObserver(
            self,
            selector:   #selector(observedSdrDeviceSelectedNotification(_:)),
            name:       .sdrDeviceSelectedNotification,
            object:     nil
        )

    }
    
    //--------------------------------------------------------------------------
    //
    // MARK: - action methods
    //
    // action methods called in response to user actions
    //
    //--------------------------------------------------------------------------

    //--------------------------------------------------------------------------
    //
    // frequencyStepDown()
    //
    // tune down button clicked, tune one frequencyStep down and check 
    // for edge cases
    //
    //--------------------------------------------------------------------------

    @objc func frequencyStepDown() {
        
        // create an Int value of proposed new frequency
        let newFrequency = self.tunedFrequency - Int(self.frequencyStep)
        self.tunedFrequency = newFrequency
    }
    
    //--------------------------------------------------------------------------
    //
    // frequencyStepUp()
    //
    // tune up button clicked, tune one frequencyStep up and check
    // for edge cases
    //
    //--------------------------------------------------------------------------

    @objc func frequencyStepUp() {
        
        // create an Int value of proposed new frequency
        let newFrequency = self.tunedFrequency + Int(self.frequencyStep)
        self.tunedFrequency = newFrequency
    }
    
    //--------------------------------------------------------------------------
    //
    // MARK: - notification observers
    //
    // <observed> methods are selectors for notificaions from NotifiationCenter
    //
    //--------------------------------------------------------------------------
    
    //--------------------------------------------------------------------------
    //
    // observedSdrDeviceSelectedNotification()
    //
    // the sdr device has been selected
    //
    //--------------------------------------------------------------------------

    @objc func observedSdrDeviceSelectedNotification(_ notification: Notification) {
                
        if let userInfo = notification.userInfo {
            let device = userInfo[sdrDeviceSelectedKey] as! SDRDevice
            self.minimumFrequency = device.minimumFrequency()
            self.maximumFrequency = device.maximumFrequency()
            // FIXME: This should be not be set from here
            device.tunedFrequency(frequency: self.tunedFrequency)
        } else {
            // FIXME: Reset controls to default state
        }
    }

}
