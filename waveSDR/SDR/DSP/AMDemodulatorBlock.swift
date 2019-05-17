//
//  AMDemodulatorBlock.swift
//  waveSDR
//
//  Copyright © 2017 GetOffMyHack. All rights reserved.
//

import Foundation
import Accelerate

class AMDemodulatorBlock: RadioBlock {
    
    var notifyQueue:    DispatchQueue?
    
    var samplesOut:     ((Samples) -> ())? = nil
    
    var name:           String = "AM"
    
    var amGain:         Float = 5.0
    
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
        self.unlink()
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
        
        // create mutable copy of sample struct
        var samples = samples
        
        // create output buffer
        var output:     [Float]         = [Float](repeating: 0.0, count: samples.count)
        
        // convert to DSPSplitComplex type
        var inSamples:  DSPSplitComplex = samples.asDSPSplitComplex()
        
        // process samples
        vDSP_zvabs(&inSamples, vDSP_Stride(1), &output, vDSP_Stride(1), vDSP_Length(samples.count))
        
        let input = output
        // apply amGain
        vDSP_vsmul(input, vDSP_Stride(1), &amGain, &output, vDSP_Stride(1), vDSP_Length(samples.count))
        
        // update samples struct
        samples.audio = output
        samples.type = .audio
        
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
        return nil
    }

}
