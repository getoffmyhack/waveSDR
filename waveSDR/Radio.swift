//
//  Radio.swift
//  waveSDR
//
//  Copyright © 2017 GetOffMyHack. All rights reserved.
//

import Foundation
import Accelerate
import AVFoundation



//
//
//******************************************************************************
//
// Radio Class
//
// A chain of Radio blocks to perform a start to finsh DSP chain
//
// An instance of Radio conforms to the RadioBlock protocol and as such can be
// used as a block in a larger radio block chain.
//
//******************************************************************************
//
//

class Radio: RadioBlock {

    var name:           String              = "Radio"
    
    var _blocks:        [RadioBlock]        = []

    var notifyQueue:    DispatchQueue?
    var radioQueue:     DispatchQueue
    
    var samplesOut:     ( (Samples) ->() )? = nil
    
    //--------------------------------------------------------------------------
    //
    // initalizers / deinitalizer
    //
    //--------------------------------------------------------------------------

    init() {
        radioQueue  = DispatchQueue(label: "com.getoffmyhack.wavesdr.radioQueue", attributes: [])
    }
    
    deinit {
        
    }
    
    //--------------------------------------------------------------------------
    //
    // unlink()
    //
    // remove samplesOut pointer to next radio block
    //
    //--------------------------------------------------------------------------

    func unlink() {
        self.samplesOut = nil
    }
    
    //--------------------------------------------------------------------------
    //
    // teardown()
    //
    // teardown all radio blocks by unlinking each one
    //
    //--------------------------------------------------------------------------

    func teardown() {
        for block in _blocks {
            block.unlink()
        }
        self.unlink()
    }
    
    //--------------------------------------------------------------------------
    //
    // samplesSink()
    //
    // sink the samples into the last DSP block
    //
    //--------------------------------------------------------------------------

    func samplesSink(samples: Samples) {
        
        // do any final processing if needed
        
        // if configured with output function call with samples
        if let outCall = samplesOut {
            outCall(samples)
        }
        
    }
    
    //--------------------------------------------------------------------------
    //
    // samplesIn()
    //
    // send samples to first block of DSP chain
    //
    //--------------------------------------------------------------------------

    func samplesIn(_ samples: Samples) {
        
        // do any pre processing if needed

        radioQueue.async {
            
            // call method of first RadioBlock in array
            guard let firstBlock = self._blocks.first  else {
                fatalError("No radio blocks")
            }
            
            firstBlock.samplesIn(samples)
            
        }

    }
    
    //--------------------------------------------------------------------------
    //
    // appendBlock()
    //
    // appends a new DSP block to end of chaing managing references as needed
    //
    //--------------------------------------------------------------------------

    func appendBlock(_ block: RadioBlock) {
        
        var inBlock = block
        
        // check if there is a previous block in chain
        if(self._blocks.count > 0) {
            
            // get last block off of chain
            var lastBlock = self._blocks.popLast()!
            
            // set last block's samplesOut var to the new block's "in" method
            lastBlock.samplesOut = inBlock.samplesIn

            // re-add the last block to DSP chain
            self._blocks.append(lastBlock)
        }
        
        // set new block's sampleOut to Radio's samplesSink
        inBlock.samplesOut = self.samplesSink
        
        // append to private blocks array
        _blocks.append(inBlock)
    }
    
    //--------------------------------------------------------------------------
    //
    // getStatusForKey()
    //
    // return status information for requested key
    //
    //--------------------------------------------------------------------------
    
    func getStatusFor(key: String) -> Any? {
        return nil
    }

}

//
//
//******************************************************************************
//
//  class method used as object facories to create a working radio
//
//******************************************************************************
//
//


extension Radio {
    
    //--------------------------------------------------------------------------
    //
    // create a narrow FM radio
    //
    //--------------------------------------------------------------------------

    class func nfmDemodulator(sampleRateIn inRate: Int, sampleRateOut outRate: Int, frequency: Int) -> Radio {
        
        let ctcssTones: [Double] = [
            67.0,  69.3,  71.9,  74.4,  77.0,  79.7,  82.5,  85.4,  88.5,  91.5,
            94.8,  97.4, 100.0, 103.5, 107.2, 110.9, 114.8, 118.8, 123.0, 127.3,
            131.8, 136.5, 141.3, 146.2, 151.4, 156.7, 159.8, 162.2, 165.5, 167.9,
            171.3, 173.8, 177.3, 179.9, 183.5, 186.2, 189.9, 192.8, 196.6, 199.5,
            203.5, 206.5, 210.7, 218.1, 225.7, 229.1, 233.6, 241.8, 250.3, 254.1
        ]
        
        let nfmRadio:       Radio           = Radio()
        let queue:          DispatchQueue   = DispatchQueue(label: "com.getoffmyhack.waveSDR.notifyQueue", attributes: DispatchQueue.Attributes.concurrent)
        
        let fft:            RadioBlock  = FFTBlock(withNotifyQueue: queue)
        let mixer:          RadioBlock  = MixerBlock(sampleRate: inRate, frequency: frequency)
        let ifFilter:       RadioBlock  = ComplexFilterBlock(sampleRateIn: inRate, sampleRateOut: outRate, cutoffFrequency: 5000, kernelLength: 500, name: "IFFilter")
        let demodulator:    RadioBlock  = FMDemodulatorBlock()
        let squelch:        RadioBlock  = SquelchBlock(withNotifyQueue: queue)
        let decoder:        RadioBlock  = ToneDecoderBlock(withNotifyQueue: queue, sampleRate: outRate, toneList: ctcssTones)

        nfmRadio.appendBlock(fft)
        nfmRadio.appendBlock(mixer)
        nfmRadio.appendBlock(ifFilter)
        nfmRadio.appendBlock(demodulator)
        nfmRadio.appendBlock(squelch)
        nfmRadio.appendBlock(decoder)
        
        return nfmRadio
        
    }
    
    //--------------------------------------------------------------------------
    //
    // create a wide FM (mono) radio
    //
    //--------------------------------------------------------------------------

    class func wfmDemodulator(sampleRateIn inRate: Int, sampleRateOut outRate: Int, frequency: Int) -> Radio {
        
        let wfmRadio:       Radio           = Radio()
        let queue:          DispatchQueue   = DispatchQueue(label: "com.getoffmyhack.waveSDR.notifyQueue", attributes: DispatchQueue.Attributes.concurrent)
        
        let fft:            RadioBlock  = FFTBlock(withNotifyQueue: queue)
        let mixer:          RadioBlock  = MixerBlock(sampleRate: inRate, frequency: frequency)
        let ifFilter:       RadioBlock  = ComplexFilterBlock(sampleRateIn: inRate, sampleRateOut: 480000, cutoffFrequency: 200000, kernelLength: 300, name: "IFFilter")
        let demodulator:    RadioBlock  = FMDemodulatorBlock()
        let afFilter:       RadioBlock  = FilterBlock(sampleRateIn: 480000, sampleRateOut: outRate, cutoffFrequency: 15000, kernelLength: 300, name: "AFFilter")
        let squelch:        RadioBlock  = SquelchBlock(withNotifyQueue: queue)
        
        wfmRadio.appendBlock(fft)
        wfmRadio.appendBlock(mixer)
        wfmRadio.appendBlock(ifFilter)
        wfmRadio.appendBlock(demodulator)
        wfmRadio.appendBlock(afFilter)
        wfmRadio.appendBlock(squelch)
        
        return wfmRadio
        
    }

    //--------------------------------------------------------------------------
    //
    // create AM radio
    //
    //--------------------------------------------------------------------------

    class func amDemodulator(sampleRateIn: Int, sampleRateOut: Int, frequency: Int) -> Radio {
        
        let amRadio:        Radio           = Radio()
        let queue:          DispatchQueue   = DispatchQueue(label: "com.getoffmyhack.waveSDR.notifyQueue", attributes: DispatchQueue.Attributes.concurrent)
        
        let fft:            RadioBlock  = FFTBlock(withNotifyQueue: queue)
        let mixer:          RadioBlock  = MixerBlock(sampleRate: sampleRateIn, frequency: frequency)
        let ifFilter:       RadioBlock  = ComplexFilterBlock(sampleRateIn: sampleRateIn, sampleRateOut: sampleRateOut, cutoffFrequency: 5000, kernelLength: 300, name: "IFFilter")
        let demodulator:    RadioBlock  = AMDemodulatorBlock()
        let squelch:        RadioBlock  = SquelchBlock(withNotifyQueue: queue)
        
        amRadio.appendBlock(fft)
        amRadio.appendBlock(mixer)
        amRadio.appendBlock(ifFilter)
        amRadio.appendBlock(demodulator)
        amRadio.appendBlock(squelch)
        
        return amRadio
        
    }
    
}

//
//******************************************************************************
//
// Functions for modifying the DSP blocks while currently running
//
// TODO:  Change block names to constants
//
//******************************************************************************
//

extension Radio {
    
    //--------------------------------------------------------------------------
    //
    // updateSquelch()
    //
    // update the squelch level in the squelch block
    //
    //--------------------------------------------------------------------------

    func updateSquelch(value: Float) {
        for i in 0..<_blocks.count {
            if(_blocks[i].name == "Squelch Block") {
                (_blocks[i] as! SquelchBlock).squelch = value
            }
        }
    }
    
    //--------------------------------------------------------------------------
    //
    // updateIFSampleRate()
    //
    // update samplerate for all blocks that depend on the samplerate value
    //
    //--------------------------------------------------------------------------

    func updateIFSampleRate(rate: Int) {
        for i in 0..<_blocks.count {
            
            if(_blocks[i].name == "IFFilter") {
                (_blocks[i] as! ComplexFilterBlock).inRate = rate
            }
            
            if(_blocks[i].name == "Mixer") {
                (_blocks[i] as! MixerBlock).sampleRate = rate
            }
            
        }
    }
    
    //--------------------------------------------------------------------------
    //
    // updateMixer()
    //
    // update the mixer frequency
    //
    //--------------------------------------------------------------------------

    func updateMixer(oscillator: Int) {
        for i in 0..<_blocks.count {
            if(_blocks[i].name == "Mixer") {
                (_blocks[i] as! MixerBlock).localOscillator = oscillator
            }
        }
    }
    
    //--------------------------------------------------------------------------
    //
    // resetToneDecoder()
    //
    // update the mixer frequency
    //
    //--------------------------------------------------------------------------
    
    func resetToneDecoder() {
        for i in 0..<_blocks.count {
            if(_blocks[i].name == "ToneDecoder") {
                (_blocks[i] as! ToneDecoderBlock).decoderState = .reset
            }
        }
    }
    
    //--------------------------------------------------------------------------
    //
    // getRadioStatusForKey()
    //
    // queires radio blocks asking for a specific key to get status data
    //
    //--------------------------------------------------------------------------
    
    func getRadioStatusFor(key: String) -> Any? {
        
        for block in _blocks {
            if let valueForKey = block.getStatusFor(key: key) {
                return valueForKey
            }
        }
        
        return nil
        
    }

}
