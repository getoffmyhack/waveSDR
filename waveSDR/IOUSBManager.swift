//
//  USBManager.swift
//  waveSDR
//
//  Copyright © 2019 GetOffMyHack. All rights reserved.
//

import Foundation
import IOKit
import IOKit.usb

protocol IOUSBManagerDelegate: class {
    func usbDeviceAdded(_ device: IOUSBDevice)
    func usbDeviceRemoved(_ device: IOUSBDevice)
}

class IOUSBManager {
    
    private static var sharedIOUSBManager: IOUSBManager = {
        let usbManager = IOUSBManager()
        return usbManager
    }()

    private let ioNotificationPort:   IONotificationPortRef
    
    private var ioUSBDeviceList:    [IOUSBDevice] = []
       weak var delegate:           IOUSBManagerDelegate?
    
    private var addedIterator:      io_iterator_t = 0
    private var removedIterator:    io_iterator_t = 0
    
    private let ioUSBManagerQueue:  DispatchQueue           = DispatchQueue(label: "com.getoffmyhack.waveSDR.IOUSBManagerQueue")
    private let matchingDict:       NSMutableDictionary     = IOServiceMatching(kIOUSBDeviceClassName)
    
    private init() {
        
        let notificationPort = IONotificationPortCreate(kIOMasterPortDefault)
        guard notificationPort != nil else {
            fatalError("Unable to get IONotificationPort")
            
        }
        self.ioNotificationPort = notificationPort!
        
        IONotificationPortSetDispatchQueue(ioNotificationPort, ioUSBManagerQueue)
    
    }
    
    func start(delegate: IOUSBManagerDelegate) {

        self.delegate = delegate
        
        let usbDeviceAddedCallback:IOServiceMatchingCallback = {
            (instance, iterator) in
            let usbManager = Unmanaged<IOUSBManager>.fromOpaque(instance!).takeUnretainedValue()
            usbManager.ioUSBDeviceAdded(iterator: iterator)
        }
        
        let usbDeviceRemovedCallback: IOServiceMatchingCallback = {
            (instance, iterator) in
            let usbManager = Unmanaged<IOUSBManager>.fromOpaque(instance!).takeUnretainedValue()
            usbManager.ioUSBDeviceRemoved(iterator: iterator)
        }
        
        let instancePointer = Unmanaged.passUnretained(self).toOpaque()
        
        IOServiceAddMatchingNotification(
            ioNotificationPort,
            kIOMatchedNotification,
            matchingDict,
            usbDeviceAddedCallback,
            instancePointer,
            &addedIterator
        )
        self.ioUSBDeviceAdded(iterator: addedIterator)

        IOServiceAddMatchingNotification(
            ioNotificationPort,
            kIOTerminatedNotification,
            matchingDict,
            usbDeviceRemovedCallback,
            instancePointer,
            &removedIterator
        )
        self.ioUSBDeviceRemoved(iterator: removedIterator)
        
    }
    
    deinit {
        IOObjectRelease(addedIterator)
        IOObjectRelease(removedIterator)
        IONotificationPortDestroy(ioNotificationPort)
    }
    
    private func ioUSBDeviceAdded(iterator: io_iterator_t) {
        
        while case let device = IOIteratorNext(iterator), device != IO_OBJECT_NULL {
            
            let usbDevice: IOUSBDevice = IOUSBDevice(
                id:         device.ioRegistryID(),
                name:       device.ioRegistryName()     ?? "<unknown>",
                vid:        device.usbVendorID()        ?? 0x00,
                pid:        device.usbProductID()       ?? 0x00,
                serial:     device.usbSerialNumber()    ?? "<unknown>",
                vendor:     device.usbVendorName()      ?? "<unknown>",
                product:    device.usbProductName()     ?? "<unknown>"
            )
            
            ioUSBDeviceList.append(usbDevice)
            
            if let delegate = self.delegate {
                delegate.usbDeviceAdded(usbDevice)
            }

            IOObjectRelease(device)
        }
        
    }
    
    private func ioUSBDeviceRemoved(iterator: io_iterator_t) {
        
        while case let device = IOIteratorNext(iterator), device != IO_OBJECT_NULL {
        
            // although this will be a small array, there are better ways to
            // iterate and remove a device, but that can be done later
            for index in 0..<ioUSBDeviceList.count {
                if(ioUSBDeviceList[index].ioRegistryID == device.ioRegistryID()) {
                    let usbDevice = ioUSBDeviceList[index]
                    ioUSBDeviceList.remove(at: index)
                    if let delegate = self.delegate {
                        delegate.usbDeviceRemoved(usbDevice)
                    }
                    break;
                }
            }
            
            IOObjectRelease(device)
        }
    }
    
    class func manager() -> IOUSBManager {
        
        return sharedIOUSBManager
        
    }
    
}
