//
//  HardwareViewController.swift
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

class HardwareViewController: DisclosureViewController {
    
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

    @objc dynamic var sampleRateList:         [Int]       = []
    @objc dynamic var selectedSampleRate:     Int         = 0 {
        didSet {
            let userInfo: [String : Any] = [sampleRateUpdatedKey : self.selectedSampleRate]
            notify.post(name: .sampleRateUpdatedNotification, object: self, userInfo: userInfo)
        }
    }
    
    @objc dynamic var correctionValue:        Int         = 0 {
        didSet {
            let userInfo: [String : Any] = [correctionUpdatedKey : self.correctionValue]
            notify.post(name: .correctionUpdatedNotification, object: self, userInfo: userInfo)
        }
    }
    
    @objc dynamic      var deviceList:        [SDRDevice] = []
    @objc dynamic weak var selectedDevice:    SDRDevice? {
        didSet {
            let userInfo: [String : Any] = [sdrDeviceSelectedKey: self.selectedDevice!]
            notify.post(name: .sdrDeviceSelectedNotification, object: self, userInfo: userInfo)
            
            // update UI vars
            self.sampleRateList     = selectedDevice!.sampleRateList()
            self.selectedSampleRate = selectedDevice!.sampleRate()
            self.correctionValue    = selectedDevice!.frequencyCorrection()
        }
    }
    
    @objc dynamic var isRunning: Bool = false
    
    //--------------------------------------------------------------------------
    //
    // class constants
    //
    //--------------------------------------------------------------------------

//    private static var headerFontSize:  CGFloat     = 10.0
//    private static var headerFont:      NSFont      = NSFont.boldSystemFont(ofSize: headerFontSize)
//    
//    private static var labelFontSize:   CGFloat     = 10.0
//    private static var labelFont:       NSFont      = NSFont.systemFont(ofSize: labelFontSize)
//    
    //--------------------------------------------------------------------------
    //
    // instance properties
    //
    //--------------------------------------------------------------------------
    
    override var description:   String {
        get {
            return "Hardware"
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
    
    let hardwareStackView:      NSStackView = {
        let stackview = NSStackView()
        stackview.wantsLayer = true
        stackview.orientation = .vertical
        stackview.spacing      = 5.0
        stackview.translatesAutoresizingMaskIntoConstraints = false
        return stackview
    }()
    
    //--------------------------------------------------------------------------
    //
    // container stack views
    //
    //--------------------------------------------------------------------------

    let sdrHeaderStackView:     NSStackView = NSStackView()
    let sdrPopUpStackView:      NSStackView = NSStackView()
    let separatorStackView:     NSStackView = NSStackView()
    let detailsHeaderStackView: NSStackView = NSStackView()
    
    let sampleRateStackView:    NSStackView = NSStackView()
    let correctionStackView:    NSStackView = NSStackView()

    
    //--------------------------------------------------------------------------
    //
    // MARK: - controls
    //
    //--------------------------------------------------------------------------
    
    //--------------------------------------------------------------------------
    //
    // sdr list controls
    //
    //--------------------------------------------------------------------------
    
    let sdrHeaderLabel:             NSTextField     = {
        let label = NSTextField(labelWithString: "SDR Device")
        label.font = headerFont
        return label
    }()
    
    let sdrListPopUp:               NSPopUpButton   = {
        let control = NSPopUpButton()
        control.controlSize = .small
        control.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        control.setContentCompressionResistancePriority(NSLayoutConstraint.Priority.defaultLow, for: NSLayoutConstraint.Orientation.horizontal)
        return control
    }()
    
    let separatorLine:              NSBox           = {
        let box     = NSBox()
        box.boxType = .separator
        return box
    }()
    
    //--------------------------------------------------------------------------
    //
    // details controls
    //
    //--------------------------------------------------------------------------
    
    let detailsHeaderLabel:         NSTextField     = {
        let label   = NSTextField(labelWithString: "Device Details")
        label.font  = headerFont
        return label
    }()
    
    //--------------------------------------------------------------------------
    //
    // Sample Rate Selection
    //
    //--------------------------------------------------------------------------
    
    let sampleRateLabel:            NSTextField     = {
        let label       = NSTextField(labelWithString: "Sample Rate")
        label.font      = labelFont
        label.alignment = NSTextAlignment.right
        return label
    }()
    
    let sampleRatePopUp:            NSPopUpButton   = {
        let control         = NSPopUpButton()
        control.controlSize = .small
        control.font        = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        return control
    }()
    
    //--------------------------------------------------------------------------
    //
    // Frequency Correction Selection
    //
    //--------------------------------------------------------------------------
    
    let correctionLabel:            NSTextField     = {
        let label   = NSTextField(labelWithString: "Freq Correction")
        label.font  = labelFont
        return label
    }()
    
    let correctionTextField:        NSTextField     = {
        let field           = NSTextField()
        field.controlSize   = .small
        field.font          = labelFont
        field.alignment     = .right
        return field
    }()
    
    let correctionStepper:          NSStepper       = {
        let stepper         = NSStepper()
        stepper.controlSize = .small
        stepper.valueWraps  = false
        stepper.minValue    = -100
        stepper.maxValue    = 100
        return stepper
    }()
    
    let correctionPPMLabel:         NSTextField     = {
        let label   = NSTextField(labelWithString: "ppm")
        label.font  = labelFont
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
//        // add view
//        view.addSubview(hardwareStackView)
//
//    }
    
    //--------------------------------------------------------------------------
    //
    // viewDidLoad()
    //
    //--------------------------------------------------------------------------
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        setupStackViews()
        self.disclosedView = hardwareStackView
        
        // build constraints
        setupConstraints()
        
        // setup bindings
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

        sdrHeaderStackView.addView(     sdrHeaderLabel,     in: NSStackView.Gravity.leading)
        sdrPopUpStackView.addView(      sdrListPopUp,       in: NSStackView.Gravity.leading)
        separatorStackView.addView(     separatorLine,      in: NSStackView.Gravity.leading)
        detailsHeaderStackView.addView( detailsHeaderLabel, in: NSStackView.Gravity.leading)
        
        sampleRateStackView.setViews(
            [sampleRateLabel, sampleRatePopUp],
            in: NSStackView.Gravity.leading
        )
        
        correctionStackView.setViews(
            [correctionLabel, correctionTextField, correctionStepper, correctionPPMLabel],
            in: NSStackView.Gravity.leading
        )
        
        //----------------------------------------------------------------------
        //
        // build main stack view
        //
        //----------------------------------------------------------------------

        hardwareStackView.setViews(
            [/*sdrHeaderStackView,*/ sdrPopUpStackView, /* separatorStackView, detailsHeaderStackView,*/ sampleRateStackView, correctionStackView],
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
        
        //----------------------------------------------------------------------
        //
        // constrain the main stack view
        //
        //----------------------------------------------------------------------
    
//            hardwareStackView.topAnchor.constraint(             equalTo: self.view.topAnchor        ).isActive = true
            hardwareStackView.leadingAnchor.constraint(         equalTo: self.disclosedView.leadingAnchor    ).isActive = true
            hardwareStackView.trailingAnchor.constraint(        equalTo: self.disclosedView.trailingAnchor   ).isActive = true
        
        
        //----------------------------------------------------------------------
        //
        // constrain container views within the main stack view
        //
        //----------------------------------------------------------------------
        
//        sdrHeaderStackView.leadingAnchor.constraint(        equalTo: hardwareStackView.leadingAnchor    ).isActive = true
//        sdrHeaderStackView.trailingAnchor.constraint(       equalTo: hardwareStackView.trailingAnchor   ).isActive = true
        
//        sdrPopUpStackView.topAnchor.constraint(equalTo: hardwareStackView.bottomAnchor, constant: 10.0).isActive = true
        sdrPopUpStackView.leadingAnchor.constraint(         equalTo: hardwareStackView.leadingAnchor    ).isActive = true
        sdrPopUpStackView.trailingAnchor.constraint(        equalTo: hardwareStackView.trailingAnchor   ).isActive = true
        
//        separatorStackView.leadingAnchor.constraint(        equalTo: hardwareStackView.leadingAnchor    ).isActive = true
//        separatorStackView.trailingAnchor.constraint(       equalTo: hardwareStackView.trailingAnchor   ).isActive = true
        
//        detailsHeaderStackView.leadingAnchor.constraint(    equalTo: hardwareStackView.leadingAnchor    ).isActive = true
//        detailsHeaderStackView.trailingAnchor.constraint(   equalTo: hardwareStackView.trailingAnchor   ).isActive = true
        
        sampleRateStackView.leadingAnchor.constraint(       equalTo: hardwareStackView.leadingAnchor    ).isActive = true
        sampleRateStackView.trailingAnchor.constraint(      equalTo: hardwareStackView.trailingAnchor   ).isActive = true
        
        correctionStackView.leadingAnchor.constraint(       equalTo: hardwareStackView.leadingAnchor    ).isActive = true
        correctionStackView.trailingAnchor.constraint(      equalTo: hardwareStackView.trailingAnchor   ).isActive = true
        
        //----------------------------------------------------------------------
        //
        // constrain container views within the main stack view
        //
        // stack views will automatically tightly hug the intrinsic size of
        // is included views.  These constraints make each stack view the
        // same width as it's containing stackview (it's superview)
        //
        //----------------------------------------------------------------------

//        sdrHeaderLabel.leadingAnchor.constraint(        equalTo: sdrHeaderStackView.leadingAnchor,      constant:   5.0 ).isActive = true
//        sdrHeaderLabel.trailingAnchor.constraint(       equalTo: sdrHeaderStackView.trailingAnchor                      ).isActive = true
        
        sdrListPopUp.leadingAnchor.constraint(          equalTo: sdrPopUpStackView.leadingAnchor,       constant:  20.0 ).isActive = true
        sdrListPopUp.trailingAnchor.constraint(         equalTo: sdrPopUpStackView.trailingAnchor,      constant: -10.0 ).isActive = true
        
//        separatorLine.leadingAnchor.constraint(         equalTo: separatorStackView.leadingAnchor,      constant:  10.0 ).isActive = true
//        separatorLine.trailingAnchor.constraint(        equalTo: separatorStackView.trailingAnchor,     constant: -10.0 ).isActive = true
        
//        detailsHeaderLabel.leadingAnchor.constraint(    equalTo: detailsHeaderStackView.leadingAnchor,  constant:   5.0 ).isActive = true
//        detailsHeaderLabel.trailingAnchor.constraint(   equalTo: detailsHeaderStackView.trailingAnchor                  ).isActive = true
        
        sampleRateLabel.leadingAnchor.constraint(       equalTo: sampleRateStackView.leadingAnchor,     constant:  20.0 ).isActive = true
        sampleRatePopUp.trailingAnchor.constraint(      equalTo: sampleRateStackView.trailingAnchor,    constant: -10.0 ).isActive = true
        
        correctionLabel.widthAnchor.constraint(equalToConstant: 80.0).isActive = true
        correctionLabel.leadingAnchor.constraint(       equalTo: correctionStackView.leadingAnchor,     constant:  20.0 ).isActive = true
        correctionLabel.trailingAnchor.constraint(      equalTo: sampleRateLabel.trailingAnchor                         ).isActive = true
        correctionTextField.widthAnchor.constraint(                                              equalToConstant:  50.0 ).isActive = true
        correctionPPMLabel.trailingAnchor.constraint(   equalTo: correctionStackView.trailingAnchor,    constant: -10.0 ).isActive = true

//        self.view.bottomAnchor.constraint( greaterThanOrEqualTo: hardwareStackView.bottomAnchor,        constant:   5.0 ).isActive = true
        
    }

    //--------------------------------------------------------------------------
    //
    // setupBindinds()
    //
    // configure all the needed bindings for the views
    //
    //--------------------------------------------------------------------------
    
    func setupBindings() {
        
        let sdrListContentOptions: [NSBindingOption : Any] = [NSBindingOption(rawValue: NSBindingOption.nullPlaceholder.rawValue)         : "No SDR Devices Found"]
        let isNotNillEnableOption: [NSBindingOption : Any] = [NSBindingOption(rawValue: NSBindingOption.valueTransformerName.rawValue)    : NSValueTransformerName.isNotNilTransformerName]
        let negateBooleanOption:   [NSBindingOption : Any] = [NSBindingOption(rawValue: NSBindingOption.valueTransformerName.rawValue)    : NSValueTransformerName.negateBooleanTransformerName]

        sdrListPopUp.bind(          NSBindingName.content,           to: self, withKeyPath: "deviceList",            options: sdrListContentOptions)
        sdrListPopUp.bind(          NSBindingName.selectedObject,    to: self, withKeyPath: "selectedDevice",        options: nil)
        sdrListPopUp.bind(          NSBindingName.enabled,           to: self, withKeyPath: "selectedDevice",        options: isNotNillEnableOption)
        sdrListPopUp.bind(          NSBindingName.enabled,           to: self, withKeyPath: "isRunning",             options: negateBooleanOption)
        
        sampleRatePopUp.bind(       NSBindingName.content,           to: self, withKeyPath: "sampleRateList",        options: nil)
        sampleRatePopUp.bind(       NSBindingName.selectedObject,    to: self, withKeyPath: "selectedSampleRate",    options: nil)
        sampleRatePopUp.bind(       NSBindingName.enabled,           to: self, withKeyPath: "selectedDevice",        options: isNotNillEnableOption)
        
        correctionTextField.bind(   NSBindingName.value,             to: self, withKeyPath: "correctionValue",       options: nil)
        correctionTextField.bind(   NSBindingName.enabled,           to: self, withKeyPath: "selectedDevice",        options: isNotNillEnableOption)

        correctionStepper.bind(     NSBindingName.value,             to: self, withKeyPath: "correctionValue",       options: nil)
        correctionStepper.bind(     NSBindingName.enabled,           to: self, withKeyPath: "selectedDevice",        options: isNotNillEnableOption)

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
    
        // observe sdrDeviceListNotification when device list becomes available
        notify.addObserver(
            self,
            selector:   #selector(observedSdrDeviceListNotifcaiton(_:)),
            name:       .sdrDeviceListNotifcaiton,
            object:     nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector:   #selector(observedSDRStartedNotification(_:)),
            name:       .sdrStartedNotification,
            object:     nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector:   #selector(observedSDRStoppedNotification(_:)),
            name:       .sdrStoppedNotification,
            object:     nil
        )

    }
    
    //--------------------------------------------------------------------------
    //
    // MARK: - notification observers
    //
    // <observed> methods for notificaions from NotificationCenter
    //
    //--------------------------------------------------------------------------

    //--------------------------------------------------------------------------
    //
    // observedSdrDeviceListNotifcaiton()
    //
    // the list of sdr devices has been updated
    //
    //--------------------------------------------------------------------------

    @objc func observedSdrDeviceListNotifcaiton(_ notification: Notification) {
        
        if let userInfo = notification.userInfo {
            let sdrDeviceArray = userInfo[sdrDeviceListKey] as! [SDRDevice]
            self.deviceList = sdrDeviceArray
            
            // TODO: Replace with defaults
            if(deviceList.count > 0) {
                selectedDevice = deviceList[0]
            }
        }
        
    }
    
    //--------------------------------------------------------------------------
    //
    //  observedSDRStartedNotification()
    //
    //  SDR Started
    //
    //--------------------------------------------------------------------------
    
    @objc func observedSDRStartedNotification(_ notification: Notification) {
        
        self.isRunning = true
        
    }
    
    //--------------------------------------------------------------------------
    //
    //  observedSDRStoppedNotification()
    //
    //  SDR stopped
    //
    //--------------------------------------------------------------------------
    
    @objc func observedSDRStoppedNotification(_ notification: Notification) {
        
        self.isRunning = false
        
    }

    
}

