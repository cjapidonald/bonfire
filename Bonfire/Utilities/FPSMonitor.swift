import Combine
import QuartzCore

@MainActor
final class FPSMonitor: NSObject, ObservableObject {
    @Published private(set) var framesPerSecond: Double = 60

    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    private var frameCount: Int = 0
    private let updateInterval: CFTimeInterval = 0.5

    func start() {
        stop()
        let link = CADisplayLink(target: self, selector: #selector(step(_:)))
        link.add(to: .main, forMode: .common)
        displayLink = link
        lastTimestamp = 0
        frameCount = 0
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
        lastTimestamp = 0
        frameCount = 0
    }

    @objc private func step(_ link: CADisplayLink) {
        if lastTimestamp == 0 {
            lastTimestamp = link.timestamp
            return
        }

        frameCount += 1
        let elapsed = link.timestamp - lastTimestamp

        guard elapsed >= updateInterval else { return }

        let fps = Double(frameCount) / elapsed
        framesPerSecond = fps

        lastTimestamp = link.timestamp
        frameCount = 0
    }

    deinit {
        stop()
    }
}
