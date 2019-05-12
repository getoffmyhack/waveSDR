//
//  USBManager.swift
//  waveSDR
//
//  Copyright © 2019 GetOffMyHack. All rights reserved.
//

import Foundation
import IOKit
import IOKit.usb

public protocol IOUSBManagerDelegate {
    /// Called on the main thread when a device is connected.
    func deviceAdded(_ device: IOUSBDevice)
    
    /// Called on the main thread when a device is disconnected.
    func deviceRemoved(_ device: IOUSBDevice)
}

class IOUSBManager {
    
    private static var sharedIOUSBManager: IOUSBManager = {
        let usbManager = IOUSBManager()
        
        return usbManager
    }()

    private let ioNotificationPort:   IONotificationPortRef
    
    private var ioUSBDeviceDictionary:  Dictionary<io_registry_id_t, IOUSBDevice>   = [:]
    private var managedDeviceList:      [IOUSBDevice]           = []
    private var delegateList:           [IOUSBManagerDelegate]  = []
    
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
        
        let usdDeviceAddedCallback:IOServiceMatchingCallback = {
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
            usdDeviceAddedCallback,
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
    
    func ioUSBDeviceAdded(iterator: io_iterator_t) {
        
    }
    
    func ioUSBDeviceRemoved(iterator: io_iterator_t) {
        
    }
    
    class func shared() -> IOUSBManager {
        
        return sharedIOUSBManager
        
    }
    
}
