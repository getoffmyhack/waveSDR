//
//  SpectrumViewController.swift
//  waveSDR
//
//  Copyright © 2017 GetOffMyHack. All rights reserved.
//

import Cocoa
import Accelerate



class SpectrumViewController: NSViewController, AnalyzerViewDelegate, SpectrogramViewDelegate {
    
    let colorsPerPixel = 4
    
    var imageBuildCounter: UInt8 = 0
    
    // create serial queue for atomic access to the analyzer image
    var analyzerQueue:      DispatchQueue = DispatchQueue(label: "AnalyzerQueue")
    var spectrogramQueue:   DispatchQueue = DispatchQueue(label: "SpectrogramQueue")
    var workQueue:          DispatchQueue = DispatchQueue(label: "SpectrumViewController.WorkQueue")//, attributes: DispatchQueue.Attributes.concurrent)

    var refreshTimer: Timer = Timer()
    
    private var sampleRate:     Int         = 1
    private var frequency:      Int         = 1
    private var deltaFrequency: Int         = 0

    private var frequencyStep:  Double      = 1.0
    private var _isRunning:     Bool        = false
    
    var inSamples:              [Float]     = [] {
        didSet {
            updateDisplaySamples()
            workQueue.async {
                self.buildAnalyzerPath()
            }
            workQueue.async {
                if(self.imageBuildCounter % 8 == 0) {
                    self.buildSpectrogramImage()
                }
                self.imageBuildCounter = self.imageBuildCounter &+ 1
            }
        }
    }
    var inSamplesHistory:       [[Float]]   = []
    var displaySamples:         [Float]     = []
    
    var pixelLineArray:         [UInt8]     = []
    var pixelLine:              [UInt8]     = []
    var pixelArray:             [UInt8]     = []
    var updatePixelArray:       Bool        = false
    
    let spectrumStackView:      NSStackView     = {
        let view = NSStackView()
        view.wantsLayer     = true
        view.orientation    = .vertical
        view.spacing        = 0.0
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let analyzerView:           AnalyzerView    = {
        let view = AnalyzerView()
        return view
    }()
    
    let spectrogramView:        SpectrogramView = {
        let view = SpectrogramView()
        return view
    }()
    
    var lastSpectrogramImageSize:   NSSize = NSSize(width: 0, height: 0)
    
    var analyzerTrackingArea:       NSTrackingArea = NSTrackingArea()

    private var _analyzerPath:      NSBezierPath = NSBezierPath()
    var analyzerPath:               NSBezierPath {
        get {
            var path: NSBezierPath!
            analyzerQueue.sync {
                path =  self._analyzerPath
            }
            return path
        }
        
        set {
            analyzerQueue.async {
                self._analyzerPath = newValue
            }
        }
        
    }
    
    private var _spectrogramImage:  CGImage = {
        // start with essentialy a blank image
        
        let pixel:  [UInt8] = [0, 0, 0, 0]
        let data:   NSData  = NSData(bytes: pixel, length: pixel.count)
        
        let dataProvider    = CGDataProvider(data: data as CFData)
        let colorSpace      = CGColorSpaceCreateDeviceRGB()
        
        let bitmapInfo      = CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue)
        
        let image = CGImage(
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo,
            provider: dataProvider!,
            decode: nil,
            shouldInterpolate: true,
            intent: CGColorRenderingIntent.defaultIntent
            )!
        
        return image
    }()
    
    var spectrogramImage:           CGImage {
        get {
            var image: CGImage!
            spectrogramQueue.sync {
                image =  self._spectrogramImage
            }
            return image
        }
        
        set {
            spectrogramQueue.async {
                self._spectrogramImage = newValue
            }
        }
        
    }
    
    //--------------------------------------------------------------------------
    //
    // MARK: - init / deinit
    //
    //--------------------------------------------------------------------------
    
    override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        // setup notification observers
        initObservers()
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    //--------------------------------------------------------------------------
    //
    // MARK: - override methods
    //
    //--------------------------------------------------------------------------
    
    //--------------------------------------------------------------------------
    //
    // loadView()
    // override loadView() to build view hierarchy and set up both
    // the display view and control view
    //
    //--------------------------------------------------------------------------
    
    override func loadView() {
        
        // create a generic container view
        self.view = NSView()
        
        setupStackView()
        
        analyzerView.delegate = self
        spectrogramView.delegate = self
        self.view.addSubview(spectrumStackView)
    
    }
    
    //--------------------------------------------------------------------------
    //
    // viewDidLoad()
    //
    //--------------------------------------------------------------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // build constraints
        setupConstraints()

    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------
    
    func initObservers() {
        
        NotificationCenter.default.addObserver(
            self,
            selector:   #selector(observedAnalyzerViewFrameDidChage),
            name:       NSView.frameDidChangeNotification,
            object:     self.analyzerView
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector:   #selector(observedSpectrogramViewFrameDidChage),
            name:       NSView.frameDidChangeNotification,
            object:     self.spectrogramView
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector:   #selector(observedSampleRateUpdatedNotification(_:)),
            name:       .sampleRateUpdatedNotification,
            object:     nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector:   #selector(observedFrequencyUpdatedNotification(_:)),
            name:       .frequencyUpdatedNotification,
            object:     nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector:   #selector(observedFrequencyStepUpdatedNotification(_:)),
            name:       .frequencyStepUpdatedNotification,
            object:     nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector:   #selector(observedSDRStartedNotification(_:)),
            name:       .sdrStartedNotification,
            object:     nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector:   #selector(observedSDRStoppedNotification(_:)),
            name:       .sdrStoppedNotification,
            object:     nil
        )
    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------
    
    func getDisplayPoints()->[Float] {
        return displaySamples
    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------
    
    func getAnalyzerPath() -> NSBezierPath {
    
        return self.analyzerPath
    
    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------
    
    func getSpectrogramImage() -> CGImage {
        
        return self.spectrogramImage

    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------
    
    func isRunning()->Bool {
        
        return self._isRunning
    
    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------
    
    func buildAnalyzerPath() {
        
        let path:       NSBezierPath    = NSBezierPath()
        var i = 0
        
        if(displaySamples.count > 0) {
            path.move(to: NSPoint(x: i, y: Int(self.analyzerView.bounds.height)))
            for sample in displaySamples {
                path.line(to: NSPoint(x:i, y:Int(abs(sample))))
                i += 1
            }
//            path.line(to:NSPoint(x: (i - 1), y: Int(self.analyzerView.bounds.height)))
    
            let xScale: CGFloat = self.analyzerView.bounds.width  / CGFloat(displaySamples.count)
            let yScale: CGFloat = self.analyzerView.bounds.height / 128.0 //CGFloat(pathSamples.max()!)//128.0
            let scaleTransform  = AffineTransform(scaleByX: xScale, byY: yScale)
        
            path.transform(using: scaleTransform)
                    
            self.analyzerPath = path
        }
    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------

    func buildSpectrogramImage() {
        
        self.inSamplesHistory.insert(self.inSamples, at: 0)
        if self.inSamplesHistory.count > Int(self.spectrogramView.bounds.height) {
            _ = self.inSamplesHistory.popLast()
        }

        var imageLine: [UInt8] = []
        
        let imageWidth = displaySamples.count

        for i in 0..<imageWidth {
            
            let pixelMagnitude = 1 - (displaySamples[i]) / (128.0)
            let red:    Float = 0.0
            let green:  Float = 1.0
            let blue:   Float = 1.0
            var alpha:  Float = 1.0 * pixelMagnitude
            
            alpha = alpha * 2
            if(alpha > 1) {
                alpha = 1
            }
            
            imageLine.append(UInt8(255 * red))
            imageLine.append(UInt8(255 * green))
            imageLine.append(UInt8(255 * blue))
            imageLine.append(UInt8(255 * alpha))
        }
        
        
        pixelArray.insert(contentsOf: imageLine, at: 0)
        let imageHeight = pixelArray.count / imageLine.count
        if imageHeight > Int(self.spectrogramView.bounds.height) {
            let heightDifference =  imageHeight - Int(self.spectrogramView.bounds.height)
            let scrollLineStartIndex    = pixelArray.count - (heightDifference * imageLine.count)
            let scrollLineEndIndex      = pixelArray.count
            pixelArray.removeSubrange(scrollLineStartIndex..<scrollLineEndIndex)
        }
        
        
        let pixels: NSData = NSData(bytes: &pixelArray, length: pixelArray.count)
        
        let dataProvider    = CGDataProvider(data: pixels as CFData)
        let colorSpace      = CGColorSpaceCreateDeviceRGB()
        
        let bitmapInfo      = CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue)
        
        self.spectrogramImage = CGImage(
            width: imageWidth,
            height: pixelArray.count / imageLine.count,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: imageLine.count,
            space: colorSpace,
            bitmapInfo: bitmapInfo,
            provider: dataProvider!,
            decode: nil,
            shouldInterpolate: true,
            intent: CGColorRenderingIntent.defaultIntent
        )!
        
    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------
    
    func updateDisplaySamples() {

        let bins = inSamples.count
        let scaleWidthLog2  = Float(floor(log2(self.view.bounds.width)))
        let scaleWidth      = Int(powf(2, scaleWidthLog2 + 1))
        let binsPerLine     = (Float(bins) / Float(scaleWidth))
        
        var samples: [Float] = [Float](repeating: 0.0, count: scaleWidth)
        
        for i in 0..<Int(scaleWidth) {
            
            var avgSum: Float = 0;
            for j in 0..<Int(binsPerLine) {
                let index = ( i * Int(binsPerLine) ) + j
                avgSum = avgSum + abs(inSamples[index])
            }
            samples[i] = avgSum / Float(binsPerLine)

        }
        
        self.displaySamples = samples
        
    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------
    
    func requestMixerChangeFrom(point: NSPoint, inView: NSView) {
        
        let requestedFrequency = getFrequencyFromPoint(point, inView: inView)
        self.deltaFrequency = requestedFrequency - self.frequency
        
        let userInfo: [String : Any] = [mixerChangeRequestKey: self.deltaFrequency]
        
        NotificationCenter.default.post(
            name: .mixerChangeRequestNotification,
            object: self,
            userInfo: userInfo
        )
        
    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------
    
    func requestFrequencyChangeFrom(point: NSPoint, inView: NSView) {
        
        let requestedFrequency = getFrequencyFromPoint(point, inView: inView)
        let userInfo: [String : Any] = [frequencyChangeRequestKey: requestedFrequency]
        
        NotificationCenter.default.post(
            name: .frequencyChangeRequestNotification,
            object: self,
            userInfo: userInfo
        )
        
        // reset the mixer as well
        self.deltaFrequency = 0
        let mixerInfo: [String : Any] = [mixerChangeRequestKey: self.deltaFrequency]
        
        NotificationCenter.default.post(
            name: .mixerChangeRequestNotification,
            object: self,
            userInfo: mixerInfo
        )

    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------
    
    func requestFrequencyChangeWithScrollSpeed(_ speed: Int) {
        
        let newFrequency = self.frequency + (Int(self.frequencyStep) * speed)
        let userInfo: [String : Any] = [frequencyChangeRequestKey: newFrequency]
        
        NotificationCenter.default.post(
            name: .frequencyChangeRequestNotification,
            object: self,
            userInfo: userInfo
        )
    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------
    
    func getTunedLocation(inView view: NSView) -> Float {
        
        let viewWidth   = view.bounds.width
        
        // get # Hz per each X position from 0 to view.width
        let hzPerX      = Float(self.sampleRate) / Float(viewWidth)
        
        // get the frequency at center of view (self.frequency)
        let centerX     = Float(viewWidth / 2)
        
        // find the mixed line location
        let line = centerX + (Float(self.deltaFrequency) / hzPerX)
    
        return line
    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------

    func getFrequencyAndSnapLineFor(point: NSPoint, inView: NSView) -> (frequency: Int, snapLine: Float) {
    
        let viewWidth           = inView.bounds.width
        
        // get # Hz per each X position from 0 to view.width
        let hzPerX              = Float(self.sampleRate) / Float(viewWidth)

        // get the frequency at X = 0
        let zeroXFrequency      = self.frequency - (self.sampleRate / 2)

        let channelFrequency = getFrequencyFromPoint(point, inView: view)
        
        // compute mouse line location to snap to frequency step
        let frequencyDifference = channelFrequency - zeroXFrequency
        let snapLine = Float(frequencyDifference) / hzPerX
        
        return (channelFrequency, snapLine)
    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------
    
    func getPowerFor(point: NSPoint, inView: NSView) -> Float {
        
        var powerValue: Float = 0.0

        let sampleCount         = (self.displaySamples.count - 1)
        
        // check if power values exists
        if(sampleCount > 0) {

            // drop into work queue to serialize access to displaySamples
            // sync mode so it will block until complete and the value
            // can be returned
        
            workQueue.sync {
            
                let viewWidth           = self.analyzerView.bounds.width
                let position            = point.x
        
                let relativeLocation    = position / viewWidth
        
                let relativeIndex       = relativeLocation * CGFloat(sampleCount)
        
                // TODO: interpolation
                // interpolate results from floor(relativeIndex) to ceil(relativeIndex)
                // of display samples array
        
        
                //
                let index = Int(relativeIndex)
                powerValue = self.displaySamples[index]
    
            }
        }
        return powerValue
    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------
    
    func getFrequencyFromPoint(_ point: NSPoint, inView: NSView) -> Int {
        let viewWidth           = inView.bounds.width
        
        // get # Hz per each X position from 0 to view.width
        let hzPerX              = Float(self.sampleRate) / Float(viewWidth)
        
        // get the frequency at X = 0
        let zeroXFrequency      = self.frequency - (self.sampleRate / 2)
        
        // get frequency under mouse pointer
        let mouseOverFrequency  = zeroXFrequency + (Int(point.x) * Int(hzPerX))
        
        // separate the freq into MHz and kHz components
        let frequencyMHz        = mouseOverFrequency / 1000000
        let frequencykHz        = mouseOverFrequency - (frequencyMHz * 1000000)
        
        // determine how many "channel" steps in freq kHz component
        let steps               = frequencykHz / Int(self.frequencyStep)
        
        // the number of steps below freq kHz component = lower channel
        let steps_kHzLow        = Int(self.frequencyStep) * steps
        
        // the number of steps to next higher channel then freq kHz component - upper channel
        let steps_kHzHigh       = steps_kHzLow + Int(self.frequencyStep)
        
        // take difference from freq kHz component to lower channel and upper channel
        let stepsLowDifference  = frequencykHz - steps_kHzLow
        let stepsHighDifference = steps_kHzHigh - frequencykHz
        
        // determine if lower channel or upper channel is closer to freq kHz component
        var steps_kHz           = 0
        if(stepsLowDifference < stepsHighDifference) {
            steps_kHz = steps_kHzLow
        } else {
            steps_kHz = steps_kHzHigh
        }
        
        // add freq MHz component with channel (steps) kHz component
        let channelFrequency = (frequencyMHz * 1000000) + steps_kHz
        
        // return channel
        return channelFrequency

    }
    
    //--------------------------------------------------------------------------
    //
    // MARK: - notification observers
    //
    // <observed> methods are selectors for notificaions from NotifiationCenter
    //
    //--------------------------------------------------------------------------
    
    //--------------------------------------------------------------------------
    //
    // observedFrequencyUpdatedNotification()
    //
    // the selected frequency has been changed
    //
    //--------------------------------------------------------------------------
    
    @objc func observedFrequencyUpdatedNotification(_ notification: Notification) {
        
        if let userInfo = notification.userInfo {
            let updatedFrequency = userInfo[frequencyUpdatedKey] as! Int
            self.frequency = updatedFrequency
        }
        
    }
    
    //--------------------------------------------------------------------------
    //
    // observedFrequencyStepUpdatedNotification()
    //
    // the selected step size has changed
    //
    //--------------------------------------------------------------------------
    
    @objc func observedFrequencyStepUpdatedNotification(_ notification: Notification) {
        
        if let userInfo = notification.userInfo {
            let updatedFrequencyStep = userInfo[frequencyStepUpdatedKey] as! Double
            self.frequencyStep = updatedFrequencyStep
        }
        
    }
    
    //--------------------------------------------------------------------------
    //
    // observedSampleRateSelectedNotification()
    //
    // the selected sample rate has been changed
    //
    //--------------------------------------------------------------------------
    
    @objc func observedSampleRateUpdatedNotification(_ notification: Notification) {
        
        if let userInfo = notification.userInfo {
            let sampleRate  = userInfo[sampleRateUpdatedKey] as! Int
            self.sampleRate = sampleRate
        }
        
    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------
    
    @objc func observedSDRStartedNotification(_ notification: Notification) {
        
        self.refreshTimer = Timer.init(
            timeInterval:   1.0/60.0,
            target:         self,
            selector:       #selector(self.refreshViews),
            userInfo:       nil,
            repeats:        true
        )
        
        RunLoop.main.add(self.refreshTimer, forMode: RunLoop.Mode.common)
        self._isRunning = true
        
    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------
    
    @objc func observedSDRStoppedNotification(_ notification: Notification) {
        self.refreshTimer.invalidate()
        self._isRunning = false
    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------
    
    @objc func observedAnalyzerViewFrameDidChage() {
        
        // setup tracking area
        self.analyzerView.removeTrackingArea(analyzerTrackingArea)
        
        let trackingAreaOptions: NSTrackingArea.Options = [
            NSTrackingArea.Options.mouseMoved,
            NSTrackingArea.Options.mouseEnteredAndExited,
            NSTrackingArea.Options.activeInActiveApp,
            NSTrackingArea.Options.cursorUpdate
        ]
        
        analyzerTrackingArea = NSTrackingArea(rect: self.analyzerView.bounds, options: trackingAreaOptions, owner: self.analyzerView, userInfo: nil)
        self.analyzerView.addTrackingArea(analyzerTrackingArea)

    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------

    @objc func observedSpectrogramViewFrameDidChage() {
        
        // get dimensions of spectrogramView
        let viewHeight = self.spectrogramView.bounds.height
        let viewWidth  = self.spectrogramView.bounds.width
        
        // drop onto work queue to serialize access to instance vars
        workQueue.async {
            
            
            
            // the number of pixels per line of the image will be equal to or
            // the next higer power of 2 value larger than the width of the view
            let imageWidthLog2  = Float(floor(log2(viewWidth)))
            let imageWidth      = Int(powf(2, imageWidthLog2 + 1))
            
            var newImageHeight: Int = 0
            
            // create an array to hold bitmap byte data
            var newImageBytes: [UInt8] = []
            
            // check if view width has changed enough to change the imageWidth
            // (the imageWidth will always be power of 2 to be evenly divisibly
            // into the fft samples, which will always be a power of 2)
            if imageWidth != Int(self.lastSpectrogramImageSize.width) {
                
                // reset the lastSpectrogramImageSize width
                self.lastSpectrogramImageSize.width = CGFloat(imageWidth)
                
                // loop through each set of samples from the sample history
                for samples in self.inSamplesHistory {
                    
                    let bins = samples.count
                    let binsPerLine     = (Float(bins) / Float(imageWidth))
                    
                    for i in 0..<Int(imageWidth) {
                        
                        var avgSum: Float = 0;
                        for j in 0..<Int(binsPerLine) {
                            let index = ( i * Int(binsPerLine) ) + j
                            avgSum = avgSum + abs(samples[index])
                        }
                        let sample = avgSum / Float(binsPerLine)
                        
                        let pixelMagnitude = 1 - (sample) / (128.0)
                        let red:    Float = 0.0
                        let green:  Float = 1.0
                        let blue:   Float = 1.0
                        var alpha:  Float = 1.0 * pixelMagnitude
                        
                        alpha = alpha * 2
                        if(alpha > 1) {
                            alpha = 1
                        }
                        
                        newImageBytes.append(UInt8(255.0 * red)     )
                        newImageBytes.append(UInt8(255.0 * green)   )
                        newImageBytes.append(UInt8(255.0 * blue)    )
                        newImageBytes.append(UInt8(255.0 * alpha)   )
                        
                    }
                    newImageHeight += 1
                }
                
                
                // all of the horizontal image lines have been created, check if
                // the height needs to be adjusted for the new view size
                if newImageHeight != Int(viewHeight) {
                    
                    // if height is shrinking, remove lines from the end of the array
                    if(Int(viewHeight) < newImageHeight) {
                        let removeLines = newImageHeight - Int(viewHeight)
                        let removeBytes = removeLines * self.colorsPerPixel
                        
                        let startRemoveIndex = newImageBytes.count - removeBytes
                        newImageBytes.removeSubrange(startRemoveIndex..<newImageBytes.count)
                    } else {
                        // view height is growing, add blank lines to end of image
                        let addLines = Int(viewHeight) - newImageHeight
                        let addBytes = addLines * imageWidth * self.colorsPerPixel
                        for _ in 0..<(addBytes / self.colorsPerPixel) {
                            newImageBytes.append(0) // red
                            newImageBytes.append(0) // green
                            newImageBytes.append(0) // blue
                            newImageBytes.append(255) // alpha
                        }
                    }
                    // update last image size
                    self.lastSpectrogramImageSize.height    = viewHeight
                }
                
                // update pixel array
                self.pixelArray = newImageBytes
                
                // update image
                let pixels: NSData = NSData(bytes: &newImageBytes, length: newImageBytes.count)
                
                let dataProvider    = CGDataProvider(data: pixels as CFData)
                let colorSpace      = CGColorSpaceCreateDeviceRGB()
                
                let bitmapInfo      = CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue)
                
                self.spectrogramImage = CGImage(
                    width: imageWidth,
                    height: Int(viewHeight),
                    bitsPerComponent: 8,
                    bitsPerPixel: 32,
                    bytesPerRow: imageWidth * self.colorsPerPixel,
                    space: colorSpace,
                    bitmapInfo: bitmapInfo,
                    provider: dataProvider!,
                    decode: nil,
                    shouldInterpolate: true,
                    intent: CGColorRenderingIntent.defaultIntent
                    )!

            }
            
            // check if the height has changed (independant from the last conditional)
            if self.lastSpectrogramImageSize.height != viewHeight {
                
                if(viewHeight < self.lastSpectrogramImageSize.height) {
                    
                    // if height is shrinking, remove lines from the end
                    let removeLines = self.lastSpectrogramImageSize.height - viewHeight
                    
                    // remove lines from end of pixel array
                    let removeBytes = Int(removeLines) * imageWidth * self.colorsPerPixel
                    let startRemoveIndex = self.pixelArray.count - removeBytes
                    self.pixelArray.removeSubrange(startRemoveIndex..<self.pixelArray.count)
                    
                    // remove blocks of samples from end of samples array
                    let removeBlocks = Int(removeLines)
                    let startRemoveBlockIndex = self.inSamplesHistory.count - removeBlocks
                    if startRemoveBlockIndex >= 0 {
                        self.inSamplesHistory.removeSubrange(startRemoveBlockIndex..<self.inSamplesHistory.count)
                    }
                    
                } else {
                    
                    // if height is growing, just add blank lines to end of pixel array
                    let addLines = Int(viewHeight - self.lastSpectrogramImageSize.height)
                    let addBytes = addLines * Int(viewWidth) * self.colorsPerPixel
                    self.pixelArray.append(contentsOf: [UInt8](repeating: 0, count: addBytes))
                    
                }
                
                self.lastSpectrogramImageSize.height    = viewHeight
                
            }

        }
        
    }
    
    //--------------------------------------------------------------------------
    //
    // setupStackViews()
    //
    // create the stack views that contain all the controls for the view
    //
    //--------------------------------------------------------------------------
    
    func setupStackView() {
        
        //----------------------------------------------------------------------
        //
        // build internal container views
        //
        //----------------------------------------------------------------------
        
        spectrumStackView.addView(analyzerView,     in: .top)
        spectrumStackView.addView(spectrogramView,  in: .top)

    }
    
    //--------------------------------------------------------------------------
    //
    // setupConstraints()
    //
    // create all the constraints needed to place and align all subviews
    //
    //--------------------------------------------------------------------------
    
    func setupConstraints() {
        
        //----------------------------------------------------------------------
        //
        // constrain the main stack view
        //
        //----------------------------------------------------------------------
        NSLayoutConstraint.activate([
            spectrumStackView.topAnchor.constraint(             equalTo: self.view.topAnchor        ),
            spectrumStackView.leadingAnchor.constraint(         equalTo: self.view.leadingAnchor    ),
            spectrumStackView.trailingAnchor.constraint(        equalTo: self.view.trailingAnchor   ),
            spectrumStackView.bottomAnchor.constraint(          equalTo: self.view.bottomAnchor     ),
        ])
        
        //----------------------------------------------------------------------
        //
        // constrain custom views within the main stack view
        //
        //----------------------------------------------------------------------
        
        NSLayoutConstraint.activate([
            analyzerView.leadingAnchor.constraint(              equalTo: spectrumStackView.leadingAnchor    ),
            analyzerView.trailingAnchor.constraint(             equalTo: spectrumStackView.trailingAnchor   ),
            analyzerView.heightAnchor.constraint(               greaterThanOrEqualToConstant: 128.0         ),
        
            spectrogramView.leadingAnchor.constraint(           equalTo: spectrumStackView.leadingAnchor    ),
            spectrogramView.trailingAnchor.constraint(          equalTo: spectrumStackView.trailingAnchor   ),
            spectrogramView.heightAnchor.constraint(            equalTo: analyzerView.heightAnchor          ),
        ])
        
    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------

    @objc func refreshViews() {
        self.analyzerView.updateView()
        self.spectrogramView.updateView()
    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------
    
    func togglePause() {
        NotificationCenter.default.post(
            name: .sdrPauseRequestNotification,
            object: self,
            userInfo: nil
        )
    }
    
    //--------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------
    
    func goLive() {
        NotificationCenter.default.post(
            name: .sdrLiveRequestNotification,
            object: self,
            userInfo: nil
        )
    }

    
}
