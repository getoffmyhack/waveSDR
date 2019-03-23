//
//  RadioDisplayViewController.swift
//  waveSDR
//
//  Copyright © 2017 GetOffMyHack. All rights reserved.
//


import Cocoa

class RadioDisplayViewController: NSViewController {
    
    var spectrumView: NSView!

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

    weak var selectedDevice:        SDRDevice? {
        didSet {
            self.selectedDeviceName = selectedDevice!.description
        }
    }
    
    @objc dynamic var selectedDeviceName: String  = "No SDR Device Selected"
    
    @objc dynamic var displayFrequency:   Int = 0
    
    var tunedFrequency:             Int = 0 {
        didSet {
            self.displayFrequency = self.tunedFrequency + self.oscillatorFrequency + self.converterFrequency
        }
    }
    
    var oscillatorFrequency:        Int = 0 {
        didSet {
            self.displayFrequency = self.tunedFrequency + self.oscillatorFrequency + self.converterFrequency
        }
    }
    
    var converterFrequency:         Int = 0 {
        didSet {
            self.displayFrequency = self.tunedFrequency + self.oscillatorFrequency + self.converterFrequency
        }
    }
    
    @objc dynamic var tone:               Double  = 0.0
    @objc dynamic var channelName:        String  = ""
    @objc dynamic var minDBFSValue:       Double  = -128.0
    @objc dynamic var maxDBFSValue:       Double  =    0.0
    @objc dynamic var signalValue:        Float   = -128.0

    @objc dynamic var squelchPercent:     String  = "@ 100%"
    @objc dynamic var squelchValue:       Float   = 0.00 {
        didSet {
    
            // update level indicator
            self.signalLevelIndicator.squelchValue = Double(self.squelchValue)
    
            // post squelch updated message
            let userInfo: [String : Any] = [squelchUpdatedKey : self.squelchValue]
            notify.post(name: Notification.Name(rawValue: squelchUpdatedNotification), object: self, userInfo: userInfo)
        }
    }
    
    @objc dynamic var gainSliderMin:      Int     = 0
    @objc dynamic var gainSliderMax:      Int     = 0
    @objc dynamic var gainSliderString:   String  = "0.0"
    @objc dynamic var gainSliderRawValue: Int     = 0 {
        didSet {
            if(gainSliderRawValue == gainSliderMax) {
                
                self.gainSliderString   = "Auto"
                self.gainAutoModeOn     = true
                self.gainDBDisplayLabel.isHidden = true
                
                // post auto gain message
                let userInfo: [String : Any] = [tunerAutoGainUpdatedKey : self.gainAutoModeOn]
                notify.post(name: Notification.Name(rawValue: tunerAutoGainUpdatedNotification), object: self, userInfo: userInfo)
                
            } else {
                
                if(gainLastRawValue == gainSliderMax) {
                    self.gainAutoModeOn = false
                    self.gainDBDisplayLabel.isHidden = false
                    
                    // post manual gain message
                    let userInfo: [String : Any] = [tunerAutoGainUpdatedKey : self.gainAutoModeOn]
                    notify.post(name: Notification.Name(rawValue: tunerAutoGainUpdatedNotification), object: self, userInfo: userInfo)
                }
                let gainValue       = self.gainValueList[gainSliderRawValue]
                let gainFloatValue  = Float(gainValue) / 10.0
                gainSliderString    = String(gainFloatValue) //+ " dB"
                
                // post set gain message
                let userInfo = [tunerGainUpdatedKey : gainValue]
                notify.post(name: Notification.Name(rawValue: tunerGainUpdatedNotification), object: self, userInfo: userInfo)
                
            }
            gainLastRawValue    = gainSliderRawValue
        }
    }
    
    var gainLastRawValue:           Int     = 0
    var gainAutoModeOn:             Bool    = false
    var gainValueList:              [Int]   = [] {
        didSet {
            let gainCount                       = gainValueList.count
            self.gainSliderMax                  = gainCount
            self.gainSliderRawValue             = gainCount
            self.gainSlider.numberOfTickMarks   = gainCount + 1 // add one for the "AUTO" setting
        }
    }
    
    
    

    //--------------------------------------------------------------------------
    //
    // class constants
    //
    //--------------------------------------------------------------------------
    
    private static let displayFontColor:    NSColor = NSColor.white.withAlphaComponent(0.95)
    private static let displayFontSize:     CGFloat = 11.0
    
    private static let displayFont:         NSFont  = {
        let font = NSFont(name: "Menlo", size: displayFontSize)
        return font!
    }()
    
    private static let digitFont:           NSFont  = {
//        let font = NSFont.userFixedPitchFont(ofSize: 10.5)
        let font = NSFont(name: "Menlo", size: displayFontSize)
        return font!
    }()
    
    private static let frequencyFont:       NSFont  = {
        let font = NSFont(name: "Enhanced LED Board-7", size: 35.0)
        return font!
    }()
    
    //
    // properties
    //
    
    private let notify = NotificationCenter.default
    
    //--------------------------------------------------------------------------
    //
    // MARK: - container views
    //
    //--------------------------------------------------------------------------
    
    
    //
    // the radioStackView contains the "display" and the "control" stacks
    //
    
    var radioStackView:             NSStackView = {
        let stackView           = NSStackView()
        stackView.wantsLayer    = true
        stackView.orientation   = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    //
    // place the display stackview within a simple container view to
    // add visual effects
    //
    
    var displayContainerView:       NSView = {
        let displayView                     = NSView()
        displayView.wantsLayer              = true
        displayView.layer?.backgroundColor  = NSColor.black.cgColor
        displayView.layer?.cornerRadius     = 10.0
        //displayView.translatesAutoresizingMaskIntoConstraints = false
        return displayView
    }()

    //
    // all components of the display and control views are
    // collected into stack views
    //
    
    var displayStackView:           NSStackView = {
        let stackView           = NSStackView()
        stackView.wantsLayer    = true
        stackView.distribution  = NSStackView.Distribution.fillEqually
        stackView.spacing       = 8.0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    var controlStackView:           NSStackView = {
        let stackView                   = NSStackView()
        stackView.wantsLayer            = true
        stackView.layer?.cornerRadius   = 10
        stackView.layer?.borderColor    = NSColor.lightGray.cgColor
        stackView.layer?.borderWidth    = 1
        return stackView
    }()
    
    //
    // inside the display and control stack views are
    // embedded stack views which create the display and control
    // views' content
    //
    
    // display stack views
    var frequencyStackView:         NSStackView = {
        let stackView           = NSStackView()
        stackView.wantsLayer    = true
        stackView.orientation   = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    var infoDisplayStackView:       NSStackView = {
        let stackView           = NSStackView()
        stackView.wantsLayer    = true
        stackView.orientation   = .vertical
        stackView.spacing       = 0.0
        return stackView
    }()

    var squelchStackView:           NSStackView = {
        let stackView           = NSStackView()
        stackView.wantsLayer    = true
        return stackView
    }()
    
    var signalStackView:            NSStackView = {
        let stackView           = NSStackView()
        stackView.wantsLayer    = true
        return stackView
    }()
    
    var gainStackView:              NSStackView = {
        let stackView           = NSStackView()
        stackView.wantsLayer    = true
        return stackView
    }()
    
    var toneStackView:              NSStackView = {
        let stackView           = NSStackView()
        stackView.wantsLayer    = true
        return stackView
    }()

    
    var signalLevelStackView:       NSStackView = {
        let stackView           = NSStackView()
        stackView.wantsLayer    = true
        return stackView
    }()
    
    // control stack views
    var squelchControlStackView:    NSStackView = {
        let stackView           = NSStackView()
        stackView.wantsLayer    = true
        return stackView
    }()
    
    var gainControlStackView:       NSStackView = {
        let stackView           = NSStackView()
        stackView.wantsLayer    = true
        return stackView
    }()
    
    //--------------------------------------------------------------------------
    //
    // MARK: - controls
    //
    //--------------------------------------------------------------------------
    
    var frequencyLabel:             NSTextField = {
        let label           = NSTextField(labelWithString: "")
        label.textColor     = displayFontColor
        label.font          = frequencyFont
        label.wantsLayer    = true
//        label.setContentCompressionResistancePriority(NSLayoutPriorityDefaultLow + 2, for: .horizontal)
        return label
    }()
    
    var deviceLabel:                NSTextField = {
        let label       = NSTextField(labelWithString: "")
        label.textColor = displayFontColor
        label.font      = displayFont
        label.setContentCompressionResistancePriority(NSLayoutConstraint.Priority.defaultLow, for: .horizontal)
        return label
    }()
    
    var channelNameLabel:           NSTextField = {
        let fontManager = NSFontManager.shared
        let font        = fontManager.convert(NSFont.userFixedPitchFont(ofSize: 15.0)!, toHaveTrait: .italicFontMask)
        let label       = NSTextField(labelWithString: "")
        label.textColor = displayFontColor
        label.font      = font
        return label
    }()
    
    var squelchDisplayLabel:        NSTextField = {
        let label       = NSTextField(labelWithString: "Squelch:")
        label.textColor = displayFontColor
        label.font      = displayFont
        return label
    }()
    
    var squelchValueDisplayLabel:   NSTextField = {
        let formatter           = NumberFormatter()
        formatter.format        = "##0.00"
        formatter.numberStyle   = .decimal
        let label               = NSTextField(labelWithString: "")
        label.textColor         = displayFontColor
        label.font              = digitFont
        label.alignment         = .right
        label.formatter         = formatter
        return label
    }()
    
    var squelchDBFSDisplayLabel:    NSTextField = {
        let label       = NSTextField(labelWithString: "dBFS")
        label.textColor = displayFontColor
        label.font      = displayFont
        return label
    }()
    
    var squelchPercentDisplayLabel: NSTextField = {
        let label       = NSTextField(labelWithString: "")
        label.textColor = displayFontColor
        label.font      = displayFont
        return label
    }()
    
    var gainDisplayLabel:           NSTextField = {
        let label       = NSTextField(labelWithString: "RF Gain:")
        label.textColor = displayFontColor
        label.font      = displayFont
        return label
    }()
    
    var gainValueDisplayLabel:      NSTextField = {
        let label       = NSTextField(labelWithString: "")
        label.textColor = displayFontColor
        label.font      = digitFont
        label.alignment = .right
        return label
    }()
    
    var gainDBDisplayLabel:         NSTextField = {
        let label       = NSTextField(labelWithString: "dB")
        label.textColor = displayFontColor
        label.font      = displayFont
        return label
    }()

    var signalDisplayLabel:         NSTextField = {
        let label       = NSTextField(labelWithString: "Signal:")
        label.textColor = displayFontColor
        label.font      = displayFont
        return label
    }()
    
    var signalValueDisplayLabel:    NSTextField = {
        let formatter               = NumberFormatter()
        formatter.format            = "##0.00"
        formatter.numberStyle       = .decimal
        let label                   = NSTextField(labelWithString: "")
        label.textColor             = displayFontColor
        label.font                  = digitFont
        label.alignment             = .right
        label.formatter             = formatter
        label.canDrawConcurrently   = true
        return label
    }()
    
    var signalDBFSDisplayLabel:     NSTextField = {
        let label       = NSTextField(labelWithString: "dBFS")
        label.textColor = displayFontColor
        label.font      = displayFont
        return label
    }()
    
    var toneDisplayLabel:           NSTextField = {
        let label       = NSTextField(labelWithString: "Tone:")
        label.textColor = displayFontColor
        label.font      = displayFont
        return label
    }()
    
    var toneValueDisplayLabel:      NSTextField = {
        let label       = NSTextField(labelWithString: "")
        label.textColor = displayFontColor
        label.font      = digitFont
        label.alignment = .right
        return label
    }()
    
    var toneHZDisplayLabel:         NSTextField = {
        let label       = NSTextField(labelWithString: "Hz")
        label.textColor = displayFontColor
        label.font      = displayFont
        return label
    }()

    
//------------------------------------------------------------------------------
//
// MARK: - control views
//
//------------------------------------------------------------------------------
    
    var squelchSliderLabel:         NSTextField = {
        let label           = NSTextField(labelWithString: "Squelch")
        label.font          = NSFont.systemFont(ofSize: 12)
        return label
    }()
    
    var squelchSlider :             NSSlider    = {
        let slider          = NSSlider()
        slider.controlSize  = .small
        return slider
    }()

    var gainSliderLabel:            NSTextField = {
        let label           = NSTextField(labelWithString: "RF Gain")
        label.font          = NSFont.systemFont(ofSize: 12)
        return label
    }()

    var gainSlider :                NSSlider    = {
        let slider          = NSSlider()
        slider.controlSize  = .small
        slider.allowsTickMarkValuesOnly = true
        return slider
    }()
    
    var separatorLine1:             NSBox       = {
        let box     = NSBox()
        box.boxType = .separator
        return box
    }()
    
    var separatorLine2:             NSBox       = {
        let box     = NSBox()
        box.boxType = .separator
        return box
    }()
    
    var signalLevelIndicator:       LevelIndicatorWithSquelch   = {
        let signal                  = LevelIndicatorWithSquelch()
        signal.levelIndicatorStyle  = .continuousCapacity
        signal.criticalValue        = -10.0
        signal.warningValue         = -30.0
        signal.canDrawConcurrently  = true
        return signal
    }()
    
    //--------------------------------------------------------------------------
    //
    // MARK: - init / deinit
    //
    //--------------------------------------------------------------------------
    
    override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
                
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        // setup notification observers
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
    //
    // override loadView() to build view hierarchy and set up both 
    // the display view and control view
    //
    
    override func loadView() {
        
        self.view = NSView()
        
        // build view hierarchy
        setupStackViews()
        
        setupViewHierarchy()

    }
    
    //--------------------------------------------------------------------------
    //
    // viewDidLoad()
    //
    //--------------------------------------------------------------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do view setup here.
        
        // setup view constraints
        setupConstraints()
        
        // bind view properties
        setupBindings()
        
        // set up controls
        setupControls()
    
        // set up some inital values
        squelchValue = -128.0   // this will later be replaced with defaults
        
    }
    
    ///--------------------------------------------------------------------------
    //
    // MARK: - setup methods
    //
    // <setup> methods are called during the various phases of loading
    // and displaying the view controller's views
    //
    //--------------------------------------------------------------------------
    
    //--------------------------------------------------------------------------
    //
    // setupStackView()
    //
    // creates the NSStackView containing the controls found in the
    // "front panel display" portion of the view
    //
    //--------------------------------------------------------------------------
    
    func setupStackViews() {
        
        //
        // embedded function for building stack view's cliping resistance
        // and visibility priority
        //
        
        func configInfoStackViewClippingAndDetatching(_ stackView: NSStackView) {
            
            stackView.setClippingResistancePriority(NSLayoutConstraint.Priority(rawValue: NSLayoutConstraint.Priority.RawValue(Int(NSLayoutConstraint.Priority.defaultLow.rawValue) - 1)), for: .horizontal)

            
//            for myView in stackView.views {
//                let myViewIndex = stackView.views.index(of: myView)!
//                let priority = NSStackViewVisibilityPriorityDetachOnlyIfNecessary - Float(myViewIndex)
//
////                 make the first two views equal priority so they detatch together
//                stackView.setVisibilityPriority(myViewIndex == 0 ? priority - 1 : priority, for: myView)
//            }

        }
        
        // build stack view for the frequency and device labels
        frequencyStackView.addView(frequencyLabel,              in: .top)
        frequencyStackView.addView(signalLevelStackView,        in: .top)
        
        // build stack view that contains all labels to display squelch data
        squelchStackView.addView(squelchDisplayLabel,           in: .center)
        squelchStackView.addView(squelchValueDisplayLabel,      in: .center)
        squelchStackView.addView(squelchDBFSDisplayLabel,       in: .center)
        squelchStackView.addView(squelchPercentDisplayLabel,    in: .center)
        configInfoStackViewClippingAndDetatching(squelchStackView)
        
        // build stack view that contains all labels for signal data
        signalStackView.addView(signalDisplayLabel,             in: NSStackView.Gravity.leading)
        signalStackView.addView(signalValueDisplayLabel,        in: NSStackView.Gravity.leading)
        signalStackView.addView(signalDBFSDisplayLabel,         in: NSStackView.Gravity.leading)
        configInfoStackViewClippingAndDetatching(signalStackView)

        // build stack view that contains all labels for gain setting
        gainStackView.addView(gainDisplayLabel,                 in: NSStackView.Gravity.leading)
        gainStackView.addView(gainValueDisplayLabel,            in: NSStackView.Gravity.leading)
        gainStackView.addView(gainDBDisplayLabel,               in: NSStackView.Gravity.leading)
        configInfoStackViewClippingAndDetatching(gainStackView)
        
        toneStackView.addView(toneDisplayLabel, in: NSStackView.Gravity.leading)
        toneStackView.addView(toneValueDisplayLabel, in: NSStackView.Gravity.leading)
        toneStackView.addView(toneHZDisplayLabel, in: NSStackView.Gravity.leading)
        configInfoStackViewClippingAndDetatching(toneStackView)

        // build stack view for the signal indicator
        signalLevelStackView.addView(signalLevelIndicator,      in: NSStackView.Gravity.leading)
        
        // build stack view which conatins the squelch, signal, gain and level indicator stackviews
        infoDisplayStackView.addView(gainStackView,             in: NSStackView.Gravity.leading)
        infoDisplayStackView.addView(signalStackView,           in: NSStackView.Gravity.leading)
        infoDisplayStackView.addView(squelchStackView,          in: NSStackView.Gravity.leading)
        infoDisplayStackView.addView(toneStackView,             in: NSStackView.Gravity.leading)
        
        // combine frequency and infoDisplay stackViews into complete displayStackView
        displayStackView.addView(frequencyStackView,            in: .center)
        displayStackView.addView(infoDisplayStackView,          in: .center)

        displayStackView.setClippingResistancePriority(NSLayoutConstraint.Priority(rawValue: NSLayoutConstraint.Priority.RawValue(Int(NSLayoutConstraint.Priority.windowSizeStayPut.rawValue) - 1)), for: .horizontal)

        
        //
        // create the NSStackViews containing the controls found in the
        // "front panel" control portion of the view
        //

        squelchControlStackView.addView(squelchSliderLabel,     in: .center)
        squelchControlStackView.addView(squelchSlider,          in: .center)
        
        gainControlStackView.addView(gainSliderLabel,           in: .center)
        gainControlStackView.addView(gainSlider,                in: .center)

        controlStackView.addView(squelchControlStackView,       in: .center)
        controlStackView.addView(separatorLine1,                in: .center)
        controlStackView.addView(gainControlStackView,          in: .center)
        
    }
    
    //--------------------------------------------------------------------------
    //
    // setupViewHierarchy()
    //
    // creates the entire hierarchy of views and adds them to the radio view
    // controller's content view
    //
    //--------------------------------------------------------------------------

    func setupViewHierarchy() {
        
        displayContainerView.addSubview(displayStackView)
        radioStackView.setViews([displayContainerView, controlStackView, spectrumView], in: .top)
        self.view.addSubview(radioStackView)

    }
    
    //--------------------------------------------------------------------------
    //
    // setupContraints()
    //
    // creates the auto layout constraints for placeing the sub-views together
    // into the main view
    //
    //--------------------------------------------------------------------------

    func setupConstraints() {
        
        frequencyLabel.translatesAutoresizingMaskIntoConstraints = false
        
        //
        // the entire view is contained within the radio stack view
        //
        // constrain the radioStackView to it's superview
        //

        radioStackView.topAnchor.constraint(                equalTo: self.view.topAnchor,               constant:   5.0 ).isActive = true
        radioStackView.leadingAnchor.constraint(            equalTo: self.view.leadingAnchor,           constant:   5.0 ).isActive = true
        radioStackView.trailingAnchor.constraint(           equalTo: self.view.trailingAnchor,          constant:  -5.0 ).isActive = true
        self.view.bottomAnchor.constraint(     equalTo: radioStackView.bottomAnchor,       constant:   5.0 ).isActive = true
        
        //
        // the displayStackView contains all of the "front panel" display
        // information, status, etc.
        //
        // constrain displayContainerView, displayStackView within the radioStackView
        
        
        displayContainerView.topAnchor.constraint(          equalTo: radioStackView.topAnchor,          constant:   0.0 ).isActive = true
        displayContainerView.leadingAnchor.constraint(      equalTo: radioStackView.leadingAnchor,      constant:   0.0 ).isActive = true
        displayContainerView.trailingAnchor.constraint(     equalTo: radioStackView.trailingAnchor,     constant:   0.0 ).isActive = true
  
        displayStackView.topAnchor.constraint(              equalTo: displayContainerView.topAnchor,        constant:  10.0).isActive = true
        displayStackView.leadingAnchor.constraint(          equalTo: displayContainerView.leadingAnchor,    constant:  10.0).isActive = true
        displayStackView.trailingAnchor.constraint(         equalTo: displayContainerView.trailingAnchor,   constant: -10.0).isActive = true
        displayStackView.bottomAnchor.constraint(           equalTo: displayContainerView.bottomAnchor,     constant: -10.0).isActive = true
        
        
        frequencyStackView.topAnchor.constraint(            equalTo: displayStackView.topAnchor,        constant:   0.0 ).isActive = true
        infoDisplayStackView.topAnchor.constraint(          equalTo: displayStackView.topAnchor,        constant:   0.0 ).isActive = true
        
        squelchStackView.widthAnchor.constraint(            equalTo: infoDisplayStackView.widthAnchor                   ).isActive = true
        
        gainDisplayLabel.leadingAnchor.constraint(          equalTo: squelchDisplayLabel.leadingAnchor                  ).isActive = true
        signalDisplayLabel.leadingAnchor.constraint(        equalTo: squelchDisplayLabel.leadingAnchor                  ).isActive = true
        toneDisplayLabel.leadingAnchor.constraint(          equalTo: squelchDisplayLabel.leadingAnchor                  ).isActive = true

        gainDisplayLabel.widthAnchor.constraint(            equalTo: squelchDisplayLabel.widthAnchor                    ).isActive = true
        signalDisplayLabel.widthAnchor.constraint(          equalTo: squelchDisplayLabel.widthAnchor                    ).isActive = true
        toneDisplayLabel.widthAnchor.constraint(            equalTo: squelchDisplayLabel.widthAnchor                    ).isActive = true

        
        gainValueDisplayLabel.trailingAnchor.constraint(    equalTo: squelchValueDisplayLabel.trailingAnchor,   constant: 0.0).isActive = true
        signalValueDisplayLabel.trailingAnchor.constraint(  equalTo: squelchValueDisplayLabel.trailingAnchor                 ).isActive = true
        toneValueDisplayLabel.trailingAnchor.constraint(    equalTo: squelchValueDisplayLabel.trailingAnchor                 ).isActive = true
        squelchValueDisplayLabel.widthAnchor.constraint(    equalTo: squelchDisplayLabel.widthAnchor                         ).isActive = true
        
        // constrain the signalLevelIndicator using the frequency label as reference
        signalLevelIndicator.heightAnchor.constraint(                                            equalToConstant:  11.0 ).isActive = true
//        signalLevelIndicator.widthAnchor.constraint(        equalTo: frequencyLabel.widthAnchor                         ).isActive = true
        signalLevelIndicator.leadingAnchor.constraint(      equalTo: frequencyLabel.leadingAnchor                       ).isActive = true
        signalLevelIndicator.trailingAnchor.constraint(equalTo: frequencyLabel.trailingAnchor).isActive = true
    
        
        //
        // the constrolStackView contains the most common used controls, 
        // currently only squelch and gain control
        //
        // contain controlStackView within the radioStackView
        //
        
        controlStackView.leadingAnchor.constraint(          equalTo: radioStackView.leadingAnchor,      constant:     0.0 ).isActive = true
        controlStackView.trailingAnchor.constraint(         equalTo: radioStackView.trailingAnchor,     constant:     0.0 ).isActive = true

        //
        // create a 1 pt wide vertical line as a separator between the
        // gain and squelch stack views
        //
        
        separatorLine1.topAnchor.constraint(                equalTo: controlStackView.topAnchor,        constant:     2.0 ).isActive = true
        separatorLine1.bottomAnchor.constraint(             equalTo: controlStackView.bottomAnchor,     constant:    -2.0 ).isActive = true
        separatorLine1.widthAnchor.constraint(                                                   equalToConstant:     1.0 ).isActive = true
        
        //
        // make the gainControlStackView width = to squelchControlStackview so
        // that they occupy the same amount of space across the display
        //
        gainControlStackView.widthAnchor.constraint(        equalTo: squelchControlStackView.widthAnchor                  ).isActive = true

        //
        // constrain the gainControlStackView within the controlStackView
        //
        
        gainControlStackView.topAnchor.constraint(          equalTo: controlStackView.topAnchor,        constant:     5.0 ).isActive = true
        gainControlStackView.trailingAnchor.constraint(lessThanOrEqualTo: controlStackView.trailingAnchor,    constant:    -10.0 ).isActive = true
        gainControlStackView.bottomAnchor.constraint(       equalTo: controlStackView.bottomAnchor,     constant:    -5.0 ).isActive = true
        
        //
        // constrain the squelchControlStackView within the controlStackView
        //
        
        squelchControlStackView.topAnchor.constraint(                   equalTo: controlStackView.topAnchor,        constant:   5.0 ).isActive = true
        squelchControlStackView.leadingAnchor.constraint(  greaterThanOrEqualTo: controlStackView.leadingAnchor,    constant:  10.0 ).isActive = true
        squelchControlStackView.bottomAnchor.constraint(                equalTo: controlStackView.bottomAnchor,     constant:  -5.0 ).isActive = true

        squelchSlider.widthAnchor.constraint(lessThanOrEqualToConstant: 275.0).isActive = true
        squelchSlider.widthAnchor.constraint(greaterThanOrEqualToConstant: 80.0).isActive = true
        gainSlider.widthAnchor.constraint(equalTo: squelchSlider.widthAnchor).isActive = true
        
        //
        // constrain the spectrum view
        //
        spectrumView.leadingAnchor.constraint(equalTo: radioStackView.leadingAnchor).isActive = true
        spectrumView.trailingAnchor.constraint(equalTo: radioStackView.trailingAnchor).isActive = true
        spectrumView.bottomAnchor.constraint(equalTo: radioStackView.bottomAnchor, constant: 0.0).isActive = true
    
    }
    
    //--------------------------------------------------------------------------
    //
    // setupBindings()
    //
    // setups the property bindings between the views and the controller
    //
    //--------------------------------------------------------------------------

    func setupBindings() {
        
        frequencyLabel.bind(                NSBindingName.value,     to: self, withKeyPath: "displayFrequency",      options: nil)
        deviceLabel.bind(                   NSBindingName.value,     to: self, withKeyPath: "selectedDeviceName",    options: nil)
        
        squelchValueDisplayLabel.bind(      NSBindingName.value,     to: self, withKeyPath: "squelchValue",          options: nil)
        squelchPercentDisplayLabel.bind(    NSBindingName.value,     to: self, withKeyPath: "squelchPercent",        options: nil)
        gainValueDisplayLabel.bind(         NSBindingName.value,     to: self, withKeyPath: "gainSliderString",      options: nil)
        signalValueDisplayLabel.bind(       NSBindingName.value,     to: self, withKeyPath: "signalValue",           options: nil)
        toneValueDisplayLabel.bind(         NSBindingName.value,     to: self, withKeyPath: "tone",                  options: nil)
        channelNameLabel.bind(              NSBindingName.value,     to: self, withKeyPath: "channelName",           options: nil)
        
        gainSlider.bind(                    NSBindingName.minValue,  to: self, withKeyPath: "gainSliderMin",         options: nil)
        gainSlider.bind(                    NSBindingName.maxValue,  to: self, withKeyPath: "gainSliderMax",         options: nil)
        gainSlider.bind(                    NSBindingName.value,     to: self, withKeyPath: "gainSliderRawValue",    options: nil)
        
        squelchSlider.bind(                 NSBindingName.minValue,  to: self, withKeyPath: "minDBFSValue",          options: nil)
        squelchSlider.bind(                 NSBindingName.maxValue,  to: self, withKeyPath: "maxDBFSValue",          options: nil)
        squelchSlider.bind(                 NSBindingName.value,     to: self, withKeyPath: "squelchValue",          options: nil)

        signalLevelIndicator.bind(          NSBindingName.minValue,  to: self, withKeyPath: "minDBFSValue",          options: nil)
        signalLevelIndicator.bind(          NSBindingName.maxValue,  to: self, withKeyPath: "maxDBFSValue",          options: nil)
        signalLevelIndicator.bind(          NSBindingName.value,     to: self, withKeyPath: "signalValue",           options: nil)

    }
    
    //--------------------------------------------------------------------------
    //
    // setupControls()
    //
    // do any last minute control configuration
    //
    //--------------------------------------------------------------------------
    
    func setupControls() {
        
        //
        // add a number formatter to the frequency text field
        //
        
        let formatter = NumberFormatter()
        formatter.format = "0,000,000,000"
        formatter.numberStyle = NumberFormatter.Style.none
        formatter.thousandSeparator = "."
        self.frequencyLabel.formatter = formatter
        
        let toneFormatter = NumberFormatter()
        toneFormatter.format = "00.00"
        toneFormatter.numberStyle = NumberFormatter.Style.none
        self.toneValueDisplayLabel.formatter = toneFormatter

        
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

        notify.addObserver(
            self,
            selector:   #selector(observedSdrDeviceSelectedNotification(_:)),
            name:       Notification.Name(rawValue: sdrDeviceSelectedNotification),
            object:     nil
        )
        
        notify.addObserver(
            self,
            selector:   #selector(observedSdrDeviceInitalizedNotification(_:)),
            name:       Notification.Name(rawValue: sdrDeviceInitalizedNotification),
            object:     nil
        )
        
        notify.addObserver(
            self,
            selector:   #selector(observedFrequencyUpdatedNotification(_:)),
            name:       Notification.Name(rawValue: frequencyUpdatedNotification),
            object:     nil
        )
        
        notify.addObserver(
            self,
            selector:   #selector(observedConverterUpdatedNotification(_:)),
            name:       Notification.Name(rawValue: converterUpdatedNotification),
            object:     nil
        )
        
        notify.addObserver(
            self,
            selector:   #selector(observedMixerChangeRequestNotification(_:)),
            name:       NSNotification.Name(rawValue: mixerChangeRequestNotification),
            object:     nil
        )

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
    // the selected device has been changed
    //
    //--------------------------------------------------------------------------
    
    @objc func observedSdrDeviceSelectedNotification(_ notification: Notification) {
                
        if let userInfo = notification.userInfo {
            let device = userInfo[sdrDeviceSelectedKey] as! SDRDevice
            selectedDevice = device
        }

    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------
    
    @objc func observedMixerChangeRequestNotification(_ notification: Notification) {
        
        if let userInfo = notification.userInfo {
            let newFrequency = userInfo[mixerChangeRequestKey] as! Int
            self.oscillatorFrequency = newFrequency
        }
    }

    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------
    
    @objc func observedConverterUpdatedNotification(_ notification: Notification) {
        
        if let userInfo = notification.userInfo {
            let converter = userInfo[converterUpdatedKey] as! Int
            self.converterFrequency = converter
        }
    }
    
    //--------------------------------------------------------------------------
    //
    // observedSdrDeviceInitalizedNotification()
    //
    // the selected device had been initalized 
    // (opened, read config, closed, etc)
    //
    //--------------------------------------------------------------------------
    
    @objc func observedSdrDeviceInitalizedNotification(_ notification: Notification) {
        
            // configure gain slider
            configureGainSlider()
        
    }

    //--------------------------------------------------------------------------
    //
    // observedFrequencyUpdatedNotification()
    //
    // the frequency has been changed
    //
    //--------------------------------------------------------------------------
    
    @objc func observedFrequencyUpdatedNotification(_ notification: Notification) {
        
        if let userInfo = notification.userInfo {
            let updatedFrequency = userInfo[frequencyUpdatedKey] as! Int
            self.tunedFrequency = updatedFrequency
        }
        
    }
    
    //--------------------------------------------------------------------------
    //
    // MARK: - utility methods
    //
    //--------------------------------------------------------------------------
    
    func configureGainSlider() {
        
//        print("Device: \(selectedDevice)")
        self.gainValueList = selectedDevice!.tunerGainArray()
    }
    
}
