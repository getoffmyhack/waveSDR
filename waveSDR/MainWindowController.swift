//
//  MainWindowController.swift
//  waveSDR
//
//  Copyright © 2017 GetOffMyHack. All rights reserved.
//

import Cocoa

class MainWindowController: NSWindowController {
    
    @IBOutlet weak var startSDRButton:          NSButton!
    @IBOutlet weak var sidebarButton:           NSButton!
    @IBOutlet weak var deviceToolbarItem:       NSToolbarItem!
    @IBOutlet weak var deviceToolbarLabel:      NSTextField!
    @IBOutlet weak var centeringToolbarItem:    CenteringSpacerToolbarItem!
    
    @objc var sdr: SoftwareDefinedRadio
    
    var sidebarCollapsed: Bool      =   false
    
    @objc let deviceLabelToolbarTooltip   =   "Currently selected SDR device."
    
    // create main content view controller
    var mainContentViewController   =   MainContentViewController()
    
    // create display area view controllers
    var radioDisplayViewController  =   RadioDisplayViewController()
    var spectrumViewController      =   SpectrumViewController()
    
    // create sidebar view controllers
    var sidebarViewController       =   SidebarViewController()
    var hardwareViewController      =   HardwareViewController()
    var tunerViewController         =   TunerViewController()
    var audioOutViewController      =   AudioOutViewController()
    
    // create split view items for content view controllers
    var displaySplitViewItem        =   NSSplitViewItem()
    var sidebarSplitViewItem        =   NSSplitViewItem()
    
    private let notify              =   NotificationCenter.default
    
    private var refreshTimer: Timer =   Timer()

    @objc private dynamic var stringForToolBarDeviceLabel: String = ""
    
    override var windowNibName: NSNib.Name? {
        return NSNib.Name("MainWindowController")
    }
    
//    override var windowNibName: String! {
//        return "MainWindowController"
//    }
    
    //--------------------------------------------------------------------------
    //
    // MARK: - init / deinit
    //
    //--------------------------------------------------------------------------
    
    override init(window: NSWindow?) {
    
        sdr = SoftwareDefinedRadio()
        super.init(window: window)
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
    // override methods from super class
    //
    //--------------------------------------------------------------------------
    
    override func windowDidLoad() {
        
        super.windowDidLoad()
        
        // remove title from window frame
        self.window!.titleVisibility = .hidden
                
        //----------------------------------------------------------------------
        //
        // build gui
        //
        //----------------------------------------------------------------------

        // initalize (left) sidebar
        setupSidebar()

        // build split views
        setupMainSplitView()
        
        // config radio view controller
        radioDisplayViewController.spectrumView = spectrumViewController.view
        
        // config device label toolbar item -- setting menuFormRepresentation
        // to nil will remove the label from the overflow menu
        deviceToolbarItem.menuFormRepresentation = nil

        // set main content view controller
        self.contentViewController = mainContentViewController
        
        //----------------------------------------------------------------------
        //
        // setup software defined radio
        //
        //----------------------------------------------------------------------

        // announce device list
        //
        // at this point, all devices (if any) have been enumerated, let the UI
        // know that the device list is ready
        
        let sdrDeviceInfo: [String : Any] = [sdrDeviceListKey: sdr.deviceList]
        notify.post(name: Notification.Name(rawValue: sdrDeviceListNotifcaiton), object: self, userInfo: sdrDeviceInfo)
        
        //
        // setup defaults
        //
        // TODO: replace with NSUserDefaults
        // setup some start-up values
        tunerViewController.tunedFrequency      = 162550000
        tunerViewController.demodSelected       = 1
        tunerViewController.selectedStepBase    = "kHz"
        tunerViewController.selectedStepSize    = 1
        audioOutViewController.highPassCutoff   = 300
        
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
    // setupSidebar()
    //
    // add child view controllers to sidebar view controller
    //
    //--------------------------------------------------------------------------
    
    func setupSidebar() {
        
        // build sidebar controller
        self.sidebarViewController.addChildViewController(hardwareViewController)
        self.sidebarViewController.addChildViewController(tunerViewController)
        self.sidebarViewController.addChildViewController(audioOutViewController)

        // KLUDGE:
        // set inital sidebar state - used to keep toolbar button in sync
        // with sidebar collapsed state
        sidebarCollapsed = sidebarSplitViewItem.isCollapsed
        
    }
    
    //--------------------------------------------------------------------------
    //
    // setupMainSplitView()
    //
    // create split view items and add to main split view controller
    //
    //--------------------------------------------------------------------------

    func setupMainSplitView() {

        // create split view items for main split view controller
        sidebarSplitViewItem = NSSplitViewItem(sidebarWithViewController: sidebarViewController)
        displaySplitViewItem = NSSplitViewItem(viewController: radioDisplayViewController)
        
        
        // add split view items to main split view controller
        mainContentViewController.addSplitViewItem(sidebarSplitViewItem)
        mainContentViewController.addSplitViewItem(displaySplitViewItem)
        
        // this will prevent the sidebar from automatically collapsing when
        // the window shrinks
        mainContentViewController.minimumThicknessForInlineSidebars = -1
        
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
        
        // KLUDGE: 
        // add observer for SplitViewDidResizeSubview in order to keep track of
        // sidebar collapsed state --- there should be a better way to do this
        notify.addObserver( self,
                    selector: #selector(updateSidebarButton),
                        name: NSSplitView.didResizeSubviewsNotification,
                      object: nil)
        
        //
        // the following obervers receive posts from the different view
        // controllers in response to control changes and updates the
        // selected sdr device via the SoftwareDefinedRadio object
        //
        
        notify.addObserver(
            self,
            selector:   #selector(observedSdrDeviceSelectedNotification(_:)),
            name:       NSNotification.Name(rawValue: sdrDeviceSelectedNotification),
            object:     nil
        )
        
        notify.addObserver(
            self,
            selector:   #selector(observedFrequencyUpdatedNotification(_:)),
            name:       NSNotification.Name(rawValue: frequencyUpdatedNotification),
            object:     nil
        )
        
        notify.addObserver(
            self,
            selector:   #selector(observedHighPassCutoffUpdatedNotification(_:)),
            name:       NSNotification.Name(rawValue: highPassCutoffUpdatedNotification),
            object:     nil
        )
        
        notify.addObserver(
            self,
            selector:   #selector(observedHighPassBypassUpdatedNotification(_:)),
            name:       NSNotification.Name(rawValue: highPassBypassUpdatedNotification),
            object:     nil
        )
        
        notify.addObserver(
            self,
            selector:   #selector(observedSampleRateUpdatedNotification(_:)),
            name:       NSNotification.Name(rawValue: sampleRateUpdatedNotification),
            object:     nil
        )
        
        notify.addObserver(
            self,
            selector:   #selector(observedCorrectionUpdatedNotification(_:)),
            name:       NSNotification.Name(rawValue: correctionUpdatedNotification),
            object:     nil
        )
        
        notify.addObserver(
            self,
            selector:   #selector(observedTunerAutoGainUpdatedNotification(_:)),
            name:       NSNotification.Name(rawValue: tunerAutoGainUpdatedNotification),
            object:     nil
        )
        
        notify.addObserver(
            self,
            selector:   #selector(observedTunerGainUpdatedNotification(_:)),
            name:       NSNotification.Name(rawValue: tunerGainUpdatedNotification),
            object:     nil
        )
        
        notify.addObserver(
            self,
            selector:   #selector(observedSquelchUpdatedNotification(_:)),
            name:       NSNotification.Name(rawValue: squelchUpdatedNotification),
            object:     nil
        )
        
        notify.addObserver(
            self,
            selector:   #selector(observedDemodModeUpdatedNotification(_:)),
            name:       NSNotification.Name(rawValue: demodModeUpdatedNotification),
            object:     nil
        )
        
        notify.addObserver(
            self,
            selector:   #selector(observedFrequencyChangeRequestNotification(_:)),
            name:       NSNotification.Name(rawValue: frequencyChangeRequestNotification),
            object:     nil
        )
        
        notify.addObserver(
            self,
            selector:   #selector(observedMixerChangeRequestNotification(_:)),
            name:       NSNotification.Name(rawValue: mixerChangeRequestNotification),
            object:     nil
        )
        
        notify.addObserver(
            self,
            selector:   #selector(observedSDRPauseRequestNotification(_:)),
            name:       NSNotification.Name(rawValue: sdrPauseRequestNotification),
            object:     nil
        )
        
        notify.addObserver(
            self,
            selector:   #selector(observedSDRLiveRequestRequestNotification(_:)),
            name:       NSNotification.Name(rawValue: sdrLiveRequestNotification),
            object:     nil
        )
        
        //
        // radio report observers
        //
        
        notify.addObserver(
            self,
            selector:   #selector(observedAverageDBUpdatedNotification(_:)),
            name:       NSNotification.Name(rawValue: averageDBUpdatedNotification),
            object:     nil
        )
        
        notify.addObserver(
            self,
            selector:   #selector(observedSquelchPercentUpdated(_:)),
            name:       NSNotification.Name(rawValue: squelchPercentUpdatedNotification),
            object:     nil
        )
        
        notify.addObserver(
            self,
            selector:   #selector(observedFFTSamplesUpdatedNotification(_:)),
            name:       NSNotification.Name(rawValue: fftSamplesUpdatedNotification),
            object:     nil
        )
        
        notify.addObserver(
            self,
            selector:   #selector(observedToneDecoderUpdatedNotification(_:)),
            name:       NSNotification.Name(rawValue: toneDecoderUpdatedNotification),
            object:     nil
        )


    }
    
    //--------------------------------------------------------------------------
    //
    // MARK: - notification observers
    //
    // <observed> methods are selectors for notificaions from NotificationCenter
    //
    //--------------------------------------------------------------------------
    
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
            sdr.frequency = updatedFrequency
        }

    }
    
    //--------------------------------------------------------------------------
    //
    // observedSampleRateSelectedNotification()
    //
    // the selected sample rate has been changed
    //
    //--------------------------------------------------------------------------
    
    @objc func observedSampleRateUpdatedNotification(_ notification: Notification) {
        
        if let userInfo = notification.userInfo {
            let sampleRate = userInfo[sampleRateUpdatedKey] as! Int
            sdr.sampleRate = sampleRate
        }
        
    }
    
    //--------------------------------------------------------------------------
    //
    // observedCorrectionUpdatedNotification()
    //
    // the frequency correction has been changed
    //
    //--------------------------------------------------------------------------
    
    @objc func observedCorrectionUpdatedNotification(_ notification: Notification) {
        
        if let userInfo = notification.userInfo {
            let correction = userInfo[correctionUpdatedKey] as! Int
            sdr.frequencyCorrection = correction
        }
        
    }

    //--------------------------------------------------------------------------
    //
    // observedSquelchUpdatedNotification()
    //
    // the squelch has been changed
    //
    //--------------------------------------------------------------------------
    
    @objc func observedSquelchUpdatedNotification(_ notification: Notification) {
        
        if let userInfo = notification.userInfo {
            let squelch = userInfo[squelchUpdatedKey] as! Float
            sdr.squelchValue = squelch
        }
        
    }

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
            sdr.selectedDevice = device

            updateToolBarDeviceLabel(device.description)
            self.window?.title = device.description

            
            if(device.isConfigured()) {
                // post device is configured notify
                notify.post(name: Notification.Name(rawValue: sdrDeviceInitalizedNotification), object: self, userInfo: nil)

            }
        }
        
    }
    
    //--------------------------------------------------------------------------
    //
    // observedTunerAutoGainUpdatedNotification()
    //
    // the auto gain setting has changed
    //
    //--------------------------------------------------------------------------
    
    @objc func observedTunerAutoGainUpdatedNotification(_ notification: Notification) {
        
        if let userInfo = notification.userInfo {
            let autoGain = userInfo[tunerAutoGainUpdatedKey] as! Bool
            sdr.tunerAutoGain = autoGain
        }
        
    }
    
    //--------------------------------------------------------------------------
    //
    // observedTunerGainUpdatedNotification()
    //
    // the tuner gain setting has changed
    //
    //--------------------------------------------------------------------------
    
    @objc func observedTunerGainUpdatedNotification(_ notification: Notification) {
        
        if let userInfo = notification.userInfo {
            let gain = userInfo[tunerGainUpdatedKey] as! Int
            sdr.tunerGain = gain
        }
        
    }
    
    //--------------------------------------------------------------------------
    //
    // observedHighPassCutoffUpdatedNotification()
    //
    // the frequency has been changed
    //
    //--------------------------------------------------------------------------
    
    @objc func observedHighPassCutoffUpdatedNotification(_ notification: Notification) {
        
        if let userInfo = notification.userInfo {
            let updatedFrequency = userInfo[highPassCutoffUpdatedKey] as! Int
            sdr.highPassCutoff = updatedFrequency
        }
        
    }
    
    //--------------------------------------------------------------------------
    //
    // observedHighPassBypassUpdatedNotification()
    //
    // the frequency has been changed
    //
    //--------------------------------------------------------------------------
    
    @objc func observedHighPassBypassUpdatedNotification(_ notification: Notification) {
        
        if let userInfo = notification.userInfo {
            let bypass = userInfo[highPassBypassUpdatedKey] as! Bool
            sdr.highPassBypass = bypass
        }
        
    }
    
    //--------------------------------------------------------------------------
    //
    // observedDemodModeUpdatedNotification()
    //
    // the selected device has been changed
    //
    //--------------------------------------------------------------------------
    
    @objc func observedDemodModeUpdatedNotification(_ notification: Notification) {
        
//        self.refreshTimer.invalidate()
        
        if let userInfo = notification.userInfo {
            let mode = userInfo[demodModeUpdatedKey] as! String
            sdr.setMode(mode)
        }
        
//        self.refreshTimer = Timer.init(
//            timeInterval:   1.0/30.0,
//            target:         self,
//            selector:       #selector(self.updateDisplays),
//            userInfo:       nil,
//            repeats:        true
//        )
//        RunLoop.main.add(self.refreshTimer, forMode: RunLoopMode.commonModes)
        
    }
    
    //--------------------------------------------------------------------------
    //
    //  observedMixerChangeRequestNotification()
    //
    //  user clicked in spectrum display to change tuning offset from 
    //  center tuned frequency
    //
    //--------------------------------------------------------------------------
    
    @objc func observedMixerChangeRequestNotification(_ notification: Notification) {
        
        if let userInfo = notification.userInfo {
            let newFrequency = userInfo[mixerChangeRequestKey] as! Int
            sdr.localOscillator = newFrequency
        }
    }
    
    //--------------------------------------------------------------------------
    //
    //  observedFrequencyChangeRequestNotification()
    //
    //  user doubled clicked spectrum display to change center tuned frequency
    //
    //--------------------------------------------------------------------------
    
    @objc func observedFrequencyChangeRequestNotification(_ notification: Notification) {
        
        if let userInfo = notification.userInfo {
            let newFrequency = userInfo[frequencyChangeRequestKey] as! Int
            tunerViewController.tunedFrequency = newFrequency
        }
    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------
    
    @objc func observedSDRPauseRequestNotification(_ notification: Notification) {
        
        if self.sdr.isRunning {
            self.sdr.isPaused.toggle()
        }
    }

    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------
    
    @objc func observedSDRLiveRequestRequestNotification(_ notification: Notification) {
        
        if self.sdr.isRunning == true {
            self.sdr.goLive()
        }
    }

    //--------------------------------------------------------------------------
    //
    // MARK: - Radio Report Observers
    //
    //--------------------------------------------------------------------------
    
    //--------------------------------------------------------------------------
    //
    // observedAverageDBNotificaiton()
    //
    //  signal strength value changed
    //
    //--------------------------------------------------------------------------
    
    @objc func observedAverageDBUpdatedNotification(_ notification: Notification) {
        
        if let userInfo = notification.userInfo {
            let db = userInfo[averageDBUpdatedKey] as! Float
            DispatchQueue.main.async {
                self.radioDisplayViewController.signalValue = db
            }
        }
        
    }

    //--------------------------------------------------------------------------
    //
    // observedSquelchPercentUpdated()
    //
    // the squelch % value has changed
    //
    //--------------------------------------------------------------------------
    
    @objc func observedSquelchPercentUpdated(_ notification: Notification) {
        
        if let userInfo = notification.userInfo {
            let percent = userInfo[squelchPercentUpdatedKey] as! Int
            DispatchQueue.main.async {
                self.radioDisplayViewController.squelchPercent = String(format: "@ %3d%%", percent)
            }
        }
    }
    
    //--------------------------------------------------------------------------
    //
    //  observedFFTSamplesUpdatedNotification()
    //
    //  latest buffer of samples from FFT updated
    //
    //--------------------------------------------------------------------------
    
    @objc func observedFFTSamplesUpdatedNotification(_ notification: Notification) {
        
        if let userInfo = notification.userInfo {
            let fftSamples = userInfo[fftSamplesUpdatedKey] as! [Float]
            
            // pass fft samples to spectrum view controller
            spectrumViewController.inSamples = fftSamples
        }
    }
    
    //--------------------------------------------------------------------------
    //
    //  observedToneDecoderUpdatedNotification()
    //
    //  tone decoder updated
    //
    //--------------------------------------------------------------------------
    
    @objc func observedToneDecoderUpdatedNotification(_ notification: Notification) {
        
        if let userInfo = notification.userInfo {
            let tone = userInfo[toneDecoderUpdatedKey] as! Double
            
            // update radio view controller
            DispatchQueue.main.async {
                self.radioDisplayViewController.tone = tone
            }
        }
    }

    //--------------------------------------------------------------------------
    //
    // updateSidebarButton()
    //
    // KLUDGE:
    // keep track of sidebar collapsed state and update toolbar button as needed
    // ---- there must be a better way to do this
    //
    //--------------------------------------------------------------------------
    
    @objc func updateSidebarButton(notification: NSNotification) {
        
        if(sidebarSplitViewItem.isCollapsed == true) {
            sidebarButton.state = NSControl.StateValue.off // NSOffState
        } else {
            sidebarButton.state = NSControl.StateValue.on  // NSOnState
        }
        
    }
    
    //--------------------------------------------------------------------------
    //
    //  updateToolBarDeviceLabel()
    //
    //  selected device changed, update toolbar label
    //
    //--------------------------------------------------------------------------
    
    func updateToolBarDeviceLabel(_ deviceName: String) {
        
        self.stringForToolBarDeviceLabel = deviceName
        
        
        // use standard system font and size (as default in IB) as attributes
        let labelAttributes: [NSAttributedStringKey : Any] = [
            NSAttributedStringKey(rawValue: NSAttributedStringKey.font.rawValue) : NSFont.systemFont(ofSize: NSFont.systemFontSize)
        ]

        // get size of attributed string as displayed in toolbar device label
        let labelMargin: CGFloat = 1.0
        var labelSize: NSSize = stringForToolBarDeviceLabel.size(withAttributes: labelAttributes)
        labelSize.width += labelMargin
        
        // set the toolbar item's min and max sizes to size of new device label
        deviceToolbarItem.minSize = labelSize
        deviceToolbarItem.maxSize = labelSize
        
        // update width of the centering toolbar item
        centeringToolbarItem.updateWidth()
        
    }

    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------

    @objc func updateDisplays() {
//        self.radioDisplayViewController.signalValue = self.sdr.getStatusFor(key: averageDBKey) as! Float
//        self.radioDisplayViewController.squelchPercent = String(format: "@ %3d%%", self.sdr.getStatusFor(key: squelchPercentKey) as! Int)
//        self.radioDisplayViewController.tone            = self.sdr.getStatusFor(key: toneDecoderKey) as! Double
    }
    
    //--------------------------------------------------------------------------
    //
    // MARK: - Action Methods
    //
    //--------------------------------------------------------------------------
    
    //--------------------------------------------------------------------------
    //
    //  runStopButtonClicked()
    //
    //  toggle SDR running state
    //
    //--------------------------------------------------------------------------
    
    @IBAction func runStopButtonClicked(_ sender: AnyObject) {
        
        if(self.sdr.isRunning == true) {

            self.refreshTimer.invalidate()
            self.sdr.stop()
            notify.post(name: Notification.Name(rawValue: sdrStoppedNotification), object: self, userInfo: nil)
            
        } else {

            self.refreshTimer = Timer.init(
                timeInterval:   1.0/30.0,
                target:         self,
                selector:       #selector(self.updateDisplays),
                userInfo:       nil,
                repeats:        true
            )
            RunLoop.main.add(self.refreshTimer, forMode: RunLoopMode.commonModes)

            self.sdr.start()
            notify.post(name: Notification.Name(rawValue: sdrStartedNotification), object: self, userInfo: nil)
        }
        
    }
    

    
}







