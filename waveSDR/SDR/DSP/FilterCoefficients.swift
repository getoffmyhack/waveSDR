//
//  Filter.swift
//  waveSDR
//
//  Copyright © 2017 GetOffMyHack. All rights reserved.
//

import Foundation
import Accelerate

    
class FilterCoefficients {
    
    enum FilterType {
        case lowPass
        case highPass
        case bandPass
    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------

    
    class func fir(sampleRate: Int, frequency: Int, length: Int)-> [Float] {
        
        let π: Float = Float.pi

        // variable to hold the value of sinc()
        var sinc: Float
        
        // make sure kernel length is odd
        let kernelLength = length + ((length + 1) % 2)
        
        // check to make sure that frequency is <= (rate / 2) (Nyquist)
        if frequency > (sampleRate / 2) {
            fatalError("Frequency \(frequency) greater than Nyquist \(sampleRate / 2)")
        }
        
        // normalize cut off freq between 0.0 and 0.5 of the sample rate
        let fCutoff = Float(frequency) / Float(sampleRate)
        
        // get center point of coefficient array
        let centerPoint = length / 2
        
        // Calculate FIR filter coefficients
        var coefficientArray = [Float](repeating: 0.0, count: kernelLength)
        
        // sum all coeff's
        var kernelSum: Float = 0.0
        
        let ω = Float(2 * π) * fCutoff
        
        // these are going to be symmetrical around the center point
        for i in 0..<kernelLength {
            
            // i-(M/2) shift
            let n = Float(i - centerPoint)
            
            // center point
            if(n == 0.0) {
                sinc = sin(ω)
                
                // all other points
            } else {
                sinc = (sin(ω * n) / n)
            }
            
            // multiply with window function
            sinc *= ( 0.54 - 0.46 * cos(Float(2 * π) * Float(i) / Float(kernelLength) ) )
            
            coefficientArray[i] = sinc
            
            // sum all coeff's to normalize later
            kernelSum += sinc
            
        }
        
        // normalize coeff's for unity gain at DC - the sum of all coeff's
        // will be equal to 1
        coefficientArray = coefficientArray.map({
            (sample: Float) ->Float in
                return sample / kernelSum
        })

        return coefficientArray
    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------

    
    class func iir(type: FilterType, sampleRate: Int, frequency: Int, qValue: Double) -> [Double] {
        
        var a0: Double = 0.0
        var a1: Double = 0.0
        var a2: Double = 0.0
        
        var b0: Double = 0.0
        var b1: Double = 0.0
        var b2: Double = 0.0
        
        let π:  Double = .pi
        let ω:  Double = 2 * π * Double(frequency) / Double(sampleRate)
        let α:  Double = sin(ω) / (2.0 * qValue)
    
        
        switch type {
        
        case .lowPass:

            a0 =  1.0 + α
            a1 = -2.0 * cos(ω)
            a2 =  1.0 - α
            
            b0 = (1.0 - cos(ω)) / 2.0
            b1 =  1.0 - cos(ω)
            b2 = (1.0 - cos(ω)) / 2.0

        case .highPass:
            
            a0 =  1.0 + α
            a1 = -2.0 * cos(ω)
            a2 =  1.0 - α
            
            b0 =  (1.0 + cos(ω)) / 2.0
            b1 = -(1.0 + cos(ω))
            b2 =  (1.0 + cos(ω)) / 2.0
            
        case .bandPass:

            a0 =  1.0 + α
            a1 = -2.0 * cos(ω)
            a2 =  1.0 - α
            
            b0 =  α
            b1 =  0
            b2 = -α

        }
        
        a1 /= a0
        a2 /= a0
        
        b0 /= a0
        b1 /= a0
        b2 /= a0

        return [b0, b1, b2, a1, a2]
    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------

    
    class func pll(bandwidth: Double, dampening: Double, loopGain: Double) -> [Double] {
        
        let ωn: Double  = bandwidth
        let ζ:  Double  = dampening
        let K:  Double  = loopGain
        
        // generate loop filter parameters (active PI design)
        let τ1: Double  = K / (ωn * ωn)
        let τ2: Double  = 2 * ζ / ωn
        
        // feed-forward coefficients (numerator)
        let b0: Double  = (4 * K / τ1) * (1.0 + τ2 / 2.0)
        let b1: Double  = (8 * K / τ1)
        let b2: Double  = (4 * K / τ1) * (1.0 - τ2 / 2.0)
        
        // feed-back coefficients (denominator)
        let a1: Double  = -2.0
        let a2: Double  =  1.0
        
        return [b0, b1, b2, a1, a2]

    }
}
