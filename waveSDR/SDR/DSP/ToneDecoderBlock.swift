//
//  ToneDecoderBlock.swift
//  waveSDR
//
//  Copyright © 2017 GetOffMyHack. All rights reserved.
//

import Foundation
import Accelerate

class ToneDecoderBlock: RadioBlock {
    
    enum ToneDecoderState {
        case    idle
        case    running
        case    locked
        case    reset
    }
    
    let π: Double = Double.pi
    
    var notifyQueue:    DispatchQueue?
    var processQueue:   DispatchQueue       = DispatchQueue(label: "Tone Decoder Process Queue")

    var samplesOut:     ((Samples) -> ())?  = nil
    
    var name:           String              = "ToneDecoder"
    
    var decoderState:   ToneDecoderState    = .idle
    
    var tones:          [Double]    = []
    
    var coefficients:   [Double]    = []
    var sampleRate:     Int
    
    var output:         [Double]    = []
    var delayOne:       [Double]    = []
    var delayTwo:       [Double]    = []
    var power:          [Double]    = []
    var relativePower:  [Int]       = []
    var tone:           Double      = 0.0 {
        didSet {
            let userInfo: [String : Any] = [toneDecoderUpdatedKey : tone]
            NotificationCenter.default.post(name: .toneDecoderUpdatedNotification, object: self, userInfo: userInfo)
        }
    }
    
    var tempSampleCount: Int = 0

    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------

    init(withNotifyQueue queue: DispatchQueue, sampleRate rate: Int, toneList tones: [Double]) {
        
        self.notifyQueue    = queue
        self.tones          = tones
        self.sampleRate     = rate
        
        let count = tones.count
        
        for i in 0..<count {
            let coefficient = 2.0 * cos(2.0 * π *  self.tones[i] / Double(self.sampleRate))
            coefficients.append(coefficient)
            output.append(0.0)
            delayOne.append(0.0)
            delayTwo.append(0.0)
            power.append(0.0)
            relativePower.append(0)
        }
        
    }
    
    deinit {

    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------

    func unlink() {
        self.samplesOut = nil
    }

    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------

    func samplesIn(_ samples: Samples) {
        
        // drop into dispatch queue so the next block can take the samples
        processQueue.async {
            
            // check for zero audio, full squelch so reset filter
            if (samples.audio.reduce(0, +) == 0) {
                if self.decoderState != .idle {
                    self.decoderState = .idle
                    self.resetFilter()
                }
            } else {
                if(self.decoderState != .locked && self.decoderState != .reset) {
                    self.decoderState = .running
                }
            }
            
            // check which state
            switch self.decoderState {
            case .reset:
                self.resetFilter()
                self.decoderState = .running
                break
            
            case .running:
                self.getTone(samples)
                break
                
            default:
                break
            }
            
        }
        
        // the reference to samplesOut may become nil at any time so
        // check to make sure it exists before sending samples out
        if(samplesOut != nil) {
            self.samplesOut!(samples)
        }
        
    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------

    func resetFilter() {
        
        self.tone = 0.0

        let count = self.coefficients.count
        
        self.output.removeAll(keepingCapacity: true)
        self.delayOne.removeAll(keepingCapacity: true)
        self.delayTwo.removeAll(keepingCapacity: true)
        self.power.removeAll(keepingCapacity: true)
        self.relativePower.removeAll(keepingCapacity: true)
        
        self.output         = Array(repeating: 0.0, count: count)
        self.delayOne       = Array(repeating: 0.0, count: count)
        self.delayTwo       = Array(repeating: 0.0, count: count)
        self.power          = Array(repeating: 0.0, count: count)
        self.relativePower  = Array(repeating: 0,   count: count)
        
        self.tempSampleCount = 0
        
    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------

    func getTone(_ samples: Samples) {
        
        // step through the audio samples
        for i in 0..<samples.count {
            self.tempSampleCount += 1
            let sample = Double(samples.audio[i])
            
            // compute power for each tone (pre-computed coefficients)
            for j in  0..<self.coefficients.count {
                self.output[j]   = sample + self.coefficients[j] * self.delayOne[j] - self.delayTwo[j]
                self.delayTwo[j] = self.delayOne[j]
                self.delayOne[j] = self.output[j]
                
                let delayTwoSquared = self.delayTwo[j] * self.delayTwo[j]
                let delayOneSquared = self.delayOne[j] * self.delayOne[j]
                
                self.power[j] = delayTwoSquared + delayOneSquared - self.coefficients[j] * self.delayOne[j] * self.delayTwo[j]
            }
            
        }
        
//        print(power)
        // replace with .reduce
        var totalPower = 0.00000000001
        for i in 0..<self.coefficients.count {
            totalPower += self.power[i]
        }
        
        // replace with .map
        for i in 0..<self.coefficients.count {
            let powerPercent =  (self.power[i] / totalPower) * 100
            self.relativePower[i] = Int(powerPercent)
        }
//        print(relativePower)
        // find a better method of detecting if a tone is present
        let maxPower = self.relativePower.max()!

        if (maxPower > 70) {
            
            let maxPowerIndex   = self.relativePower.firstIndex(of: maxPower)!
            self.tone           = self.tones[maxPowerIndex]
            self.decoderState   = .locked
            
        }
        
    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------
    
    func getStatusFor(key: String) -> Any? {
        
        if key == toneDecoderKey {
            return self.tone
        }

        return nil
    }


}
