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
}
