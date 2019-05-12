//
//  IOUSBDevice.swift
//  waveSDR
//
//  Copyright © 2019 GetOffMyHack. All rights reserved.
//

public struct IOUSBDevice {
    let ioRegistryID:       io_registry_id_t
    let ioRegistryName:     String
    let usbVendorID:        UInt16
    let usbProductID:       UInt16
    let usbSerialNumber:    String
    let usbVendorName:      String
    let usbProductName:     String
    
    public init(
        id:         UInt64,
        name:       String,
        vid:        UInt16,
        pid:        UInt16,
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
