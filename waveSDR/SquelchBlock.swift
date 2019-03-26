//
//  SquelchBlock.swift
//  waveSDR
//
//  Copyright © 2017 GetOffMyHack. All rights reserved.
//

//
// simple power squelch.  Need to create noise squelch
//

import Foundation
import Accelerate

class SquelchBlock: RadioBlock {
    
    var notifyQueue:        DispatchQueue?
    
    var squelch:            Float               = 0.0
    
    var averageDB:          Float               = 0.0
    
    var squelchPercent:     Int                 = 0
    
    var lastSquelchPercent: Int                 = 0
    
    var samplesOut:         ((Samples) -> ())?  = nil
    
    var name:               String              = "Squelch Block"
    
    var maxMag:             Float               = 0.0
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------

    init() {
        notifyQueue = nil
    }
    
    init(withNotifyQueue queue: DispatchQueue) {
        notifyQueue = queue
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
        
        // need to create a mutable copy of input samples
        var samples = samples
        
        var magnitudes: [Float] = [Float](repeating: 0.0, count: samples.count)
        
        var complexSamples: DSPSplitComplex = samples.asDSPSplitComplex()
        
        // get magnitudes squared: C = Re^2 + Im^2
        vDSP_zvmags(&complexSamples, vDSP_Stride(1), &magnitudes, vDSP_Stride(1), vDSP_Length(samples.count))
        
        // https://developer.apple.com/library/content/samplecode/aurioTouch/Listings/Classes_FFTHelper_cpp.html
        // In order to avoid taking log10 of zero, an adjusting factor is added in to make the minimum value equal -128dB
        var adjustDB128: Float32 = 1.5849e-13
        //        var kAdjust0DB: Float32 = 0.0000000001  // min value equeal to -100dBFS
        
//        let inMagnitudes = magnitudes
        vDSP_vsadd(magnitudes, vDSP_Stride(1), &adjustDB128, &magnitudes, vDSP_Stride(1), vDSP_Length(samples.count))
        
        // convert to dBFS: C = α * log10(A/dbScale); α = 20 if flag = 1; α = 10 if flag = 0
        let flag:           UInt32  = 0
        var zeroReference:  Float32 = 1.0
        
//        let inMagnitudes2 = magnitudes
        vDSP_vdbcon(magnitudes, vDSP_Stride(1), &zeroReference, &magnitudes, vDSP_Stride(1), vDSP_Length(samples.count), flag)

        // compute average db value
        self.averageDB = magnitudes.reduce(0, +) / Float(magnitudes.count)
    
        if let queue = self.notifyQueue {
            queue.async {
                let userInfo: [String : Any] = [averageDBUpdatedKey : self.averageDB]
                NotificationCenter.default.post(name: .averageDBUpdatedNotification, object: self, userInfo: userInfo)
            }
        }

        // squelch samples if db < squelch value
//        let inMagnitudes3 = magnitudes
        vDSP_vthres(magnitudes, vDSP_Stride(1), &self.squelch, &magnitudes, vDSP_Stride(1), vDSP_Length(samples.count))
        
        // loop through checking for 0 values 
        var squelchCount: Int = 0
        for i in 0..<samples.count {
            if magnitudes[i] == 0 {
                samples.audio[i] = 0
                squelchCount += 1
            }
        }
        
        self.squelchPercent = 100 * squelchCount / samples.count
        
        if lastSquelchPercent != squelchPercent {
            lastSquelchPercent = squelchPercent
            if let queue = self.notifyQueue {
                queue.async {
                    let userInfo: [String : Any] = [squelchPercentUpdatedKey : self.squelchPercent]
                    NotificationCenter.default.post(name: .squelchPercentUpdatedNotification, object: self, userInfo: userInfo)
                }
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
    
    func getStatusFor(key: String) -> Any? {
        
        if key == averageDBKey {
            return self.averageDB
        }
        
        if key == squelchPercentKey {
            return self.squelchPercent
        }
        
        return nil
    }

}

