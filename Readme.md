# waveSDR

A macOS native desktop Software Defined Radio application using the RTL-SDR USB device.

<> Mar 2020<>

Back from a bit of a hiatus in development on waveSDR, but before I start adding features to waveSDR, I plan on finishing my port of librtlsdr to a native macOS Swift framework.  Follow the progress here: [RTLSDR.Swift](https://github.com/getoffmyhack/RTLSDR.Swift) 

<> May 2019 <>
 
I have started a simple build log which can be found in the project's root directory, more as notes to myself, but also as a means of thinking through my design choices and documenting them for future reference.  Eventually my build log will become posts on my wordpress site. 

At some future date I am going to migrate my domain name and all my web presence to a wordpress site.  I have no idea as to when I will finish as dealing with my web presence never seems to be a high priority.  In the mean time, if you wish to contact me about waveSDR, please feel free to [drop me a comment here.](https://getoffmyhack.wordpress.com/contact/) (Sorry for the wordpress template, I  prefer to write waveSDR code then build a wordpress site.)

If you are interested in my first prototype / proof-of-concept design, check out my [first Youtube video.](https://youtu.be/aE4_K-NDLcQ)  I also plan on putting together simple videos demonstrating the new features as I add them to waveSDR.

<><>

**NB**:  This is purely experimental software.  I am using this application as a platform for teaching myself macOS desktop application programming as well as DSP techniques.  As it is, there are numerous sections of code where improvement is needed.

![Screenshot](screenshot.png)

Features:

* RTL-SDR hardware
* Dynamic Device Detection
* Spectrum Analyzer
* Spectrogram
* AM Demodulator
* FM Narrow Demodulator
* FM Wide Demodulator (mono only)
* Mixer Tuning
* Swipe to tune
