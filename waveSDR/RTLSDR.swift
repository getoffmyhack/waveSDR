//
//  RTLSDR.swift
//  waveSDR
//
//  Copyright © 2017 GetOffMyHack. All rights reserved.
//

import Foundation



final class RTLSDR: SDRDevice {
     
    // MARK: - Type Properties

    //------------------------------------------------------------
    //
    // Private Type Properties
    //
    //------------------------------------------------------------
    
//    fileprivate static let _rtlsdrCount: Int = {
    
//        let rtlsdrCount = Int(rtlsdr_get_device_count())
//        return rtlsdrCount
//        return _deviceArray.count

//    }()

//    fileprivate static let _deviceArray: [RTLSDR] = []
//    fileprivate static let _deviceArray: [RTLSDR] = {
//
//        var rtlsdrArray: [RTLSDR] = []
//        for i in 0..<_rtlsdrCount {
//            let device = RTLSDR(i)
//            device.initDevice()
//            rtlsdrArray.append(device)
//        }
//        return rtlsdrArray
//
//    }()
    
    fileprivate static let _sampleRates:    [Int] = [960000, 2400000]
    
    fileprivate static let gainModeAuto:    Int32  = 0
    fileprivate static let gainModeManual:  Int32  = 1

    
    //--------------------------------------------------------------------------
    //
    // MARK: - type Methods
    //
    //--------------------------------------------------------------------------
    
//    override class func deviceCount() -> Int {
//        return _rtlsdrCount
//    }
//    
//    override class func deviceList() -> [SDRDevice] {
//        return _deviceArray
//    }
    
    override class func isDeviceSupported(usbDevice: IOUSBDevice) -> SDRDevice? {
        
        var rtlDevice: RTLSDR? = nil
        
        // a new USB device has been added, first check if RTL
        if(RTLKnownDevices.isKnownRTLDevice(vid: usbDevice.usbVendorID, pid: usbDevice.usbProductID)) {
            
            // at this point, IOKit has completely registered this device
            // but for some uknown reason(s) (as of now) it takes about 2 seconds
            // for librtlsdr via libusb to recognize the new device using
            // either rtlsdr_get_device_count or rtlsdr_get_index_by_serial
            
            // my option to overcome this is to loop the call to
            // rtlsdr_get_index_by_serial until it returns a valid index
            // which usually happens on the second call
            
            let serialCString = (usbDevice.usbSerialNumber as NSString).utf8String
            
            var index: Int32 = -99
            
            repeat {
                index = rtlsdr_get_index_by_serial(serialCString)
            } while index < 0
            
            // we have the index, create the RTLSDR object and return
            rtlDevice = RTLSDR(UInt32(index), device: usbDevice)
            rtlDevice?.initDevice()
            
        }
        
        return rtlDevice
    }

    
    //------------------------------------------------------------
    //
    // MARK: - Public Instance Properties
    //
    //------------------------------------------------------------
    
    let usbName:            String
    let usbManufacture:     String
    let usbProduct:         String
    let usbSerial:          String
    let name:               String

    var tuner:              String = ""
    var isInitalized:       Bool   = false
    
    override var description:   String {
        get {
            return usbName
        }
    }
    
    //------------------------------------------------------------
    //
    // MARK: - Private Instance Properties
    //
    //------------------------------------------------------------
    
    private let asyncReadQueue:         DispatchQueue
    private let asyncReadQueueLabel:    String = "RTLSDR.asyncReadQueue"
    
    private var librtlsdrPointer:       OpaquePointer?  = nil
    private var librtlsdrIndex:         UInt32          {
        get {
            let index = rtlsdr_get_index_by_serial((self.usbSerial as NSString).utf8String)
            return UInt32(index)
        }
    }
    
    private var bufferSize:             Int          = 16384 * 2
    
    private var sampleBuffer:           [UInt8]
    
    private var _isConfigured:          Bool    = false
    
    private var _sampleRate:            Int     = 0 {
        didSet {
            if(self.isOpen() == true) {
                let rate = UInt32(self._sampleRate)
                rtlsdr_set_sample_rate(self.librtlsdrPointer, rate)
            }
        }
    }
    
    private var _tunedFrequency:        Int     = 0 {
        didSet {
            if(self.isOpen() == true) {
                let frequency = UInt32(self._tunedFrequency)
                rtlsdr_set_center_freq(self.librtlsdrPointer, frequency)
            }
        }
    }
    
    private var _correction:            Int     = 0 {
        didSet {
            if(self.isOpen() == true) {
                let correction = Int32(self._correction)
                rtlsdr_set_freq_correction(self.librtlsdrPointer, correction)
            }
        }
    }
    
    private var _tunerGainList:         [Int]   = []
    
    private var _tunerAutoGain:         Bool    = false {
        didSet {
            if(self.isOpen() == true) {
                if(self._tunerAutoGain == true) {
                    rtlsdr_set_tuner_gain_mode(self.librtlsdrPointer, RTLSDR.gainModeAuto)
                } else {
                    rtlsdr_set_tuner_gain_mode(self.librtlsdrPointer, RTLSDR.gainModeManual)
                    rtlsdr_set_tuner_gain(self.librtlsdrPointer, Int32(self._tunerGain))
                }
            }
        }
    }
    
    private var _tunerGain:             Int     = 0 {
        didSet {
            if(self.isOpen() == true) {
                let gain = Int32(self._tunerGain)
                rtlsdr_set_tuner_gain(self.librtlsdrPointer, gain)                
            }
        }
    }

    
    //------------------------------------------------------------
    //
    // MARK: - Public Type Methods
    //
    //------------------------------------------------------------

    //
    
    //--------------------------------------------------------------------------
    //
    // MARK: - SDRDeviceProtocol
    //
    //--------------------------------------------------------------------------
    
    //--------------------------------------------------------------------------
    //
    // minimumFrequency()
    //
    // return minimum supported frequency
    //
    //--------------------------------------------------------------------------
    
    override func minimumFrequency() -> Int {
        
        // hardcoded for the R820T tuner
        return 24000000
        
    }
    
    //--------------------------------------------------------------------------
    //
    // maximumFrequency()
    //
    // return maximum supported frequency
    //
    //--------------------------------------------------------------------------
    
    override func maximumFrequency() -> Int {
        
        // hardcoded for the R820T tuner
        return 1766000000
        
    }
    
    //--------------------------------------------------------------------------
    //
    // sampleRate() -> UInt
    //
    // return current sample rate
    //
    //--------------------------------------------------------------------------
    
    override func sampleRate() -> Int {
        
        return self._sampleRate
        
    }
    
    //--------------------------------------------------------------------------
    //
    // sampleRate(rate: UInt)
    //
    // set device sample rate
    //
    //--------------------------------------------------------------------------
    
    override func sampleRate(rate: Int) {
        
            _sampleRate = rate

    }
    
    //--------------------------------------------------------------------------
    //
    // sampleRateList() -> [UInt]
    //
    // retreive list of available sample rates
    //
    //--------------------------------------------------------------------------
    
    override func sampleRateList() -> [Int] {
        
        return RTLSDR._sampleRates

    }
    
    //--------------------------------------------------------------------------
    //
    // tunedFrequency() -> UInt
    //
    // return current frequency
    //
    //--------------------------------------------------------------------------

    override func tunedFrequency() -> Int {
        
        return _tunedFrequency
        
    }
    
    //--------------------------------------------------------------------------
    //
    // tunedFrequency(frequency: UInt)
    //
    // set tuner frequency
    //
    //--------------------------------------------------------------------------
    
    override func tunedFrequency(frequency: Int) {
    
        self._tunedFrequency = frequency
        
    }

    //--------------------------------------------------------------------------
    //
    // frequencyCorrection() -> Int
    //
    // return current frequency correction
    //
    //--------------------------------------------------------------------------
    
    override func frequencyCorrection() -> Int {
        
        return _correction
        
    }
    
    //--------------------------------------------------------------------------
    //
    // frequencyCorrection(frequency: UInt)
    //
    // set frequency correction
    //
    //--------------------------------------------------------------------------
    
    override func frequencyCorrection(correction: Int) {
        
        self._correction = correction
        
    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------

    override func tunerGainArray() -> [Int] {
        
        return _tunerGainList
    
    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------

    override func tunerAutoGain() -> Bool {
        
        return _tunerAutoGain
        
    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------

    override func tunerAutoGain(auto: Bool) {
        
        self._tunerAutoGain = auto
        
    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------

    override func tunerGain() -> Int {
        
        return _tunerGain
        
    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------

    override func tunerGain(gain: Int) {
        
        self._tunerGain = gain
        
    }
    
    //--------------------------------------------------------------------------
    //
    // isOpen() -> Bool
    //
    // is current device opened via librtlsdr
    //
    //--------------------------------------------------------------------------

    override func isOpen() -> Bool {

        if(librtlsdrPointer != nil) {
            return true
        } else {
            return false
        }
    }
    
    //--------------------------------------------------------------------------
    //
    // isConfigured() -> Bool
    //
    // is current device opened via librtlsdr
    //
    //--------------------------------------------------------------------------
    
    override func isConfigured() -> Bool {
        
        return self._isConfigured
    
    }

    
    //------------------------------------------------------------
    //
    // MARK: - Instance Methods
    //
    //------------------------------------------------------------
    
    func open() {
        
        rtlsdr_open(&librtlsdrPointer, librtlsdrIndex)
        
    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------

    func close() {
        
        if(self.isOpen() == true) {
            rtlsdr_close(librtlsdrPointer)
            librtlsdrPointer = nil
        }
        
    }
    
    //--------------------------------------------------------------------------
    //
    // startSamplesStream()
    //
    // A convience method to start streaming (async reading) from RTLSDR
    // device
    //
    //--------------------------------------------------------------------------

    
    override func startSampleStream() {
        
        // open device
        if(self.isOpen() == false) {
            self.open()
        }
        
        // initalize device
        if(self.isConfigured() == false) {
            self.initDevice()
        }
        
        // make sure to configure all parameters
        // -- the instance properties all have observers that will
        //    call the needed librtlsdr function to set the parameter
        
        let sr                  = self._sampleRate
        self._sampleRate        = sr
        
        let ppm                 = self._correction
        self._correction        = ppm
        
        let freq                = self._tunedFrequency
        self._tunedFrequency    = freq
        
        let auto = self._tunerAutoGain
        self._tunerAutoGain = auto
        
        // reset buffer
        rtlsdr_reset_buffer(self.librtlsdrPointer)
        
        readAsyncFromDevice()
        
    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------

    override func stopSampleStream() {
        
        self.cancelAsyncRead()
        self.close()
        
    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------

    func cancelAsyncRead() {
        
        if(self.isOpen() == true) {
            rtlsdr_cancel_async(self.librtlsdrPointer)
        }
        
    }
 
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------

    func readAsyncFromDevice() {
 
        asyncReadQueue.async {
        
            let rtlSdrContext = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
            
            
            rtlsdr_read_async(self.librtlsdrPointer,
                // use a closure as the callback function
                {
                    (buffer: UnsafeMutablePointer<UInt8>?, length: UInt32, ctx: UnsafeMutableRawPointer?) -> Void in
                    
                        let selfRTLSDR =  Unmanaged<RTLSDR>.fromOpaque(ctx!).takeUnretainedValue()
                                        
                        // get a buffer pointer with length to samples
                        let bufferPointer = UnsafeMutableBufferPointer(start: buffer, count: Int(length))
                    
                        // convert buffer to Swift [UInt8]
                        let samples: [UInt8] = Array(bufferPointer)
                    
                    
                        selfRTLSDR.delegate?.sdrDevice(selfRTLSDR, rawSamples: samples)
                    
                },
                // end call back closure
                rtlSdrContext, UInt32(0), UInt32(self.bufferSize)
            )
            
        }
        
    }
    
    // init() is marked private as the only time an object is initalized will
    // be first access to deviceArray from the getDeviceArray() type method
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------

    fileprivate init(_ devID: UInt32, device: IOUSBDevice){
        
        
        // get the librtlsdr name
        name      = String(cString: UnsafePointer(rtlsdr_get_device_name(devID)))
        
        // get usb strings from device
        var manf:   [CChar] = [CChar](repeating: 0, count: 255)
        var prod:	[CChar] = [CChar](repeating: 0, count: 255)
        var serial:	[CChar] = [CChar](repeating: 0, count: 255)
        
        rtlsdr_get_device_usb_strings(devID, &manf, &prod, &serial)
        
        usbManufacture    = String(cString: manf)
        usbProduct        = String(cString: prod)
        usbSerial         = String(cString: serial)
        usbName           = usbManufacture + " " + usbProduct + " SN: " + usbSerial
        
        // Initalize vars
        
        asyncReadQueue  = DispatchQueue(label: "\(asyncReadQueueLabel).\(usbName)")
        sampleBuffer    = [UInt8](repeating: 0, count: bufferSize)
        
        super.init()

        self.usbDevice      = device
        _sampleRate = Int(RTLSDR._sampleRates.max()!)
        
        print("RTLSDR: initing:    <\(self.usbName)>")

    }
    
    deinit {
        
        print("RTLSDR: de-initing: <\(self.usbName)>")
        
    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------

    fileprivate func initDevice() {
        
        open()
        initDeviceTunerGainList()
        initDeviceTuner()
        self._isConfigured = true
        close()
        
    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------

    fileprivate func initDeviceTunerGainList() {
        if(isOpen() == true) {
            
            let tunerGainCount: Int     = Int(rtlsdr_get_tuner_gains(librtlsdrPointer, nil))
            var gainList:       [Int32] = [Int32](repeating: 0, count: tunerGainCount)
            
            rtlsdr_get_tuner_gains(librtlsdrPointer, &gainList)
            
            self._tunerGainList = gainList.map( {
                (gain: Int32) -> Int in
                return Int(gain)
            })
            
        }
    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------

    fileprivate func initDeviceTuner() {
        if(isOpen() == true) {
            
            let deviceTunerType: rtlsdr_tuner = rtlsdr_get_tuner_type(librtlsdrPointer)
            
            switch(deviceTunerType.rawValue) {
                
            case (RTLSDR_TUNER_E4000.rawValue):
                tuner = ("Elonics E4000")
                break;
            case (RTLSDR_TUNER_FC0012.rawValue):
                tuner = ("Fitipower FC0012")
                break;
            case (RTLSDR_TUNER_FC0013.rawValue):
                tuner = ("Fitipower FC0013")
                break;
            case (RTLSDR_TUNER_FC2580.rawValue):
                tuner = ("FCI 2580")
                break;
            case (RTLSDR_TUNER_R820T.rawValue):
                tuner = ("Rafael Micro R820T")
                break;
            case (RTLSDR_TUNER_R828D.rawValue):
                tuner = ("Rafael Micro R828D")
                break;
            default:
                tuner = ("Unknown Tuner")
                
            }
        }
    }
}
