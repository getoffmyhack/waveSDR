//
//  USBManager.swift
//  waveSDR
//
//  Copyright © 2019 GetOffMyHack. All rights reserved.
//

import Foundation
import IOKit
import IOKit.usb

//--------------------------------------------------------------------------
//
// MARK: - IOUSBManagerDelegate
//
// This the protocol used by the delegate to recevie calls when a USB
// device has been added or removed.
//
//--------------------------------------------------------------------------

protocol IOUSBManagerDelegate: class {
    func usbDeviceAdded(_   device: IOUSBDevice)
    func usbDeviceRemoved(_ device: IOUSBDevice)
}

//--------------------------------------------------------------------------
//
// MARK: - IOUSBManager class
//
//--------------------------------------------------------------------------

class IOUSBManager {
    
    private static var sharedIOUSBManager: IOUSBManager = {
        let usbManager = IOUSBManager()
        return usbManager
    }()

    private let ioNotificationPort:   IONotificationPortRef
    
    private      var ioUSBDeviceList:    [IOUSBDevice] = []
    private weak var delegate:           IOUSBManagerDelegate?
    
    private var addedIterator:      io_iterator_t = 0
    private var removedIterator:    io_iterator_t = 0
    
    private let ioUSBManagerQueue:  DispatchQueue           = DispatchQueue(label: "com.getoffmyhack.waveSDR.IOUSBManagerQueue")
    private let matchingDict:       NSMutableDictionary     = IOServiceMatching(kIOUSBDeviceClassName)
    
    //--------------------------------------------------------------------------
    //
    // manager()
    //
    // this is used to get the shared instance to IOUSBManager
    //
    //--------------------------------------------------------------------------
    
    class func manager() -> IOUSBManager {
        
        return sharedIOUSBManager
        
    }
    
    //--------------------------------------------------------------------------
    //
    // init() method to set up the notification port and dispatch queue
    //
    //--------------------------------------------------------------------------
    
    private init() {
        
        // get the Master notificatin port for IO Kit
        let notificationPort = IONotificationPortCreate(kIOMasterPortDefault)
        guard notificationPort != nil else {
            fatalError("Unable to get IONotificationPort")
            
        }
        self.ioNotificationPort = notificationPort!
        
        // set up the dispatch queue for where the notifications will be sent
        IONotificationPortSetDispatchQueue(ioNotificationPort, ioUSBManagerQueue)
    
    }
    
    //--------------------------------------------------------------------------
    //
    // start()
    //
    // this method adds the matching notification.  The delegate is passed into
    // this fuction such that it is assured that the delegate has been set up
    // prior to any add/remove events being dispatched
    //
    //--------------------------------------------------------------------------
    
    func start(delegate: IOUSBManagerDelegate) {

        self.delegate = delegate
        
        // create callback closure for when a device is added
        let usbDeviceAddedCallback:IOServiceMatchingCallback = {
            (instance, iterator) in
                let usbManager = Unmanaged<IOUSBManager>.fromOpaque(instance!).takeUnretainedValue()
                usbManager.ioUSBDeviceAdded(iterator: iterator)
        }
        
        // create callback closure for when a device is removed
        let usbDeviceRemovedCallback: IOServiceMatchingCallback = {
            (instance, iterator) in
                let usbManager = Unmanaged<IOUSBManager>.fromOpaque(instance!).takeUnretainedValue()
                usbManager.ioUSBDeviceRemoved(iterator: iterator)
        }
        
        // create a point to this instace of IOUSBManager
        let instancePointer = Unmanaged.passUnretained(self).toOpaque()
        
        // add notification for when a device is added
        IOServiceAddMatchingNotification(
            ioNotificationPort,
            kIOMatchedNotification,
            matchingDict,
            usbDeviceAddedCallback,
            instancePointer,
            &addedIterator
        )
        
        // "arm" the call back notification
        self.ioUSBDeviceAdded(iterator: addedIterator)

        // add notification for when a device is removed
        IOServiceAddMatchingNotification(
            ioNotificationPort,
            kIOTerminatedNotification,
            matchingDict,
            usbDeviceRemovedCallback,
            instancePointer,
            &removedIterator
        )
        
        // "arm" the call back notification
        self.ioUSBDeviceRemoved(iterator: removedIterator)
        
    }
    
    //--------------------------------------------------------------------------
    //
    // deinit
    //
    // release all IOKit objects that have been created
    //
    //--------------------------------------------------------------------------
    
    deinit {
        IOObjectRelease(addedIterator)
        IOObjectRelease(removedIterator)
        IONotificationPortDestroy(ioNotificationPort)
    }
    
    //--------------------------------------------------------------------------
    //
    // ioUSBDeviceAdded
    //
    // called from the IOKit whenever a new USB device is added.  Each new
    // device will create an IOUSBDevice struct, adds to an internal array
    // and passes it to the delegate
    //
    //--------------------------------------------------------------------------
    
    private func ioUSBDeviceAdded(iterator: io_iterator_t) {
        
        // iterate through the list of devices from IOKit
        while case let device = IOIteratorNext(iterator), device != IO_OBJECT_NULL {
            
            // create usbDevice for this device
            let usbDevice: IOUSBDevice = IOUSBDevice(
                id:         device.ioRegistryID(),
                name:       device.ioRegistryName()     ?? "<unknown>",
                vid:        device.usbVendorID()        ?? 0x00,
                pid:        device.usbProductID()       ?? 0x00,
                serial:     device.usbSerialNumber()    ?? "<unknown>",
                vendor:     device.usbVendorName()      ?? "<unknown>",
                product:    device.usbProductName()     ?? "<unknown>"
            )
            
            // append to local list
            ioUSBDeviceList.append(usbDevice)
            
            // call delegate with new device
            if let delegate = self.delegate {
                delegate.usbDeviceAdded(usbDevice)
            }

            IOObjectRelease(device)
        }
        
    }
    
    //--------------------------------------------------------------------------
    //
    // ioUSBDeviceRemoved
    //
    // called from the IOKit whenever a USB device is removed, remove from
    // local array and call delegate
    //
    //--------------------------------------------------------------------------
    
    private func ioUSBDeviceRemoved(iterator: io_iterator_t) {
        
        // iterate through list of devices removed from IOKit
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
    

    
}
