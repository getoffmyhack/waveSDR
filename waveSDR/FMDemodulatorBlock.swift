//
//  FMDemodulatorBlock.swift
//  waveSDR
//
//  Copyright © 2017 GetOffMyHack. All rights reserved.
//

import Foundation
import Accelerate

class FMDemodulatorBlock: RadioBlock {
    
    var notifyQueue:    DispatchQueue?
    
    var lastI:      Float = 0.0
    var lastQ:      Float = 0.0
    
    let fmGain:     Float = 1.0
    
    var samplesOut: ((Samples) -> ())? = nil
    
    var name:       String = "FM Demodulator Block"
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------

    init() {
        
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
        
        // demodulate to audio & add audio samples to samples object
        let numberOfSamples = samples.count
        
        for idx in 0..<numberOfSamples {
            
            let I	= samples.real[idx]
            let Q	= samples.imag[idx]
            
            let num = ( (I * lastQ) - (Q * lastI) )
            //        -----------------------------
            let den = (     (I * I) + (Q * Q)     ) + 0.0000000001 // add epsilon to avoid division by zero
            
            samples.audio.append(self.fmGain * (num / den))
            
            self.lastI = I
            self.lastQ = Q
            
        }
        
        // update type of samples
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
    
    //
    // demodulate FM
    //
    // takes iq samples and demodulates narrow FM
    //
    
    /*------------------------------------------------------------------------*\
     
     f[n]	= arg{x[n+1]} - arg{x[n]}
     
     = arctan(
     (Im{x[n+1]}*Re{x[n]} - Re{x[n+1]}*Im{x[n]})
     /
     (Re{x[n+1]}*Re{x[n]} + Im{x[n+1]}*Im{x[n]})
     )
     
     f[n] =	(IQ'-QI')
            ---------
            (I^2+Q^2)
     
     f = angle(x(2:N).*conj(x(1:N-1)))/2/pi;
     
     \*------------------------------------------------------------------------*/
    

}
