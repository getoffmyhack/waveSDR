//
//  RTLKnownDeviceList.swift
//  waveSDR
//
//  Copyright © 2019 GetOffMyHack. All rights reserved.
//

class RTLKnownDevices  {
    
    struct USBDevice : Hashable {
        var vendorID:   Int
        var productID:  Int
        
        init(_ vid: Int, _ pid: Int) {
            self.vendorID   = vid
            self.productID  = pid
        }
    }
    
    private static let knownDevices:   Set = [
        USBDevice(0x0bda, 0x2832),//, "Generic RTL2832U"),
        USBDevice(0x0bda, 0x2838),//, "Generic RTL2832U OEM"),
        USBDevice(0x0413, 0x6680),//, "DigitalNow Quad DVB-T PCI-E card"),
        USBDevice(0x0413, 0x6f0f),//, "Leadtek WinFast DTV Dongle mini D"),
        USBDevice(0x0458, 0x707f),//, "Genius TVGo DVB-T03 USB dongle (Ver. B)"),
        USBDevice(0x0ccd, 0x00a9),//, "Terratec Cinergy T Stick Black (rev 1)"),
        USBDevice(0x0ccd, 0x00b3),//, "Terratec NOXON DAB/DAB+ USB dongle (rev 1)"),
        USBDevice(0x0ccd, 0x00b4),//, "Terratec Deutschlandradio DAB Stick"),
        USBDevice(0x0ccd, 0x00b5),//, "Terratec NOXON DAB Stick - Radio Energy"),
        USBDevice(0x0ccd, 0x00b7),//, "Terratec Media Broadcast DAB Stick"),
        USBDevice(0x0ccd, 0x00b8),//, "Terratec BR DAB Stick"),
        USBDevice(0x0ccd, 0x00b9),//, "Terratec WDR DAB Stick"),
        USBDevice(0x0ccd, 0x00c0),//, "Terratec MuellerVerlag DAB Stick"),
        USBDevice(0x0ccd, 0x00c6),//, "Terratec Fraunhofer DAB Stick"),
        USBDevice(0x0ccd, 0x00d3),//, "Terratec Cinergy T Stick RC (Rev.3)"),
        USBDevice(0x0ccd, 0x00d7),//, "Terratec T Stick PLUS"),
        USBDevice(0x0ccd, 0x00e0),//, "Terratec NOXON DAB/DAB+ USB dongle (rev 2)"),
        USBDevice(0x1554, 0x5020),//, "PixelView PV-DT235U(RN)"),
        USBDevice(0x15f4, 0x0131),//, "Astrometa DVB-T/DVB-T2"),
        USBDevice(0x15f4, 0x0133),//, "HanfTek DAB+FM+DVB-T"),
        USBDevice(0x185b, 0x0620),//, "Compro Videomate U620F"),
        USBDevice(0x185b, 0x0650),//, "Compro Videomate U650F"),
        USBDevice(0x185b, 0x0680),//, "Compro Videomate U680F"),
        USBDevice(0x1b80, 0xd393),//, "GIGABYTE GT-U7300"),
        USBDevice(0x1b80, 0xd394),//, "DIKOM USB-DVBT HD"),
        USBDevice(0x1b80, 0xd395),//, "Peak 102569AGPK"),
        USBDevice(0x1b80, 0xd397),//, "KWorld KW-UB450-T USB DVB-T Pico TV"),
        USBDevice(0x1b80, 0xd398),//, "Zaapa ZT-MINDVBZP"),
        USBDevice(0x1b80, 0xd39d),//, "SVEON STV20 DVB-T USB & FM"),
        USBDevice(0x1b80, 0xd3a4),//, "Twintech UT-40"),
        USBDevice(0x1b80, 0xd3a8),//, "ASUS U3100MINI_PLUS_V2"),
        USBDevice(0x1b80, 0xd3af),//, "SVEON STV27 DVB-T USB & FM"),
        USBDevice(0x1b80, 0xd3b0),//, "SVEON STV21 DVB-T USB & FM"),
        USBDevice(0x1d19, 0x1101),//, "Dexatek DK DVB-T Dongle (Logilink VG0002A)"),
        USBDevice(0x1d19, 0x1102),//, "Dexatek DK DVB-T Dongle (MSI DigiVox mini II V3.0)"),
        USBDevice(0x1d19, 0x1103),//, "Dexatek Technology Ltd. DK 5217 DVB-T Dongle"),
        USBDevice(0x1d19, 0x1104),//, "MSI DigiVox Micro HD"),
        USBDevice(0x1f4d, 0xa803),//, "Sweex DVB-T USB"),
        USBDevice(0x1f4d, 0xb803),//, "GTek T803"),
        USBDevice(0x1f4d, 0xc803),//, "Lifeview LV5TDeluxe"),
        USBDevice(0x1f4d, 0xd286),//, "MyGica TD312"),
        USBDevice(0x1f4d, 0xd803),//, "PROlectrix DV107669")
    ]
    
    public static func isKnownRTLDevice(vid: Int, pid: Int) -> Bool {
        
        return knownDevices.contains(USBDevice(vid, pid))
        
    }
    
    
}
