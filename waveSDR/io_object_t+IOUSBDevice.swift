//
//  io_object_t+IOUSBDevice.swift
//  waveSDR
//
//  Copyright © 2019 GetOffMyHack. All rights reserved.
//

import IOKit
import IOKit.usb

extension io_object_t {
    
    // returns the registry entry id
    func ioRegistryID() -> UInt64 {

        var registryID: UInt64  = 0
        
        guard (IORegistryEntryGetRegistryEntryID(self, &registryID) == kIOReturnSuccess) else {
            fatalError("Unable to get registry entry ID")
        }
        
        return registryID

    }
    
    /// - Returns: The device's name.
    func ioRegistryName() -> String? {
        let buf = UnsafeMutablePointer<io_name_t>.allocate(capacity: 1)
        
        defer {
            buf.deallocate()
        }
        
        return buf.withMemoryRebound(to: CChar.self, capacity: MemoryLayout<io_name_t>.size) {
            if IORegistryEntryGetName(self, $0) == kIOReturnSuccess {
                return String(cString: $0)
            }
            return nil
        }
    }
        
    func usbVendorID() -> Int? {
        var vendorID: Int? = nil
        
        if let cfVendorID = IORegistryEntryCreateCFProperty(self, kUSBVendorID as CFString, kCFAllocatorDefault, 0) {
            vendorID = cfVendorID.takeRetainedValue() as? Int
        }
        
        return vendorID
    }
    
    func usbProductID() -> Int? {
        var productID: Int? = nil
        
        if let cfProductID = IORegistryEntryCreateCFProperty(self, kUSBProductID as CFString, kCFAllocatorDefault, 0) {
            productID = cfProductID.takeRetainedValue() as? Int
        }
        
        return productID
    }
    
    func usbSerialNumber() -> String? {
        var usbSerial: String? = nil
        
        if let cfUSBSerial = IORegistryEntryCreateCFProperty(self, kUSBSerialNumberString as CFString, kCFAllocatorDefault, 0) {
            usbSerial = cfUSBSerial.takeRetainedValue() as? String
        }
        
        return usbSerial
    }
    
    func usbProductName() -> String? {
        var usbProductName: String? = nil
        
        if let cfUSBProductName = IORegistryEntryCreateCFProperty(self, kUSBProductString as CFString, kCFAllocatorDefault, 0) {
            usbProductName = cfUSBProductName.takeRetainedValue() as? String
        }
        
        return usbProductName
    }
    
    func usbVendorName() -> String? {
        var usbVendorName: String? = nil
        
        if let cfUSBVendorName = IORegistryEntryCreateCFProperty(self, kUSBVendorString as CFString, kCFAllocatorDefault, 0) {
            usbVendorName = cfUSBVendorName.takeRetainedValue() as? String
        }
        
        return usbVendorName
    }
}
