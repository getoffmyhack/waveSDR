//
//  waveSDRNotifications.swift
//  waveSDR
//
//  Copyright © 2017 GetOffMyHack. All rights reserved.
//

import Foundation

// Strings as keys for notification's userinfo dictionary

let sdrDeviceListKey            = String("com.getoffmyhack.waveSDR.sdrDeviceListKey")
let sdrDeviceAddedKey           = String("com.getoffmyhack.wabeSDR.sdrDeviceAdded")
let sdrDeviceRemovedKey         = String("com.getoffmyhack.wabeSDR.sdrDeviceRemoved")
let sdrDeviceSelectedKey        = String("com.getoffmyhack.waveSDR.sdrDeviceSelectedKey")
let sdrDeviceInitalizedKey      = String("com.getoffmyhack.waveSDR.sdrDeviceInitalizedKey")
let frequencyUpdatedKey         = String("com.getoffmyhack.waveSDR.frequencyUpdatedKey")
let frequencyChangeRequestKey   = String("com.getoffmyhack.waveSDR.frequencyChangeRequestKey")
let mixerChangeRequestKey       = String("com.getoffmyhack.waveSDR.mixerChangeRequestKey")
let converterUpdatedKey         = String("com.getoffmyhack.waveSDR.converterUpdatedKey")
let frequencyStepUpdatedKey     = String("com.getoffmyhack.waveSDR.frequencyStepUpdatedKey")
let sampleRateUpdatedKey        = String("com.getoffmyhack.waveSDR.sampleRateUpdatedKey")
let correctionUpdatedKey        = String("com.getoffmyhack.waveSDR.correctionUpdatedKey")
let tunerAutoGainUpdatedKey     = String("com.getoffmyhack.waveSDR.tunerAutoGainUpdatedKey")
let tunerGainUpdatedKey         = String("com.getoffmyhack.waveSDR.tunerGainUpdatedKey")
let squelchUpdatedKey           = String("com.getoffmyhack.waveSDR.squelchUpdatedKey")
let demodModeUpdatedKey         = String("com.getoffmyhack.waveSDR.demodModeUpdatedKey")
let highPassCutoffUpdatedKey    = String("com.getoffmyhack.waveSDR.highPassCutoffUpdatedKey")
let highPassBypassUpdatedKey    = String("com.getoffmyhack.waveSDR.highPassBypassUpdatedKey")
let averageDBUpdatedKey         = String("com.getoffmyhack.waveSDR.averageDBUpdatedKey")
let averageDBKey                = String("com.getoffmyhack.waveSDR.averageDBKey")
let squelchPercentUpdatedKey    = String("com.getoffmyhack.waveSDR.squelchPercentUpdatedKey")
let squelchPercentKey           = String("com.getoffmyhack.waveSDR.squelchPercentKey")
let fftSamplesUpdatedKey        = String("com.getoffmyhack.waveSDR.fftSamplesUpdatedKey")
let toneDecoderUpdatedKey       = String("com.getoffmyhack.waveSDR.toneDecoderUpdatedKey")
let toneDecoderKey              = String("com.getoffmyhack.waveSDR.toneDecoderKey")

// create extension of Notification.Name in order to add custom notifications

extension Notification.Name {

    static let sdrDeviceNotifcaiton                 = Notification.Name("com.getoffmyhack.waveSDR.sdrDevice")
    static let sdrStartedNotification               = Notification.Name("com.getoffmyhack.waveSDR.sdrStarted")
    static let sdrStoppedNotification               = Notification.Name("com.getoffmyhack.waveSDR.sdrStopped")
    static let sdrPauseRequestNotification          = Notification.Name("com.getoffmyhack.waveSDR.sdrPauseRequest")
    static let sdrLiveRequestNotification           = Notification.Name("com.getoffmyhack.waveSDR.sdrLiveRequest")

// control notifications from user input

    static let sdrDeviceSelectedNotification        = Notification.Name("com.getoffmyhack.waveSDR.sdrDeviceSelected")
    static let sdrDeviceInitalizedNotification      = Notification.Name("com.getoffmyhack.waveSDR.sdrDeviceInitalized")
    static let frequencyUpdatedNotification         = Notification.Name("com.getoffmyhack.waveSDR.frequencyUpdated")
    static let frequencyChangeRequestNotification   = Notification.Name("com.getoffmyhack.waveSDR.frequencyChangeRequest")
    static let mixerChangeRequestNotification       = Notification.Name("com.getoffmyhack.waveSDR.mixerChangeRequest")
    static let converterUpdatedNotification         = Notification.Name("com.getoffmyhack.waveSDR.converterUpdated")
    static let frequencyStepUpdatedNotification     = Notification.Name("com.getoffmyhack.waveSDR.frequencyStepUpdated")
    static let sampleRateUpdatedNotification        = Notification.Name("com.getoffmyhack.waveSDR.sampleRateUpdated")
    static let correctionUpdatedNotification        = Notification.Name("com.getoffmyhack.waveSDR.correctionUpdated")
    static let tunerAutoGainUpdatedNotification     = Notification.Name("com.getoffmyhack.waveSDR.tunerAutoGainUpdated")
    static let tunerGainUpdatedNotification         = Notification.Name("com.getoffmyhack.waveSDR.tunerGainUpdated")
    static let squelchUpdatedNotification           = Notification.Name("com.getoffmyhack.waveSDR.squelchUpdated")
    static let demodModeUpdatedNotification         = Notification.Name("com.getoffmyhack.waveSDR.demodModeUpdated")
    static let highPassCutoffUpdatedNotification    = Notification.Name("com.getoffmyhack.waveSDR.highPassCutoffUpdated")
    static let highPassBypassUpdatedNotification    = Notification.Name("com.getoffmyhack.waveSDR.highPassBypassUpdated")

// report notifications from the radio

    static let averageDBUpdatedNotification         = Notification.Name("com.getoffmyhack.waveSDR.averageDBUpdated")
    static let squelchPercentUpdatedNotification    = Notification.Name("com.getoffmyhack.waveSDR.squelchPercentUpdated")
    static let fftSamplesUpdatedNotification        = Notification.Name("com.getoffmyhack.waveSDR.fftSamplesUpdated")
    static let toneDecoderUpdatedNotification       = Notification.Name("com.getoffmyhack.waveSDR.toneDecoderUpdated")

}
