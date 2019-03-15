//
//  SoftwareDefinedRadio.swift
//  waveSDR
//
//  Copyright © 2017 GetOffMyHack. All rights reserved.
//

import Foundation
import Accelerate
import AVFoundation

class SoftwareDefinedRadio: NSObject, SDRDeviceDelegate {
    
    static let audioSampleRate = 48000
    
    var workQueue:          DispatchQueue = DispatchQueue(label: "SoftwareDefinedRadio.WorkQueue")

    @objc dynamic var selectedDevice: SDRDevice? {
        didSet {
            oldValue?.delegate = nil
            selectedDevice!.delegate = self
        }
    }
    
    var deviceList:             [SDRDevice] = []
    
    var isRunning:              Bool    = false
    
    var isPaused:               Bool    = false
    
    var deviceCount:            Int     = 0

    var frequency:              Int     = 0 {
        didSet {
            if let sdr = selectedDevice {
                workQueue.async {
                    sdr.tunedFrequency(frequency: self.frequency)
                }
            }
        }
    }
    
    var frequencyCorrection:    Int    = 0 {
        didSet {
            if let sdr = selectedDevice {
                sdr.frequencyCorrection(correction: self.frequencyCorrection)
            }
        }
    }
    
    var sampleRate:             Int    = 2400000 {
        didSet {
            if let sdr = selectedDevice {
                sdr.sampleRate(rate: self.sampleRate)
            }
            if let radio = self.radio {
                radio.updateIFSampleRate(rate: self.sampleRate)
            }
        }
    }
    
    var tunerAutoGain:          Bool   = false {
        didSet {
            if let sdr = selectedDevice {
                sdr.tunerAutoGain(auto: self.tunerAutoGain)
            }
        }
    }
    
    var tunerGain:              Int    = 0 {
        didSet {
            if let sdr = selectedDevice {
                sdr.tunerGain(gain: self.tunerGain)
            }
        }
    }
    
    var squelchValue:           Float = 0.0 {
        didSet {
            self.radio?.updateSquelch(value: squelchValue)
        }
    }
    
    var localOscillator:        Int = 0 {
        didSet {
            self.radio?.updateMixer(oscillator: localOscillator)
            self.radio?.resetToneDecoder();
        }
    }
    
    var radio:                  Radio? {
        didSet {
            // since the radio blocks contain hard links to the next, the teardown()
            // methed is used to tell each block to unlink itself from the
            // next (via the samplesOut function)
            if let radio = oldValue {
                radio.teardown()
            }

        }
    }
    
    var radioQueue:         DispatchQueue

    private var _index:     Int                 = 0
    var sampleIndex:        Int {
        get {
            var index: Int!
            self.bufferQueue.sync {
                index = self._index
            }
            return index
        }
        
        set {
            self.bufferQueue.async {
                self._index = newValue
            }
        }

    }
    
    var sampleBuffer:       [[UInt8]]           = []

    var bufferQueue:        DispatchQueue       = DispatchQueue(label: "com.getoffmyhack.waveSDR.SoftwareDefinedRadio.bufferQueue")
    var dequeueQueue:       DispatchQueue       = DispatchQueue(label: "com.getoffmyhack.waveSDR.SoftwareDefinedRadio.dequeueQueue")
    
    // The audio engine manages the sound system.
    let audioEngine:		AVAudioEngine		= AVAudioEngine()
    
    // The player node schedules the playback of the audio buffers.
    let audioPlayerNode:	AVAudioPlayerNode	= AVAudioPlayerNode()
    
    // filter node creates high-pass filter
    let audioFilterNode:    AVAudioUnitEQ       =  AVAudioUnitEQ(numberOfBands: 1)
    var audioFilterParams:  AVAudioUnitEQFilterParameters?

    
    // Use standard non-interleaved PCM audio.
    let audioFormat:		AVAudioFormat		= AVAudioFormat(standardFormatWithSampleRate: 48000.0, channels: 1)!
    
    // audio buffer
    let audioBuffer:		AVAudioPCMBuffer	= AVAudioPCMBuffer()
    

    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------

    override init() {
        
        radioQueue  = DispatchQueue(label: "com.getoffmyhack.wavesdr.sdrQueue", attributes: [])
        
        super.init()

        //----------------------------------------------------------------------
        //
        // get a list of all SDR hardware devices currently installed
        //
        // currently this is hard coded to the RTLSDR devices, but will 
        // ultimatly be replaced with a plug-in architecture such that
        // any number of different hardware platforms can be enumerated
        //
        //----------------------------------------------------------------------

        let rtlsdrList = RTLSDR.deviceList()
        deviceList  += rtlsdrList
        deviceCount  = deviceList.count
        
        // configure audio system
        // Attach and connect the player node.
        audioFilterParams = audioFilterNode.bands.first
        audioFilterNode.bypass = false
        
        audioFilterParams!.filterType = .highPass
        audioFilterParams!.frequency = 500
        audioFilterParams!.bypass = false
        
        audioEngine.attach(audioFilterNode)
        audioEngine.attach(audioPlayerNode)
        
        audioEngine.connect(audioPlayerNode, to: audioFilterNode, format: audioFormat)
        audioEngine.connect(audioFilterNode, to: audioEngine.mainMixerNode, format: audioFormat)
//        audioEngine.connect(audioFilterNode, to: audioEngine.outputNode, format: audioFormat)

        
        NotificationCenter.default.addObserver(
            self,
            selector:   #selector(observedAVAudioEngineConfigurationChangeNotification(_:)),
            name:       Notification.Name.AVAudioEngineConfigurationChange,
            object:     audioEngine
        )


    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------

    func start() {

        // attempt to start the audio engine
        do {
            try audioEngine.start()
        } catch let error as NSError {
            print("Error: \(error.domain)")
        }
        
        // start the player node
        audioPlayerNode.play()
        
        // start streaming samples from device
        selectedDevice!.startSampleStream()
        
        // start watchdog timer
        
        // set sample index to start dequeuing samples
//        self.sampleIndex = 0
        
        
        self.isRunning = true
    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------

    func stop() {
        
        // stop SDR samples
        selectedDevice!.stopSampleStream()
        
        // stop audio player
        audioPlayerNode.stop()
        
        // stop audio system
        audioEngine.stop()

        self.isRunning = false
        
    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------
    
    func dequeueSamples() {
        if self.isPaused == false {
            dequeueSamplesWithIndex()
        }
        
    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------

    func goLive() {
        
        self.sampleIndex = (self.sampleBuffer.endIndex - 1)
        self.isPaused = false
        
    }

    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------

    func dequeueSamplesWithIndex(/*_ index: Int*/) {
        
        self.dequeueQueue.async {

//            let rawSamples = self.sampleBuffer[self.sampleIndex]
//            self.sampleIndex += 1
            
            let rawSamples = self.sampleBuffer.popLast()!
            
            // get samples count
            let sampleLength = vDSP_Length(rawSamples.count)
            let sampleCount  = rawSamples.count
        
            // create stride constants
            let strideOfOne = vDSP_Stride(1)
            let strideOfTwo = vDSP_Stride(2)
        
            // create scalers
            var addScaler:  Float = -127.5
            var divScaler:  Float = 127.5
            var zeroScaler: Float = 0.0
        
            // create float array
            var floatSamples: [Float] = [Float](repeating: 0.0, count: sampleCount)
        
            // create split arrays for complex separation
            var realSamples: [Float] = [Float](repeating: 0.0, count: (sampleCount / 2) )
            var imagSamples: [Float] = [Float](repeating: 0.0, count: (sampleCount / 2) )
        
            // convert the raw UInt8 values into Floats
            vDSP_vfltu8(rawSamples, strideOfOne, &floatSamples, strideOfOne, sampleLength)
        
            // convert 0.0 ... 255.0 -> -127.5 ... 127.5
            vDSP_vsadd(floatSamples, strideOfOne, &addScaler, &floatSamples, strideOfOne, sampleLength)
        
            // normalize values to -1.0 -> 1.0
            vDSP_vsdiv(floatSamples, strideOfOne, &divScaler, &floatSamples, strideOfOne, sampleLength)
        
            // the following two vDSP_vsadd calls are used only as a means of
            // optimizing a for loop used to separate the I and Q values into
            // their own arrays
            vDSP_vsadd(&(floatSamples) + 0, strideOfTwo, &zeroScaler, &realSamples, strideOfOne, (sampleLength / 2) )
            vDSP_vsadd(&(floatSamples) + 1, strideOfTwo, &zeroScaler, &imagSamples, strideOfOne, (sampleLength / 2) )
        
            // create samples object
            let samples = Samples(samplesType: .complex, realArray: realSamples, imagArray: imagSamples)
            
            // send samples to start of DSP chain
            guard let radio = self.radio else {
                fatalError("No radio configured")
            }
    
            radio.samplesIn(samples)
        }
     
    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------
    
    @objc func observedAVAudioEngineConfigurationChangeNotification(_ notification: Notification) {
        
        Swift.print("audio engine config changed!!")

        // stop audio player
        audioPlayerNode.stop()
        
        // stop audio system
        audioEngine.stop()
        
        do {
            try audioEngine.start()
        } catch let error as NSError {
            print("Error: \(error.domain)")
        }
        
        // start the player node
        audioPlayerNode.play()

    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------

    func setMode(_ mode: String) {
        
        switch mode {
            case "AM":
                self.radio = Radio.amDemodulator(sampleRateIn: sampleRate, sampleRateOut: SoftwareDefinedRadio.audioSampleRate, frequency: localOscillator)
            case "NFM":
                self.radio = Radio.nfmDemodulator(sampleRateIn: sampleRate, sampleRateOut: SoftwareDefinedRadio.audioSampleRate, frequency: localOscillator)
            case "WFM":
                self.radio = Radio.wfmDemodulator(sampleRateIn: sampleRate, sampleRateOut: SoftwareDefinedRadio.audioSampleRate, frequency: localOscillator)
            default:
                self.radio = Radio.nfmDemodulator(sampleRateIn: sampleRate, sampleRateOut: SoftwareDefinedRadio.audioSampleRate, frequency: localOscillator)
        }
        
        // configure radio output method
        self.radio?.samplesOut = processAudio
        self.radio?.updateSquelch(value: squelchValue)
        
    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------
    
    func getStatusFor(key: String) -> Any? {
        
        if let value = self.radio?.getRadioStatusFor(key: key) {
            return value
        }
        return nil
        
    }
    
}

extension SoftwareDefinedRadio {

    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------
    
    func processAudio(samples: Samples) {
        
        var audioBuffer:		AVAudioPCMBuffer
        var audioBufferData:	UnsafeMutablePointer<Float>
        
        audioBuffer = AVAudioPCMBuffer(pcmFormat: self.audioFormat, frameCapacity: AVAudioFrameCount(samples.count))!
        audioBuffer.frameLength = AVAudioFrameCount(samples.count)
        
        audioBufferData = (audioBuffer.floatChannelData?[0])!
        
        // copy PCM data to audio buffer
        for i in 0..<samples.count {
            audioBufferData[i] = samples.audio[i]
        }
        
        self.audioPlayerNode.scheduleBuffer(audioBuffer)
        
    }

}

//------------------------------------------------------------------------------
//
// MARK: - SDRDevice Delegate
//
// This extension is where the SDRDevice delegate method is called in
// order to start the DSP chain on the received samples
//
//------------------------------------------------------------------------------

extension SoftwareDefinedRadio {
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------

    func sdrDevice(_ device: SDRDevice, rawSamples: [UInt8]) {
        
        radioQueue.async {
            
            // buffer samples
            self.sampleBuffer.append(rawSamples)
            
            // dequeue buffer
            self.dequeueSamples()
            
        }
    }

    
}
