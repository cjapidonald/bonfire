import Foundation
import SwiftUI

@MainActor
final class PerformanceSettings: ObservableObject {
    static let shared = PerformanceSettings()

    @Published var particleIntensity: Double
    @Published var blurStrength: Double

    private let defaultParticleIntensity: Double = 1.0
    private let defaultBlurStrength: Double = 1.0

    private init(particleIntensity: Double = 1.0, blurStrength: Double = 1.0) {
        self.particleIntensity = particleIntensity
        self.blurStrength = blurStrength
    }

    func setParticlesEnabled(_ isEnabled: Bool) {
        particleIntensity = isEnabled ? defaultParticleIntensity : 0
    }

    func setBlurEnabled(_ isEnabled: Bool) {
        blurStrength = isEnabled ? defaultBlurStrength : 0
    }

    func resetVisualEffects() {
        particleIntensity = defaultParticleIntensity
        blurStrength = defaultBlurStrength
    }

    func reduceForLowPerformance() {
        particleIntensity = min(particleIntensity, 0.4)
        blurStrength = min(blurStrength, 0.5)
    }

    var areParticlesEnabled: Bool {
        particleIntensity > 0.01
    }

    var isBlurEnabled: Bool {
        blurStrength > 0.01
    }
}
