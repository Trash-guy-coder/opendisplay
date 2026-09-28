import UIKit
import GameController

/// Foreground-only hardware input, separate from finger/Pencil sampling. There
/// is no key-content logging, hidden text field, or iPad text-composition proxy.
class HardwareInputCaptureView: UIView, UIPointerInteractionDelegate {
    weak var hardwareReceiver: StreamReceiver?
    var normalizeHardwarePoint: ((CGPoint) -> (x: Double, y: Double)?)?
    private var inputEnabled = false
    private var inputRequested = false
    private var pressedKeys = Set<Int>()
    private var pointerButton: Int?
    private var scrollGesture = TrackpadScrollGesture()
    private var mice: [GCMouse] = []
    private var relativePeerBound = false
    private var lastReadyState = ""
    private var mouseObservers: [NSObjectProtocol] = []
    private var lastHoverPoint: CGPoint?
    private var clickTime: [Int: TimeInterval] = [:]
    private var clickCount: [Int: Int] = [:]
    private var movementSinceClick = 0.0
    private var currentModifiers: UInt = 0
    private var inactiveObserver: NSObjectProtocol?

    private var canForward: Bool {
        inputEnabled && window != nil && UIApplication.shared.applicationState == .active
            && hardwareReceiver?.macSupportsHardwareInput == true
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        let hover = UIHoverGestureRecognizer(target: self, action: #selector(hovered(_:)))
        hover.allowedTouchTypes = [NSNumber(value: UITouch.TouchType.indirectPointer.rawValue)]
        hover.cancelsTouchesInView = false
        addGestureRecognizer(hover)

        // A trackpad scroll has zero UITouches. Reusing the two-finger touch
        // recognizer drops it or accidentally emits a click.
        let scroll = UIPanGestureRecognizer(target: self, action: #selector(scrolled(_:)))
        scroll.allowedScrollTypesMask = .all
        scroll.allowedTouchTypes = []
        scroll.minimumNumberOfTouches = 0
        scroll.maximumNumberOfTouches = 0
        scroll.cancelsTouchesInView = false
        addGestureRecognizer(scroll)
        addInteraction(UIPointerInteraction(delegate: self))

        mouseObservers.append(NotificationCenter.default.addObserver(
            forName: UIPointerLockState.didChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Log.info("relative pointer: system lock=\(self.window?.windowScene?.pointerLockState?.isLocked == true)")
        })
        for name in [NSNotification.Name.GCMouseDidConnect, .GCMouseDidDisconnect] {
            mouseObservers.append(NotificationCenter.default.addObserver(
                forName: name, object: nil, queue: .main
            ) { [weak self] _ in
                self?.releaseHardwareInput()
                self?.refreshHardwareFocus(rebind: true)
            })
        }
        for name in [UIApplication.didBecomeActiveNotification, UIScene.didActivateNotification] {
            mouseObservers.append(NotificationCenter.default.addObserver(
                forName: name, object: nil, queue: .main
            ) { [weak self] _ in
                self?.refreshHardwareFocus(rebind: true)
            })
        }
        inactiveObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification, object: nil, queue: .main
        ) { [weak self] _ in self?.releaseHardwareInput() }
    }

    required init?(coder: NSCoder) { fatalError("Programmatic video view only") }

    deinit {
        if let inactiveObserver { NotificationCenter.default.removeObserver(inactiveObserver) }
        mouseObservers.forEach { NotificationCenter.default.removeObserver($0) }
        unbindMice()
    }

    func configureHardwareInput(receiver: StreamReceiver, enabled: Bool) {
        hardwareReceiver = receiver
        inputRequested = enabled
        let effective = enabled && receiver.macSupportsHardwareInput
        let changed = effective != inputEnabled
        inputEnabled = effective
        if effective {
            refreshHardwareFocus(rebind: changed || relativePeerBound != receiver.macSupportsRelativePointer)
        } else if changed {
            releaseHardwareInput()
            unbindMice()
            if isFirstResponder { _ = resignFirstResponder() }
        }
    }

    private func updatePointerLock() {
        (window?.rootViewController as? InputHostingController)?.wantsPointerLock =
            canForward && hardwareReceiver?.macSupportsRelativePointer == true && !mice.isEmpty
    }

    private func refreshHardwareFocus(rebind: Bool) {
        guard inputEnabled else { return }
        if rebind { bindRelativeMice() }
        updatePointerLock()
        acquireKeyboardFocus()
    }

    override var canBecomeFirstResponder: Bool { canForward }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil { releaseHardwareInput() }
        else { refreshHardwareFocus(rebind: true) }
    }

    override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()
        if result { releaseHardwareInput() }
        return result
    }

    private func acquireKeyboardFocus() {
        DispatchQueue.main.async { [weak self] in
            guard let self, self.canForward else { return }
            self.updatePointerLock()
            if !self.isFirstResponder { self.becomeFirstResponder() }
            let ready = "responder=\(self.isFirstResponder), rawMouse=\(!self.mice.isEmpty)"
            if ready != self.lastReadyState {
                self.lastReadyState = ready
                Log.info("hardware input ready: \(ready)")
            }
        }
    }

    func releaseHardwareInput() {
        if let cancelled = scrollGesture.cancel(modifiers: currentModifiers) {
            hardwareReceiver?.sendPreciseScroll(cancelled)
        }
        pressedKeys.removeAll()
        pointerButton = nil
        lastHoverPoint = nil
        currentModifiers = 0
        clickTime.removeAll()
        clickCount.removeAll()
        (window?.rootViewController as? InputHostingController)?.wantsPointerLock = false
        hardwareReceiver?.resetHardwareInput()
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        let unhandled = forwardKeys(presses, down: true)
        if !unhandled.isEmpty { super.pressesBegan(unhandled, with: event) }
    }

    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        let unhandled = forwardKeys(presses, down: false)
        if !unhandled.isEmpty { super.pressesEnded(unhandled, with: event) }
    }

    override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        // A cancellation need not contain the modifier releases. Reset the
        // complete session so Command/Shift and held pointer buttons cannot stick.
        releaseHardwareInput()
        refreshHardwareFocus(rebind: false)
        super.pressesCancelled(presses, with: event)
    }

    private func forwardKeys(_ presses: Set<UIPress>, down: Bool) -> Set<UIPress> {
        guard canForward else { return presses }
        var unhandled = Set<UIPress>()
        for press in presses {
            guard let key = press.key else { unhandled.insert(press); continue }
            currentModifiers = UInt(key.modifierFlags.rawValue)
            let code = Int(key.keyCode.rawValue)
            let input = HardwareInput.Key(code: code, down: down,
                                          mod: UInt(key.modifierFlags.rawValue))
            guard input.isValid else { unhandled.insert(press); continue }
            if down {
                guard pressedKeys.insert(code).inserted else { continue }
            } else {
                guard pressedKeys.remove(code) != nil else { continue }
            }
            if (224...231).contains(code) {
                let bit: UInt = [1 << 18, 1 << 17, 1 << 19, 1 << 20][(code - 224) % 4]
                if pressedKeys.contains(where: { (224...231).contains($0) && ($0 - 224) % 4 == (code - 224) % 4 }) {
                    currentModifiers |= bit
                } else { currentModifiers &= ~bit }
            }
            hardwareReceiver?.sendHardwareKey(input)
        }
        return unhandled
    }

    /// Returns true only for the optional new pointer path. Legacy Macs keep
    /// receiving the existing indirect-touch primary click fallback.
    func forwardPointerTouches(_ phase: String, _ touches: Set<UITouch>, _ event: UIEvent?) -> Bool {
        guard let touch = touches.first(where: { $0.type == .indirectPointer }) else { return false }
        guard inputRequested else { return true }
        guard hardwareReceiver?.macSupportsHardwareInput == true else { return false }
        if hardwareReceiver?.macSupportsRelativePointer == true {
            // Raw GCMouse owns buttons when present. UIKit remains a relative
            // fallback on devices whose trackpad is not exposed through it.
            guard mice.isEmpty, canForward,
                  let phase = HardwareInput.Pointer.Phase(rawValue: phase) else { return true }
            if phase == .began {
                pointerButton = event?.buttonMask.contains(.secondary) == true ? 2 : 1
                if !isFirstResponder { becomeFirstResponder() }
            }
            hardwareReceiver?.sendRelativePointer(.init(
                phase: phase, dx: 0, dy: 0, button: pointerButton ?? 1,
                clicks: min(max(touch.tapCount, 1), 3),
                mod: UInt(event?.modifierFlags.rawValue ?? 0)))
            if phase == .ended || phase == .cancelled { pointerButton = nil }
            return true
        }
        guard canForward,
              let point = normalizeHardwarePoint?(touch.location(in: self)),
              let phase = HardwareInput.Pointer.Phase(rawValue: phase) else { return true }
        if phase == .began {
            if !isFirstResponder { becomeFirstResponder() }
            pointerButton = event?.buttonMask.contains(.secondary) == true ? 2 : 1
        }
        let input = HardwareInput.Pointer(
            phase: phase, x: point.x, y: point.y, button: pointerButton ?? 1,
            clicks: min(max(touch.tapCount, 1), 3),
            mod: UInt(event?.modifierFlags.rawValue ?? 0))
        hardwareReceiver?.sendHardwarePointer(input)
        if phase == .ended || phase == .cancelled { pointerButton = nil }
        return true
    }

    @objc private func hovered(_ gesture: UIHoverGestureRecognizer) {
        guard canForward else { return }
        if hardwareReceiver?.macSupportsRelativePointer == true {
            guard mice.isEmpty else { return }
            let point = gesture.location(in: self)
            if gesture.state == .changed, let previous = lastHoverPoint {
                hardwareReceiver?.sendRelativePointer(.init(
                    phase: .moved, dx: Double(point.x - previous.x), dy: Double(point.y - previous.y),
                    button: pointerButton ?? 1, clicks: 1, mod: UInt(gesture.modifierFlags.rawValue)))
            }
            lastHoverPoint = gesture.state == .ended || gesture.state == .cancelled ? nil : point
            return
        }
        guard gesture.state == .began || gesture.state == .changed,
              let point = normalizeHardwarePoint?(gesture.location(in: self)) else { return }
        hardwareReceiver?.sendHardwarePointer(.init(
            phase: .moved, x: point.x, y: point.y, button: pointerButton ?? 1,
            clicks: 1, mod: UInt(gesture.modifierFlags.rawValue)))
    }

    @objc private func scrolled(_ gesture: UIPanGestureRecognizer) {
        guard canForward else { return }
        let phase: HardwareInput.PreciseScroll.Phase
        switch gesture.state {
        case .began: phase = .began
        case .changed: phase = .changed
        case .ended: phase = .ended
        case .cancelled, .failed: phase = .cancelled
        default: return
        }
        if phase == .began {
            if hardwareReceiver?.macSupportsRelativePointer != true,
               let point = normalizeHardwarePoint?(gesture.location(in: self)) {
                hardwareReceiver?.sendHardwarePointer(.init(
                    phase: .moved, x: point.x, y: point.y, button: 1,
                    clicks: 1, mod: UInt(gesture.modifierFlags.rawValue)))
            }
        }
        let translation = gesture.translation(in: self)
        guard let input = scrollGesture.update(
            phase: phase,
            translation: .init(dx: Double(translation.x), dy: Double(translation.y)),
            speed: savedSpeed("trackpadScrollSpeed", default: TrackpadTuning.defaultScrollSpeed),
            reversed: UserDefaults.standard.bool(forKey: "trackpadReverseScroll"),
            modifiers: UInt(gesture.modifierFlags.rawValue)) else { return }
        hardwareReceiver?.sendPreciseScroll(input)

    }

    private func savedSpeed(_ key: String, default value: Double) -> Double {
        (UserDefaults.standard.object(forKey: key) as? NSNumber)?.doubleValue ?? value
    }

    private func unbindMice() {
        for mouse in mice {
            mouse.mouseInput?.mouseMovedHandler = nil
            mouse.mouseInput?.leftButton.pressedChangedHandler = nil
            mouse.mouseInput?.rightButton?.pressedChangedHandler = nil
            mouse.mouseInput?.middleButton?.pressedChangedHandler = nil
            mouse.mouseInput?.scroll.valueChangedHandler = nil
        }
        mice.removeAll()
        relativePeerBound = false
        (window?.rootViewController as? InputHostingController)?.wantsPointerLock = false
    }

    private func bindRelativeMice() {
        unbindMice()
        guard inputEnabled, hardwareReceiver?.macSupportsRelativePointer == true else { return }
        relativePeerBound = true
        mice = GCMouse.mice()
        updatePointerLock()
        Log.info("relative pointer: raw devices=\(mice.count)")
        for mouse in mice {
            mouse.handlerQueue = .main
            guard let input = mouse.mouseInput else { continue }
            input.mouseMovedHandler = { [weak self] _, x, y in
                guard let self, self.canForward else { return }
                guard let delta = TrackpadTuning.pointer(x: Double(x), y: Double(y),
                    speed: self.savedSpeed("trackpadPointerSpeed", default: TrackpadTuning.defaultPointerSpeed)) else { return }
                self.movementSinceClick += hypot(delta.dx, delta.dy)
                self.hardwareReceiver?.sendRelativePointer(.init(
                    phase: .moved, dx: delta.dx, dy: delta.dy,
                    button: 1, clicks: 1, mod: self.currentModifiers))
            }
            for (number, button) in [(1, input.leftButton), (2, input.rightButton), (3, input.middleButton)] {
                button?.pressedChangedHandler = { [weak self] _, _, down in
                    guard let self, self.canForward else { return }
                    let now = ProcessInfo.processInfo.systemUptime
                    if down {
                        let repeated = now - (self.clickTime[number] ?? 0) < 0.5 && self.movementSinceClick < 4
                        self.clickCount[number] = repeated ? min((self.clickCount[number] ?? 1) + 1, 3) : 1
                        self.clickTime[number] = now
                        self.movementSinceClick = 0
                        self.acquireKeyboardFocus()
                    }
                    self.hardwareReceiver?.sendRelativePointer(.init(
                        phase: down ? .began : .ended, dx: 0, dy: 0, button: number,
                        clicks: self.clickCount[number] ?? 1, mod: self.currentModifiers))
                }
            }
            // UIKit is the sole scroll producer, including while GCMouse
            // owns relative movement and buttons. This preserves screen axes,
            // natural direction and actual begin/end semantics.
            input.scroll.valueChangedHandler = nil
        }
    }

    func pointerInteraction(_ interaction: UIPointerInteraction,
                            styleFor region: UIPointerRegion) -> UIPointerStyle? {
        // The sender's cursor is displayed in the stream / cursor echo layer.
        // Hide the iPad pointer only while we are forwarding its movement.
        canForward ? .hidden() : nil
    }
}
