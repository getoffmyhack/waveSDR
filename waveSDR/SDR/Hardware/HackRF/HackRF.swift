//
//  HackRF.swift
//  waveSDR
//
//  Created on 5/7/24.
//  Copyright © 2024 GetOffMyHack. All rights reserved.
//


import Foundation

final class HackRF: SDRDevice {
    
    // MARK: - Type Properties

    //------------------------------------------------------------
    //
    // Private Type Properties
    //
    //------------------------------------------------------------
 
    fileprivate static let _sampleRates:    [Int] = [960000, 2400000, 5760000, 10032000, 15600000, 19968000]
    
    // TODO:
    fileprivate static let gainModeAuto:    Int32  = 0
    fileprivate static let gainModeManual:  Int32  = 1
    
    fileprivate static let newDeviceQueue:  DispatchQueue = DispatchQueue(label: "com.getoffmyhack.waveSDR.HackRF.newDeviceQueue")

    //--------------------------------------------------------------------------
    //
    // MARK: - type Methods
    //
    //--------------------------------------------------------------------------
    
    
    override class func isDeviceSupported(usbDevice: USBDevice) -> SDRDevice? {
        
        var hackrfDevice: HackRF? = nil
     
        newDeviceQueue.sync {
            
            // a new USB device has been added, first check if RTL
            if( (usbDevice.usbVendorID == 0x1d50) && (usbDevice.usbProductID == 0x6089) )  {
            
//                let serialCString = (usbDevice.usbSerialNumber as NSString).utf8String

                hackrfDevice = HackRF(device: usbDevice)
//                hackrfDevice?.initDevice()
            }
            
        }
                
        return hackrfDevice
        
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
//    let name:               String

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
    private let asyncReadQueueLabel:    String = "HackRF.asyncReadQueue"
    
    private var libhackrfPointer:       OpaquePointer?  = nil
    private var libhackrfIndex:         UInt32  = 0        //{
//        get {
//            let index = rtlsdr_get_index_by_serial((self.usbSerial as NSString).utf8String)
//            return UInt32(index)
//        }
//  }
    
    private var bufferSize:             Int          = 16384 * 2
    
    private var sampleBuffer:           [UInt8]
    
    private var _isConfigured:          Bool    = false
    
    private var _sampleRate:            Int     = 2400000 {
        didSet {
            if(self.isOpen() == true) {
                let rate = UInt32(self._sampleRate)
//                rtlsdr_set_sample_rate(self.librtlsdrPointer, rate)
            }
        }
    }
    
    private var _tunedFrequency:        Int     = 0 {
        didSet {
            if(self.isOpen() == true) {
                let frequency = UInt32(self._tunedFrequency)
//                rtlsdr_set_center_freq(self.librtlsdrPointer, frequency)
            }
        }
    }
    
    private var _correction:            Int     = 0 {
        didSet {
            if(self.isOpen() == true) {
                let correction = Int32(self._correction)
//                rtlsdr_set_freq_correction(self.librtlsdrPointer, correction)
            }
        }
    }
    
    private var _tunerGainList:         [Int]   = []
    
    private var _tunerAutoGain:         Bool    = false {
        didSet {
            if(self.isOpen() == true) {
                if(self._tunerAutoGain == true) {
//                    rtlsdr_set_tuner_gain_mode(self.librtlsdrPointer, RTLSDR.gainModeAuto)
                } else {
//                    rtlsdr_set_tuner_gain_mode(self.librtlsdrPointer, RTLSDR.gainModeManual)
//                    rtlsdr_set_tuner_gain(self.librtlsdrPointer, Int32(self._tunerGain))
                }
            }
        }
    }
    
    private var _tunerGain:             Int     = 0 {
        didSet {
            if(self.isOpen() == true) {
                let gain = Int32(self._tunerGain)
//                rtlsdr_set_tuner_gain(self.librtlsdrPointer, gain)
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
        
        return HackRF._sampleRates

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

        if(libhackrfPointer != nil) {
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
        
//        rtlsdr_open(&librtlsdrPointer, librtlsdrIndex)
        
    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------

    func close() {
        
        if(self.isOpen() == true) {
//            rtlsdr_close(librtlsdrPointer)
//            librtlsdrPointer = nil
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
//            self.initDevice()
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
//        rtlsdr_reset_buffer(self.librtlsdrPointer)
        
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
//            rtlsdr_cancel_async(self.librtlsdrPointer)
        }
        
    }
 
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------

    func readAsyncFromDevice() {
 
        asyncReadQueue.async {
        
//            let rtlSdrContext = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
//            
//            
//            rtlsdr_read_async(self.librtlsdrPointer,
//                // use a closure as the callback function
//                {
//                    (buffer: UnsafeMutablePointer<UInt8>?, length: UInt32, ctx: UnsafeMutableRawPointer?) -> Void in
//                    
//                        let selfRTLSDR =  Unmanaged<RTLSDR>.fromOpaque(ctx!).takeUnretainedValue()
//                                        
//                        // get a buffer pointer with length to samples
//                        let bufferPointer = UnsafeMutableBufferPointer(start: buffer, count: Int(length))
//                    
//                        // convert buffer to Swift [UInt8]
//                        let samples: [UInt8] = Array(bufferPointer)
//                    
//                    
//                        selfRTLSDR.delegate?.sdrDevice(selfRTLSDR, rawSamples: samples)
//                    
//                },
//                // end call back closure
//                rtlSdrContext, UInt32(0), UInt32(self.bufferSize)
//            )
            
        }
        
    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------

    
    fileprivate init(device: USBDevice){
        
        usbManufacture  = device.usbVendorName
        usbProduct      = device.usbProductName
        usbSerial       = device.usbSerialNumber
        usbName         = usbManufacture + " " + usbProduct + " SN: " + usbSerial
        
        asyncReadQueue  = DispatchQueue(label: "\(asyncReadQueueLabel).\(usbName)")
        sampleBuffer    = [UInt8](repeating: 0, count: bufferSize)
        
        super.init()

        self.usbDevice      = device
//        _sampleRate = Int(HackRF._sampleRates.max()!)
        
        print("HackRF: initing:    <\(self.usbName)>")

    }
    
    deinit {
        
        print("HackRF: de-initing: <\(self.usbName)>")
        
    }
}
