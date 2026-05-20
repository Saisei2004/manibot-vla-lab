import ARKit
import CoreMotion
import Foundation
import Network

final class MotionSender: NSObject, ObservableObject, ARSessionDelegate {
    @Published var isRunning = false
    @Published var status = "Stopped"
    @Published var px = 0.0
    @Published var py = 0.0
    @Published var pz = 0.0
    @Published var source = "AR"
    @Published var gripperOpen = 1.0
    @Published var packetsSent = 0
    @Published var motionIntensity = 0.0
    @Published var linkPulse = false
    @Published var gripperForce = "open"
    @Published var connectionHint = "Manual IP"
    @Published var wristPitch = 0.0

    var boost = false

    private let motion = CMMotionManager()
    private let session = ARSession()
    private var connection: NWConnection?
    private var timer: Timer?
    private var baselineTransform: simd_float4x4?
    private var lastARPosition = SIMD3<Double>(repeating: 0)
    private var inertialPosition = SIMD3<Double>(repeating: 0)
    private var inertialVelocity = SIMD3<Double>(repeating: 0)
    private var accelBias = SIMD3<Double>(repeating: 0)
    private var lastTick = Date()
    private var resetNext = false
    private var previousPose = SIMD3<Double>(repeating: 0)
    private var baselineGravityZ = 0.0
    private var hasBaselineGravity = false
    private var baselinePitch = 0.0
    private var hasBaselinePitch = false

    override init() {
        super.init()
    }

    func start(host: String, port: UInt16, boost: Bool) {
        self.boost = boost
        let resolvedHost = host.isEmpty ? "192.168.64.1" : host
        let resolvedPort = port == 0 ? 8765 : port
        connection = NWConnection(
            host: NWEndpoint.Host(resolvedHost),
            port: NWEndpoint.Port(rawValue: resolvedPort) ?? 8765,
            using: .udp
        )
        connection?.stateUpdateHandler = { [weak self] state in
            DispatchQueue.main.async { self?.status = state.shortName }
        }
        connection?.start(queue: .global(qos: .userInteractive))

        if motion.isDeviceMotionAvailable {
            motion.deviceMotionUpdateInterval = 1.0 / 60.0
            motion.startDeviceMotionUpdates(using: .xArbitraryCorrectedZVertical)
            calibrateBias()
        }

        if ARWorldTrackingConfiguration.isSupported {
            let config = ARWorldTrackingConfiguration()
            config.worldAlignment = .gravity
            session.delegate = self
            session.run(config, options: [.resetTracking, .removeExistingAnchors])
            source = "AR"
        } else {
            source = "IMU"
        }

        baselineTransform = nil
        lastTick = Date()
        inertialPosition = .zero
        inertialVelocity = .zero
        hasBaselineGravity = false
        hasBaselinePitch = false
        gripperOpen = 1.0
        gripperForce = "open"
        wristPitch = 0.0
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 45.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        isRunning = true
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        motion.stopDeviceMotionUpdates()
        session.pause()
        connection?.cancel()
        connection = nil
        isRunning = false
        status = "Stopped"
    }

    func sendReset() {
        resetNext = true
        baselineTransform = nil
        inertialPosition = .zero
        inertialVelocity = .zero
        px = 0
        py = 0
        pz = 0
        previousPose = .zero
        motionIntensity = 0
        hasBaselineGravity = false
        hasBaselinePitch = false
        gripperOpen = 1.0
        gripperForce = "open"
        wristPitch = 0.0
    }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        if baselineTransform == nil {
            baselineTransform = frame.camera.transform
        }
        guard let baseline = baselineTransform else { return }
        let base = baseline.columns.3
        let current = frame.camera.transform.columns.3
        let dx = Double(current.x - base.x)
        let dy = Double(current.y - base.y)
        let dz = Double(current.z - base.z)
        lastARPosition = SIMD3(dx, dy, dz)
    }

    private func calibrateBias() {
        guard let sample = motion.deviceMotion else { return }
        accelBias = worldAcceleration(from: sample)
    }

    private func tick() {
        let now = Date()
        let dt = min(max(now.timeIntervalSince(lastTick), 0.0), 0.05)
        lastTick = now

        if source == "AR" {
            px = clamp(-lastARPosition.z / 0.38)
            py = clamp(-lastARPosition.x / 0.28)
            pz = clamp(lastARPosition.y / 0.16)
        } else {
            updateInertialFallback(dt: dt)
            px = clamp(inertialPosition.x)
            py = clamp(inertialPosition.y)
            pz = clamp(inertialPosition.z)
        }
        let pose = SIMD3(px, py, pz)
        let delta = pose - previousPose
        motionIntensity = clamp(Double(simd_length(delta)) * 3.0, 0.0, 1.0)
        previousPose = pose

        if let sample = motion.deviceMotion {
            if !hasBaselineGravity {
                baselineGravityZ = sample.gravity.z
                hasBaselineGravity = true
            }
            if !hasBaselinePitch {
                baselinePitch = sample.attitude.pitch
                hasBaselinePitch = true
            }
            gripperOpen = gripperAmount(from: sample.gravity.z, baselineZ: baselineGravityZ)
            wristPitch = pitchAmount(from: sample.attitude.pitch, baseline: baselinePitch)
        }
        gripperForce = gripperForceState()

        let payload: [String: Any] = [
            "mode": "pose",
            "px": px,
            "py": py,
            "pz": pz,
            "pitch": wristPitch,
            "grip": gripperOpen,
            "grip_force": gripperForce,
            "boost": boost,
            "reset": resetNext,
            "source": source,
            "t": Date().timeIntervalSince1970
        ]
        resetNext = false
        guard let data = try? JSONSerialization.data(withJSONObject: payload) else { return }
        connection?.send(content: data, completion: .contentProcessed { _ in })
        packetsSent += 1
        linkPulse.toggle()
    }

    private func updateInertialFallback(dt: TimeInterval) {
        guard let sample = motion.deviceMotion else { return }
        var acceleration = worldAcceleration(from: sample) - accelBias
        acceleration = applyDeadband(acceleration, threshold: 0.10)
        inertialVelocity += acceleration * dt
        inertialVelocity *= 0.91
        inertialPosition += inertialVelocity * dt * 2.2
        inertialPosition.x = clamp(inertialPosition.x * 0.997)
        inertialPosition.y = clamp(inertialPosition.y * 0.997)
        inertialPosition.z = clamp(inertialPosition.z * 0.996)
    }

    private func gripperAmount(from gravityZ: Double, baselineZ: Double) -> Double {
        let neutral = clamp(baselineZ, -0.75, 0.75)
        let closeProgress = (gravityZ - neutral) / max(0.12, 1.0 - neutral)
        return clamp(1.0 - closeProgress, 0.0, 1.0)
    }

    private func gripperForceState() -> String {
        guard let sample = motion.deviceMotion, hasBaselineGravity else { return "none" }
        let z = sample.gravity.z
        let neutral = clamp(baselineGravityZ, -0.75, 0.75)
        let closeProgress = (z - neutral) / max(0.12, 1.0 - neutral)
        if closeProgress >= 0.84 {
            return "close"
        }
        if closeProgress <= 0.04 {
            return "open"
        }
        return "none"
    }

    private func pitchAmount(from pitch: Double, baseline: Double) -> Double {
        let delta = normalizeAngle(pitch - baseline)
        return clamp(-delta / 0.85, -1.0, 1.0)
    }

    private func normalizeAngle(_ value: Double) -> Double {
        var angle = value
        while angle > .pi { angle -= 2.0 * .pi }
        while angle < -.pi { angle += 2.0 * .pi }
        return angle
    }

    private func worldAcceleration(from sample: CMDeviceMotion) -> SIMD3<Double> {
        let a = sample.userAcceleration
        let m = sample.attitude.rotationMatrix
        let x = m.m11 * a.x + m.m12 * a.y + m.m13 * a.z
        let y = m.m21 * a.x + m.m22 * a.y + m.m23 * a.z
        let z = m.m31 * a.x + m.m32 * a.y + m.m33 * a.z
        return SIMD3(x, y, z) * 9.80665
    }

    private func applyDeadband(_ value: SIMD3<Double>, threshold: Double) -> SIMD3<Double> {
        SIMD3(
            abs(value.x) < threshold ? 0 : value.x,
            abs(value.y) < threshold ? 0 : value.y,
            abs(value.z) < threshold ? 0 : value.z
        )
    }

    private func clamp(_ value: Double, _ low: Double = -1.0, _ high: Double = 1.0) -> Double {
        max(low, min(high, value))
    }
}

private extension NWConnection.State {
    var shortName: String {
        switch self {
        case .ready: "Ready"
        case .preparing: "Preparing"
        case .waiting: "Waiting"
        case .failed: "Failed"
        case .cancelled: "Stopped"
        case .setup: "Setup"
        @unknown default: "Unknown"
        }
    }
}
