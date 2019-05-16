//
//  IOUSBDevice.swift
//  waveSDR
//
//  Copyright © 2019 GetOffMyHack. All rights reserved.
//

public typealias io_registry_id_t = UInt64

//--------------------------------------------------------------------------
//
// IOUSBDevice
//
// simple struct which represents the USB device data
//
//--------------------------------------------------------------------------

public struct USBDevice: Hashable, CustomStringConvertible {
    let ioRegistryID:       io_registry_id_t
    let ioRegistryName:     String
    let usbVendorID:        Int
    let usbProductID:       Int
    let usbSerialNumber:    String
    let usbVendorName:      String
    let usbProductName:     String
    
    //--------------------------------------------------------------------------
    //
    // creates a print -able representation of the object
    //
    //--------------------------------------------------------------------------
    
    public var description:   String {
        get {
            let returnString =
"""
   ioRegistryID: \(self.ioRegistryID)
 ioRegistryName: \(self.ioRegistryName)
    usbVendorID: \(self.usbVendorID)
   usbProductID: \(self.usbProductID)
usbSerialNumber: \(self.usbSerialNumber)
  usbVendorName: \(self.usbVendorName)
 usbProductName: \(self.usbProductName)
            
"""
            return returnString
        }
    }
    
    //--------------------------------------------------------------------------
    //
    // init new struct with required USB data
    //
    //--------------------------------------------------------------------------
    
    public init(
        id:         io_registry_id_t,
        name:       String,
        vid:        Int,
        pid:        Int,
        serial:     String,
        vendor:     String,
        product:    String
    ) {
        
        self.ioRegistryID       = id
        self.ioRegistryName     = name
        self.usbVendorID        = vid
        self.usbProductID       = pid
        self.usbSerialNumber    = serial
        self.usbVendorName      = vendor
        self.usbProductName     = product
        
    }
}
