//
//  FMDemodulatorBlock.swift
//  waveSDR
//
//  Copyright © 2017 GetOffMyHack. All rights reserved.
//

import Foundation
import Accelerate

class MixerBlock: RadioBlock {
    
    var notifyQueue:        DispatchQueue?
    
    var samplesOut:         ((Samples) -> ())? = nil
    
    var name:               String  = "Mixer"
    
    var sampleRate:         Int     = 1 {
        didSet {
            self.δ = 2 * π * Float(self.localOscillator) / Float(self.sampleRate)
        }
    }

    var localOscillator:    Int     = 0 {
        didSet {
            self.δ = 2 * π * Float(self.localOscillator) / Float(self.sampleRate)
        }
    }
    
    let π:                  Float   = .pi
    var δ:                  Float   = 0.0
    var lastPhase:          Float   = 0.0
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------

    init(sampleRate: Int, frequency: Int) {
        
        notifyQueue             = nil
        self.sampleRate         = sampleRate
        self.localOscillator    = frequency
        self.δ                  = 2 * π * Float(self.localOscillator) / Float(self.sampleRate)
        
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
        
        var samples = samples
        
        if(localOscillator != 0) {
            var inSamples = samples.asDSPSplitComplex()

//             δ=2πf/fs
//             ϕ[n]=(ϕ[n−1]+δ) mod 2π
            
            var phaseArray:     [Float] = []
            var ϕ:   Float   = 0.0
            
            // create the phaseArray needed to create the complex oscillator
            for _ in 0..<samples.count {
                
                ϕ = δ + lastPhase
                ϕ.formRemainder(dividingBy: (2 * π))
                phaseArray.append(ϕ)
                lastPhase = ϕ
                
            }
            
            // create the oscillator
            // TODO: replace with vvcosisinf(_:​_:​_:​)
            var loReal: [Float] = [Float](repeating: 0.0, count: samples.count)
            var loImag: [Float] = [Float](repeating: 0.0, count: samples.count)
            var oscillator: DSPSplitComplex = DSPSplitComplex(realp: &loReal, imagp: &loImag)
            var samplesCount: Int32 = Int32(samples.count)
            vvcosf(&loReal, &phaseArray, &samplesCount)
            vvsinf(&loImag, &phaseArray, &samplesCount)
            
            // mix the original signal with the oscillator (in place)
            let conjugateMultiplication:    Int32 = -1
            vDSP_zvmul(
                &inSamples,
                vDSP_Stride(1),
                &oscillator,
                vDSP_Stride(1),
                &inSamples,
                vDSP_Stride(1),
                vDSP_Length(samplesCount),
                conjugateMultiplication
            )
            
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
        return nil
    }

}
