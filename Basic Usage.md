---
layout: page
title: Basic Usage
---
>*This documentation, like the application itself, is in a very early stage.  Things will be constantly changing and I will attempt to keep updated and grow the documentation as I continue developing waveSDR.  Also, this documentation should be considered incomplete*

* [Overview](#overview)
* [Main Screen](#main-screen)
    * [Sidebar](#sidebar)
        * [Hardware](#hardware)
        * [Tuner](#tuner)
    * [Main Display](#main-display)

# Overview

waveSDR started as means for me to learn several new programming topics including macOS desktop application programming, Apple's Swift language and DSP techniques. Therefore, most all UI design decisions are based off of what I feel were best suited for my usage and abilities as I learn the Cocoa frameworks.  This may or may not be the best or most user friendly way of doing things, and as I continue to develop waveSDR, controls and displays may drastically change from one minor revision to another as I keep experimenting with new features.  With that said, I will most likely continue with the current UI scheme, where, as described below, there will be a sidebar which will contain most of the "radio time" controls, a main section which contains the "radio display", the "spectrum display", and as I continue to add features, will include other displays such as a channel / memory list, and other features that I will add.

# Main Screen

waveSDR has several distinct UI sections which are either display areas or control areas, and in some cases, both display and control areas :).  The most obvious sections are the sidebar and the main display.  The sidebar has multiple sets of controls, selected via a drop down menu.  The main display currently contains the "radio" view and the "spectrum" view.  The radio view contains the display of the radio indications such as frequency, squelch level, current signal strength, etc. and also contains the most used controls for the overall radio.  The spectrum display contains the analyzer and the spectrogram views.

[![image][ss-600w-img]][ss-1440w-link]

## Sidebar

The sidebar is where most of the controls are located, currently, there are only the most basic controls needed for operation.  The sidebar controls are grouped by their functions and include Hardware controls and Tuner controls.  More controls will be added in future versions such as DSP, Scanner and Audio controls, to name a few.

### Hardware 

The Hardware controls are used to select the SDR hardware device and aspects of the device itself.  Currently, waveSDR only supports the RTLSDR device, but I fully intend to add more devices are the applications matures.

Upon selecting the SDR device, the configuration options allow changing the sample rate and the frequency correction.  Right now, the sample rates of 960000 and 2400000 samples per second are the only options available.  This is due to limitations in my current DSP implementation, and will change in a future version.  The frequency correction is passed to the RTLSDR driver and is used to "fine tune" the device.

### Tuner

The Tuner controls are used to tune the radio to specific frequencies using the selected demod mode.  Also included are controls for changing the step size and buttons for stepping through frequencies either up or down.

The **Frequency** input is used to change the center frequency of the SDR device.  Input can be in one of two formats, the first being the raw frequency in Hertz, input without any additional characters.  The frequency can also be entered by using the '.' character as the thousand separater.  For example, if you want to tune to 146.940 MHz, it could be entered as 146940000, or 146.940.000.

The **Step** control is used to adjust the change in frequency while using the **Tune** controls.  The **Step** size also controls the the frequency line while the mouse is within the spectrum analyzer.















[ss-600w-img]:  /assets/images/overview-ss-600w.png
[ss-1440w-link]: /assets/images/overview-ss-1440w.png