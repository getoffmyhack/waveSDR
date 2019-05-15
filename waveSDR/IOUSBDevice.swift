//
//  IOUSBDevice.swift
//  waveSDR
//
//  Copyright © 2019 GetOffMyHack. All rights reserved.
//

typealias io_registry_id_t = UInt64

public struct IOUSBDevice: Hashable, CustomStringConvertible {
    let ioRegistryID:       io_registry_id_t
    let ioRegistryName:     String
    let usbVendorID:        Int
    let usbProductID:       Int
    let usbSerialNumber:    String
    let usbVendorName:      String
    let usbProductName:     String
    
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
    
    public init(
        id:         UInt64,
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
