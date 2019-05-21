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

protocol USBManagerDelegate: class {
    func usbDeviceAdded(_   device: USBDevice)
    func usbDeviceRemoved(_ device: USBDevice)
}

//--------------------------------------------------------------------------
//
// MARK: - IOUSBManager class
//
//--------------------------------------------------------------------------

class USBManager {
    
    private let ioNotificationPort:   IONotificationPortRef
    
    private weak var delegate:      USBManagerDelegate?
    
    private var addedIterator:      io_iterator_t = 0
    private var removedIterator:    io_iterator_t = 0
    
    private let ioUSBManagerQueue:  DispatchQueue           = DispatchQueue(label: "com.getoffmyhack.waveSDR.IOUSBManagerQueue")
    private var matchingDict:       NSMutableDictionary     = IOServiceMatching(kIOUSBDeviceClassName)
    
    
    //--------------------------------------------------------------------------
    //
    // init() method to set up the notification port and dispatch queue
    //
    //--------------------------------------------------------------------------
    
    init() {
    
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
    
    func start(delegate: USBManagerDelegate) {

        // set the delegate object
        self.delegate = delegate
        
        // create callback closure for when a device is added
        let usbDeviceAddedCallback:IOServiceMatchingCallback = {
            (instance, iterator) in
                let usbManager = Unmanaged<USBManager>.fromOpaque(instance!).takeUnretainedValue()
                usbManager.ioUSBDeviceAdded(iterator: iterator)
        }
        
        // create callback closure for when a device is removed
        let usbDeviceRemovedCallback: IOServiceMatchingCallback = {
            (instance, iterator) in
                let usbManager = Unmanaged<USBManager>.fromOpaque(instance!).takeUnretainedValue()
                usbManager.ioUSBDeviceRemoved(iterator: iterator)
        }
        
        // create a pointer to this instace of USBManager
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
        
        //Iterate over set of matching devices to access already-present devices
        //and to arm the notification
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
        
        //Iterate over set of matching devices to release each one and to
        //arm the notification
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
    // called from the IOKit callback closure whenever a new USB device is added.
    // Each new device will create an USBDevice struct and pass to delegate
    //
    //--------------------------------------------------------------------------
    
    private func ioUSBDeviceAdded(iterator: io_iterator_t) {
        
        // iterate through the list of devices from IOKit
        while case let device = IOIteratorNext(iterator), device != IO_OBJECT_NULL {
            
            // create usbDevice for this device
            let usbDevice: USBDevice = USBDevice(
                ioRegistryID:       device.ioRegistryID(),
                ioRegistryName:     device.ioRegistryName()     ?? "<unknown>",
                usbVendorID:        device.usbVendorID()        ?? 0x00,
                usbProductID:       device.usbProductID()       ?? 0x00,
                usbSerialNumber:    device.usbSerialNumber()    ?? "<unknown>",
                usbVendorName:      device.usbVendorName()      ?? "<unknown>",
                usbProductName:     device.usbProductName()     ?? "<unknown>"
            )
            
//            for(key, value) in device.getProperties()! {
//                print("Key: \(key)\t\(value)")
//            }
            
            // call delegate with new device
            guard let delegate = self.delegate else {
                fatalError("No delegate for USBManager")
            }
            
            delegate.usbDeviceAdded(usbDevice)

            IOObjectRelease(device)
        }
        
    }
    
    //--------------------------------------------------------------------------
    //
    // ioUSBDeviceRemoved
    //
    // called from the IOKit whenever a USB device is removed, calls delegate
    //
    //--------------------------------------------------------------------------
    
    private func ioUSBDeviceRemoved(iterator: io_iterator_t) {
        
        // iterate through list of devices removed from IOKit
        while case let device = IOIteratorNext(iterator), device != IO_OBJECT_NULL {
        
            // create usbDevice for this device
            let usbDevice: USBDevice = USBDevice(
                ioRegistryID:       device.ioRegistryID(),
                ioRegistryName:     device.ioRegistryName()     ?? "<unknown>",
                usbVendorID:        device.usbVendorID()        ?? 0x00,
                usbProductID:       device.usbProductID()       ?? 0x00,
                usbSerialNumber:    device.usbSerialNumber()    ?? "<unknown>",
                usbVendorName:      device.usbVendorName()      ?? "<unknown>",
                usbProductName:     device.usbProductName()     ?? "<unknown>"
            )
            
            guard let delegate = self.delegate else {
                fatalError("No delegate for USBManager")
            }
            delegate.usbDeviceRemoved(usbDevice)
            
            IOObjectRelease(device)
   
        }
        
    }
    

    
}
