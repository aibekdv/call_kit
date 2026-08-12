import AVFAudio
import WebRTC

/// Manual-mode control of WebRTC's audio session.
///
/// CallKit owns `AVAudioSession` for any call it presents: it activates the
/// session and tells the app afterwards. WebRTC must therefore be in manual
/// mode, or the two race and the call ends up with no audio while every other
/// signal — tracks published, peer connection connected — looks healthy.
///
/// The notifications that drive this arrive through the host `AppDelegate`;
/// see `CallNativeKitHost`. If that forwarding is missing, [awaitActive] times
/// out and the call is silent, which is why [diagnostics] exists.
public enum CallAudioSession {

    private static let lock = NSLock()
    private static var nextWaiterToken = 0
    private static var pendingWaiters: [Int: (Bool) -> Void] = [:]
    private static var activationCount = 0
    private static var lastActivatedAt: Date?

    /// Hands the session to CallKit. Call before any call can arrive.
    public static func configureManualMode() {
        RTCAudioSession.sharedInstance().useManualAudio = true
        RTCAudioSession.sharedInstance().isAudioEnabled = false
    }

    /// Forward from `CallkitIncomingAppDelegate.didActivateAudioSession`.
    public static func didActivate(_ audioSession: AVAudioSession) {
        RTCAudioSession.sharedInstance().audioSessionDidActivate(audioSession)
        RTCAudioSession.sharedInstance().isAudioEnabled = true
        lock.lock()
        activationCount += 1
        lastActivatedAt = Date()
        lock.unlock()
        signalWaiters(activated: true)
    }

    /// Forward from `CallkitIncomingAppDelegate.didDeactivateAudioSession`.
    public static func didDeactivate(_ audioSession: AVAudioSession) {
        RTCAudioSession.sharedInstance().audioSessionDidDeactivate(audioSession)
        RTCAudioSession.sharedInstance().isAudioEnabled = false
    }

    /// Activates the session for a call that never went through CallKit —
    /// an outgoing call, or joining a room from inside the app.
    ///
    /// Idempotent: if CallKit already activated the session, this only
    /// re-asserts the routing.
    public static func activateForCall(defaultToSpeaker: Bool) {
        let session = AVAudioSession.sharedInstance()
        var options: AVAudioSession.CategoryOptions = [
            .allowBluetooth, .allowBluetoothA2DP,
        ]
        if defaultToSpeaker { options.insert(.defaultToSpeaker) }
        do {
            try session.setCategory(.playAndRecord, mode: .voiceChat, options: options)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            NSLog("[call_native_kit] activateForCall failed: \(error)")
        }
        RTCAudioSession.sharedInstance().audioSessionDidActivate(session)
        RTCAudioSession.sharedInstance().isAudioEnabled = true
        lock.lock()
        activationCount += 1
        lastActivatedAt = Date()
        lock.unlock()
    }

    public static func deactivateForCall() {
        let session = AVAudioSession.sharedInstance()
        RTCAudioSession.sharedInstance().isAudioEnabled = false
        RTCAudioSession.sharedInstance().audioSessionDidDeactivate(session)
        do {
            try session.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            NSLog("[call_native_kit] deactivateForCall failed: \(error)")
        }
    }

    /// Waits for CallKit to activate the session, for a call the user accepted
    /// on the system UI. Completes exactly once, possibly off the main queue.
    public static func awaitActive(
        timeoutMs: Int,
        completion: @escaping (Bool) -> Void
    ) {
        if RTCAudioSession.sharedInstance().isAudioEnabled {
            completion(true)
            return
        }

        lock.lock()
        nextWaiterToken += 1
        let token = nextWaiterToken
        pendingWaiters[token] = completion
        lock.unlock()

        // Activation could have landed between the check above and the lock,
        // in which case signalWaiters ran against an empty table and this
        // waiter would otherwise sit until the timeout for no reason.
        if RTCAudioSession.sharedInstance().isAudioEnabled {
            lock.lock()
            let waiter = pendingWaiters.removeValue(forKey: token)
            lock.unlock()
            waiter?(true)
            return
        }

        DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(timeoutMs)) {
            lock.lock()
            let waiter = pendingWaiters.removeValue(forKey: token)
            lock.unlock()
            waiter?(false)
        }
    }

    /// Reported to Dart so a silent call is visible rather than merely silent.
    public static func diagnostics() -> [String: Any] {
        lock.lock()
        let count = activationCount
        let last = lastActivatedAt
        lock.unlock()

        let session = AVAudioSession.sharedInstance()
        var payload: [String: Any] = [
            "isActive": RTCAudioSession.sharedInstance().isActive,
            "isAudioEnabled": RTCAudioSession.sharedInstance().isAudioEnabled,
            "activationCount": count,
            "category": session.category.rawValue,
            "mode": session.mode.rawValue,
        ]
        if let last {
            payload["lastActivatedAtMs"] = Int(last.timeIntervalSince1970 * 1000)
        }
        return payload
    }

    private static func signalWaiters(activated: Bool) {
        lock.lock()
        let waiters = Array(pendingWaiters.values)
        pendingWaiters.removeAll()
        lock.unlock()
        for waiter in waiters { waiter(activated) }
    }
}
