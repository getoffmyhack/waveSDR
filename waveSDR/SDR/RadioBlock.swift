//
//  RadioBlock.swift
//  waveSDR
//
//  Copyright © 2017 GetOffMyHack. All rights reserved.
//

import Foundation

protocol RadioBlock {
    
    //--------------------------------------------------------------------------
    //
    // MARK: - Properties
    //
    //--------------------------------------------------------------------------
    
    // a printable name that will be used as a key into blocks array
    var name: String                    { get }
    
    // an optional thread upon which to process the samples
    //    var queue: OperationQueue?          { get set }
    
    // var to hold the output function to call when the RadioBlock completes
    var samplesOut: ( (Samples) ->() )? { get set }
    
    // an optional var for the queue to be used to post Notificaitons
    var notifyQueue: DispatchQueue?     { get set }
    
    //--------------------------------------------------------------------------
    //
    // MARK: - Methods
    //
    //--------------------------------------------------------------------------
    
    // function to call with samples array to start RadioBlock DSP process
    func samplesIn(_ samples: Samples)
    
    // call to unlink output samples reference
    func unlink()
    
    // function to get status values
    func getStatusFor(key: String) -> Any?
    
}
