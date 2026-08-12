import AVKit
import Flutter
import WebRTC

/// True native picture-in-picture for video calls.
///
/// Unlike Android, iOS does not render the Flutter tree in the small window:
/// it renders a native surface. So this class takes a WebRTC video track,
/// converts each frame to a `CVPixelBuffer`, and pushes it into an
/// `AVSampleBufferDisplayLayer` owned by an
/// `AVPictureInPictureVideoCallViewController`.
///
/// **Track selection is Dart's job, never this class's.** Dart knows which
/// participant matters — the active speaker, not a screen share, not a stale
/// receiver — and pushes that track id here. An earlier design that picked
/// "the first available track" reliably latched onto a screen share and showed
/// it where the user expected a face.
@available(iOS 15.0, *)
final class CallPipController: NSObject,
                               AVPictureInPictureControllerDelegate,
                               AVPictureInPictureSampleBufferPlaybackDelegate,
                               RTCVideoRenderer {

    private let channel: FlutterMethodChannel

    private var pipController: AVPictureInPictureController?
    private var pipVideoCallVC: AVPictureInPictureVideoCallViewController?
    private var displayLayer: AVSampleBufferDisplayLayer?

    private var hasActiveVideoCall = false
    private var isInPip = false
    private var frameCount = 0

    /// Keeps the window alive with black frames while no track is attached.
    /// Without a steady stream of samples iOS tears the window down.
    private var fallbackTimer: Timer?

    /// Retries attachment: Dart can name a track before `flutter_webrtc` has
    /// registered the receiver for it.
    private var trackRetryTimer: Timer?
    private var retryCount = 0
    private var reportedFailureFor: String?

    private var currentVideoTrack: RTCVideoTrack?
    private var pendingTrackId: String?

    init(channel: FlutterMethodChannel) {
        self.channel = channel
        super.init()
    }

    // MARK: - Public API

    func setActiveVideoCall(active: Bool, aspectWidth: Int, aspectHeight: Int) {
        hasActiveVideoCall = active
        if active {
            setupPipIfNeeded()
        } else {
            detachCurrentTrack()
            stopPip()
            tearDown()
        }
    }

    func enterPip() -> Bool {
        guard hasActiveVideoCall,
              let pip = pipController,
              pip.isPictureInPicturePossible
        else { return false }
        pip.startPictureInPicture()
        return true
    }

    func closePip() {
        guard isInPip, let pip = pipController else { return }
        pip.stopPictureInPicture()
    }

    /// Chooses the track to render. An empty id detaches and falls back to
    /// black frames — see the class doc for why this never guesses.
    func attachTrack(id trackId: String) {
        if trackId.isEmpty {
            pendingTrackId = nil
            reportedFailureFor = nil
            detachCurrentTrack()
            startFallbackTimer()
            return
        }

        pendingTrackId = trackId

        if let track = remoteTrack(id: trackId) {
            if track != currentVideoTrack {
                detachCurrentTrack()
                currentVideoTrack = track
                track.add(self)
                stopFallbackTimer()
                retryCount = 0
                reportedFailureFor = nil
            }
            return
        }

        // Not registered yet. Keep whatever is attached and let the retry
        // timer try again rather than substituting some other track.
        if currentVideoTrack == nil { startFallbackTimer() }
    }

    // MARK: - flutter_webrtc bridge

    /// Resolves a track through `flutter_webrtc` at runtime.
    ///
    /// Reached through the Objective-C runtime rather than a pod dependency,
    /// to avoid a static-link conflict over WebRTC. The cost is that this is
    /// bound to a private detail of that plugin: if a version bump renames
    /// `sharedSingleton` or `remoteTrackForId:`, the lookup returns nil and
    /// picture-in-picture goes black. That case is reported to Dart as
    /// `PipAttachmentFailed` instead of failing quietly.
    private func remoteTrack(id trackId: String) -> RTCVideoTrack? {
        guard let pluginClass = NSClassFromString("FlutterWebRTCPlugin") as? NSObject.Type
        else {
            reportAttachmentFailure(trackId, reason: "FlutterWebRTCPlugin not found")
            return nil
        }
        guard let plugin = pluginClass
            .perform(NSSelectorFromString("sharedSingleton"))?
            .takeUnretainedValue() as? NSObject
        else {
            reportAttachmentFailure(trackId, reason: "sharedSingleton unavailable")
            return nil
        }
        let selector = NSSelectorFromString("remoteTrackForId:")
        guard plugin.responds(to: selector) else {
            reportAttachmentFailure(trackId, reason: "remoteTrackForId: missing")
            return nil
        }
        return plugin.perform(selector, with: trackId)?
            .takeUnretainedValue() as? RTCVideoTrack
    }

    private func reportAttachmentFailure(_ trackId: String, reason: String) {
        guard reportedFailureFor != trackId else { return }
        reportedFailureFor = trackId
        DispatchQueue.main.async { [weak self] in
            self?.channel.invokeMethod(
                "onPipAttachmentFailed",
                arguments: ["trackId": trackId, "reason": reason]
            )
        }
    }

    private func detachCurrentTrack() {
        currentVideoTrack?.remove(self)
        currentVideoTrack = nil
        frameCount = 0
    }

    // MARK: - RTCVideoRenderer

    func setSize(_ size: CGSize) {}

    func renderFrame(_ frame: RTCVideoFrame?) {
        guard let frame, let layer = displayLayer else { return }
        guard let pixelBuffer = pixelBuffer(from: frame) else { return }
        frameCount += 1
        enqueue(pixelBuffer, on: layer, timescale: 30)
    }

    private func pixelBuffer(from frame: RTCVideoFrame) -> CVPixelBuffer? {
        // A hardware-decoded frame already carries a buffer, but not always an
        // IOSurface-backed one — and AVSampleBufferDisplayLayer renders those
        // as black. Copying guarantees the backing.
        if let cvBuffer = frame.buffer as? RTCCVPixelBuffer {
            return copyToIOSurfaceBuffer(cvBuffer.pixelBuffer)
        }
        return convertI420ToNV12(frame.buffer.toI420())
    }

    private func convertI420ToNV12(_ i420: RTCI420BufferProtocol) -> CVPixelBuffer? {
        let width = Int(i420.width)
        let height = Int(i420.height)

        var buffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width, height,
            kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
            [kCVPixelBufferIOSurfacePropertiesKey: [:] as CFDictionary] as CFDictionary,
            &buffer
        )
        guard status == kCVReturnSuccess, let target = buffer else { return nil }

        CVPixelBufferLockBaseAddress(target, [])
        defer { CVPixelBufferUnlockBaseAddress(target, []) }

        if let yDest = CVPixelBufferGetBaseAddressOfPlane(target, 0) {
            let destStride = CVPixelBufferGetBytesPerRowOfPlane(target, 0)
            let srcStride = Int(i420.strideY)
            for row in 0..<height {
                memcpy(
                    yDest + row * destStride,
                    i420.dataY + row * srcStride,
                    min(width, srcStride)
                )
            }
        }

        // I420 keeps U and V in separate planes; NV12 wants them interleaved.
        if let uvDest = CVPixelBufferGetBaseAddressOfPlane(target, 1) {
            let destStride = CVPixelBufferGetBytesPerRowOfPlane(target, 1)
            let uStride = Int(i420.strideU)
            let vStride = Int(i420.strideV)
            let uvWidth = width / 2
            let uvHeight = height / 2
            for row in 0..<uvHeight {
                let destRow = uvDest + row * destStride
                let uRow = i420.dataU + row * uStride
                let vRow = i420.dataV + row * vStride
                for col in 0..<uvWidth {
                    destRow.storeBytes(of: uRow[col], toByteOffset: col * 2, as: UInt8.self)
                    destRow.storeBytes(of: vRow[col], toByteOffset: col * 2 + 1, as: UInt8.self)
                }
            }
        }

        return target
    }

    private func copyToIOSurfaceBuffer(_ source: CVPixelBuffer) -> CVPixelBuffer? {
        let width = CVPixelBufferGetWidth(source)
        let height = CVPixelBufferGetHeight(source)

        var buffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width, height,
            CVPixelBufferGetPixelFormatType(source),
            [kCVPixelBufferIOSurfacePropertiesKey: [:] as CFDictionary] as CFDictionary,
            &buffer
        )
        guard status == kCVReturnSuccess, let target = buffer else { return source }

        CVPixelBufferLockBaseAddress(source, .readOnly)
        CVPixelBufferLockBaseAddress(target, [])
        defer {
            CVPixelBufferUnlockBaseAddress(source, .readOnly)
            CVPixelBufferUnlockBaseAddress(target, [])
        }

        let planeCount = CVPixelBufferGetPlaneCount(source)
        guard planeCount > 0 else {
            guard let srcBase = CVPixelBufferGetBaseAddress(source),
                  let dstBase = CVPixelBufferGetBaseAddress(target)
            else { return source }
            let srcStride = CVPixelBufferGetBytesPerRow(source)
            let dstStride = CVPixelBufferGetBytesPerRow(target)
            let rowBytes = min(srcStride, dstStride)
            for row in 0..<height {
                memcpy(dstBase + row * dstStride, srcBase + row * srcStride, rowBytes)
            }
            return target
        }

        for plane in 0..<planeCount {
            guard let srcBase = CVPixelBufferGetBaseAddressOfPlane(source, plane),
                  let dstBase = CVPixelBufferGetBaseAddressOfPlane(target, plane)
            else { continue }
            let srcStride = CVPixelBufferGetBytesPerRowOfPlane(source, plane)
            let dstStride = CVPixelBufferGetBytesPerRowOfPlane(target, plane)
            let rowBytes = min(srcStride, dstStride)
            for row in 0..<CVPixelBufferGetHeightOfPlane(source, plane) {
                memcpy(dstBase + row * dstStride, srcBase + row * srcStride, rowBytes)
            }
        }
        return target
    }

    // MARK: - Setup

    private func setupPipIfNeeded() {
        guard pipController == nil else { return }
        guard AVPictureInPictureController.isPictureInPictureSupported() else { return }

        guard let sourceView = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?
            .rootViewController?.view
        else { return }

        // Picture-in-picture is only offered for a session that looks like a
        // call; a session left on .soloAmbient makes the window refuse to open.
        do {
            let session = AVAudioSession.sharedInstance()
            if session.category != .playAndRecord {
                try session.setCategory(
                    .playAndRecord,
                    mode: .videoChat,
                    options: [.allowBluetooth, .defaultToSpeaker]
                )
                try session.setActive(true)
            }
        } catch {
            NSLog("[call_native_kit] pip audio session: \(error)")
        }

        let layer = AVSampleBufferDisplayLayer()
        layer.videoGravity = .resizeAspect
        displayLayer = layer

        let pipVC = AVPictureInPictureVideoCallViewController()
        pipVC.preferredContentSize = CGSize(width: 1080, height: 1920)

        let container = PipDisplayLayerView(displayLayer: layer)
        container.translatesAutoresizingMaskIntoConstraints = false
        pipVC.view.addSubview(container)
        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: pipVC.view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: pipVC.view.trailingAnchor),
            container.topAnchor.constraint(equalTo: pipVC.view.topAnchor),
            container.bottomAnchor.constraint(equalTo: pipVC.view.bottomAnchor),
        ])
        pipVideoCallVC = pipVC

        let pip = AVPictureInPictureController(
            contentSource: AVPictureInPictureController.ContentSource(
                activeVideoCallSourceView: sourceView,
                contentViewController: pipVC
            )
        )
        pip.delegate = self
        pip.canStartPictureInPictureAutomaticallyFromInline = true
        pipController = pip

        startFallbackTimer()
    }

    private func tearDown() {
        pendingTrackId = nil
        reportedFailureFor = nil
        detachCurrentTrack()
        stopFallbackTimer()
        pipController?.delegate = nil
        pipController = nil
        pipVideoCallVC = nil
        displayLayer = nil
    }

    private func stopPip() {
        if isInPip { pipController?.stopPictureInPicture() }
    }

    private func updateDisplayLayerFrame() {
        guard let layer = displayLayer,
              let view = pipVideoCallVC?.view,
              view.bounds.width > 0, view.bounds.height > 0
        else { return }
        DispatchQueue.main.async { layer.frame = view.bounds }
    }

    // MARK: - Fallback frames

    private func startFallbackTimer() {
        guard fallbackTimer == nil else { return }
        pushBlackFrame()
        fallbackTimer = Timer.scheduledTimer(
            withTimeInterval: 1.0 / 10.0,
            repeats: true
        ) { [weak self] _ in
            self?.pushBlackFrame()
        }
        startTrackRetryTimer()
    }

    private func stopFallbackTimer() {
        fallbackTimer?.invalidate()
        fallbackTimer = nil
        trackRetryTimer?.invalidate()
        trackRetryTimer = nil
    }

    private func startTrackRetryTimer() {
        guard trackRetryTimer == nil else { return }
        retryCount = 0
        trackRetryTimer = Timer.scheduledTimer(
            withTimeInterval: 1.0,
            repeats: true
        ) { [weak self] _ in
            guard let self,
                  self.currentVideoTrack == nil,
                  let pending = self.pendingTrackId, !pending.isEmpty
            else { return }
            self.retryCount += 1
            // Five seconds of retries is long past "the receiver has not
            // materialized yet" and well into "this is never going to work".
            if self.retryCount == 5 {
                self.reportAttachmentFailure(pending, reason: "track never resolved")
            }
            self.attachTrack(id: pending)
        }
    }

    private func pushBlackFrame() {
        guard let layer = displayLayer else { return }

        var buffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            320, 180,
            kCVPixelFormatType_32BGRA,
            [kCVPixelBufferIOSurfacePropertiesKey: [:] as CFDictionary] as CFDictionary,
            &buffer
        )
        guard status == kCVReturnSuccess, let target = buffer else { return }

        CVPixelBufferLockBaseAddress(target, [])
        if let base = CVPixelBufferGetBaseAddress(target) {
            memset(base, 0, CVPixelBufferGetDataSize(target))
        }
        CVPixelBufferUnlockBaseAddress(target, [])

        enqueue(target, on: layer, timescale: 10)
    }

    // MARK: - Enqueue

    private func enqueue(
        _ pixelBuffer: CVPixelBuffer,
        on layer: AVSampleBufferDisplayLayer,
        timescale: CMTimeScale
    ) {
        var formatDescription: CMVideoFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            formatDescriptionOut: &formatDescription
        )
        guard let format = formatDescription else { return }

        var timing = CMSampleTimingInfo(
            duration: CMTime(value: 1, timescale: timescale),
            presentationTimeStamp: CMClockGetTime(CMClockGetHostTimeClock()),
            decodeTimeStamp: .invalid
        )

        var sampleBuffer: CMSampleBuffer?
        CMSampleBufferCreateReadyWithImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            formatDescription: format,
            sampleTiming: &timing,
            sampleBufferOut: &sampleBuffer
        )
        guard let sample = sampleBuffer else { return }

        let work = {
            // The layer fails when the app is backgrounded and stays failed,
            // which is the usual cause of a window that goes black and never
            // recovers. Flushing clears the error; the next frame refills it.
            if layer.status == .failed { layer.flush() }
            layer.enqueue(sample)
        }
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.async(execute: work)
        }
    }

    // MARK: - AVPictureInPictureControllerDelegate

    func pictureInPictureControllerWillStartPictureInPicture(
        _ controller: AVPictureInPictureController
    ) {
        isInPip = true
        updateDisplayLayerFrame()
        channel.invokeMethod("onPipModeChanged", arguments: true)
    }

    func pictureInPictureControllerDidStopPictureInPicture(
        _ controller: AVPictureInPictureController
    ) {
        isInPip = false
        channel.invokeMethod("onPipModeChanged", arguments: false)
    }

    func pictureInPictureController(
        _ controller: AVPictureInPictureController,
        failedToStartPictureInPictureWithError error: Error
    ) {
        isInPip = false
        channel.invokeMethod("onPipModeChanged", arguments: false)
    }

    func pictureInPictureController(
        _ controller: AVPictureInPictureController,
        restoreUserInterfaceForPictureInPictureStopWithCompletionHandler
        completionHandler: @escaping (Bool) -> Void
    ) {
        DispatchQueue.main.async {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first?
                .windows.first?
                .makeKeyAndVisible()
            completionHandler(true)
        }
    }

    // MARK: - AVPictureInPictureSampleBufferPlaybackDelegate

    func pictureInPictureController(
        _ controller: AVPictureInPictureController,
        setPlaying playing: Bool
    ) {}

    func pictureInPictureControllerTimeRangeForPlayback(
        _ controller: AVPictureInPictureController
    ) -> CMTimeRange {
        // A live stream has no timeline; an infinite range stops iOS from
        // drawing scrubbing controls over the call.
        CMTimeRange(start: .negativeInfinity, duration: .positiveInfinity)
    }

    func pictureInPictureControllerIsPlaybackPaused(
        _ controller: AVPictureInPictureController
    ) -> Bool {
        false
    }

    func pictureInPictureController(
        _ controller: AVPictureInPictureController,
        didTransitionToRenderSize newRenderSize: CMVideoDimensions
    ) {
        updateDisplayLayerFrame()
    }

    func pictureInPictureController(
        _ controller: AVPictureInPictureController,
        skipByInterval skipInterval: CMTime
    ) async {}
}

/// Keeps the display layer filling its view.
///
/// A subview with constraints rather than KVO on `bounds`, which does not fire
/// dependably across iOS versions.
@available(iOS 15.0, *)
private final class PipDisplayLayerView: UIView {
    private let displayLayer: AVSampleBufferDisplayLayer

    init(displayLayer: AVSampleBufferDisplayLayer) {
        self.displayLayer = displayLayer
        super.init(frame: .zero)
        backgroundColor = .black
        layer.addSublayer(displayLayer)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        displayLayer.frame = bounds
        CATransaction.commit()
    }
}
