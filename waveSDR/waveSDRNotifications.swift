//
//  waveSDRNotifications.swift
//  waveSDR
//
//  Copyright © 2017 GetOffMyHack. All rights reserved.
//

import Foundation

//Notification.Name(rawValue: sdrDevicesFound)



let sdrDeviceListNotifcaiton:           String = "com.getoffmyhack.waveSDR.sdrDeviceListAvailable"
let sdrDeviceListKey:                   String = "com.getoffmyhack.waveSDR.sdrDeviceListKey"

let sdrStartedNotification:             String = "com.getoffmyhack.waveSDR.sdrStarted"
let sdrStoppedNotification:             String = "com.getoffmyhack.waveSDR.sdrStopped"

let sdrPauseRequestNotification:        String = "com.getoffmyhack.waveSDR.sdrPauseRequest"
let sdrLiveRequestNotification:         String = "com.getoffmyhack.waveSDR.sdrLiveRequest"


// control notifications from user input

let sdrDeviceSelectedNotification:      String = "com.getoffmyhack.waveSDR.sdrDeviceSelected"
let sdrDeviceSelectedKey:               String = "com.getoffmyhack.waveSDR.sdrDeviceSelectedKey"

let sdrDeviceInitalizedNotification:    String = "com.getoffmyhack.waveSDR.sdrDeviceInitalized"
let sdrDeviceInitalizedKey:             String = "com.getoffmyhack.waveSDR.sdrDeviceInitalizedKey"

let frequencyUpdatedNotification:       String = "com.getoffmyhack.waveSDR.frequencyUpdated"
let frequencyUpdatedKey:                String = "com.getoffmyhack.waveSDR.frequencyUpdatedKey"

let frequencyChangeRequestNotification: String = "com.getoffmyhack.waveSDR.frequencyChangeRequest"
let frequencyChangeRequestKey:          String = "com.getoffmyhack.waveSDR.frequencyChangeRequestKey"

let mixerChangeRequestNotification:     String = "com.getoffmyhack.waveSDR.mixerChangeRequest"
let mixerChangeRequestKey:              String = "com.getoffmyhack.waveSDR.mixerChangeRequestKey"

let converterUpdatedNotification:       String = "com.getoffmyhack.waveSDR.converterUpdated"
let converterUpdatedKey:                String = "com.getoffmyhack.waveSDR.converterUpdatedKey"

let frequencyStepUpdatedNotification:   String = "com.getoffmyhack.waveSDR.frequencyStepUpdated"
let frequencyStepUpdatedKey:            String = "com.getoffmyhack.waveSDR.frequencyStepUpdatedKey"

let sampleRateUpdatedNotification:      String = "com.getoffmyhack.waveSDR.sampleRateUpdated"
let sampleRateUpdatedKey:               String = "com.getoffmyhack.waveSDR.sampleRateUpdatedKey"

let correctionUpdatedNotification:      String = "com.getoffmyhack.waveSDR.correctionUpdated"
let correctionUpdatedKey:               String = "com.getoffmyhack.waveSDR.correctionUpdatedKey"

let tunerAutoGainUpdatedNotification:   String = "com.getoffmyhack.waveSDR.tunerAutoGainUpdated"
let tunerAutoGainUpdatedKey:            String = "com.getoffmyhack.waveSDR.tunerAutoGainUpdatedKey"

let tunerGainUpdatedNotification:       String = "com.getoffmyhack.waveSDR.tunerGainUpdated"
let tunerGainUpdatedKey:                String = "com.getoffmyhack.waveSDR.tunerGainUpdatedKey"

let squelchUpdatedNotification:         String = "com.getoffmyhack.waveSDR.squelchUpdated"
let squelchUpdatedKey:                  String = "com.getoffmyhack.waveSDR.squelchUpdatedKey"

let demodModeUpdatedNotification:       String = "com.getoffmyhack.waveSDR.demodModeUpdated"
let demodModeUpdatedKey:                String = "com.getoffmyhack.waveSDR.demodModeUpdatedKey"

// report notifications from the radio

let averageDBUpdatedNotification:       String = "com.getoffmyhack.waveSDR.averageDBUpdated"
let averageDBUpdatedKey:                String = "com.getoffmyhack.waveSDR.averageDBUpdatedKey"
let averageDBKey:                       String = "com.getoffmyhack.waveSDR.averageDBKey"

let squelchPercentUpdatedNotification:  String = "com.getoffmyhack.waveSDR.squelchPercentUpdated"
let squelchPercentUpdatedKey:           String = "com.getoffmyhack.waveSDR.squelchPercentUpdatedKey"
let squelchPercentKey:                  String = "com.getoffmyhack.waveSDR.squelchPercentKey"

let fftSamplesUpdatedNotification:      String = "com.getoffmyhack.waveSDR.fftSamplesUpdated"
let fftSamplesUpdatedKey:               String = "com.getoffmyhack.waveSDR.fftSamplesUpdatedKey"

let toneDecoderUpdatedNotification:     String = "com.getoffmyhack.waveSDR.toneDecoderUpdated"
let toneDecoderUpdatedKey:              String = "com.getoffmyhack.waveSDR.toneDecoderUpdatedKey"
let toneDecoderKey:                     String = "com.getoffmyhack.waveSDR.toneDecoderKey"

/*
 

let sdrSquelchLevelChanged:         String = "com.getoffmyhack.RTLScanner.squelchLevelChanged"
let sdrSquelchLevelKey:             String = "com.getoffmyhack.RTLScanner.squelchLevelKey"
 
 */
