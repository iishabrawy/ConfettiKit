import SwiftUI

/// Knobs for a burst or a continuous rain.
public struct ConfettiConfiguration: Equatable {
    public var particles: [ConfettiParticle]
    public var colors: [Color]
    public var count: Int
    public var particleSize: CGFloat
    public var emission: ConfettiEmission
    public var origin: UnitPoint
    public var duration: TimeInterval
    public var continuous: Bool

    public init(
        particles: [ConfettiParticle] = .default,
        colors: [Color] = ConfettiConfiguration.defaultColors,
        count: Int = 80,
        particleSize: CGFloat = 12,
        emission: ConfettiEmission = .cannon,
        origin: UnitPoint? = nil,
        duration: TimeInterval = 3.2,
        continuous: Bool = false
    ) {
        self.particles = particles.isEmpty ? .default : particles
        self.colors = colors.isEmpty ? ConfettiConfiguration.defaultColors : colors
        self.count = max(1, count)
        self.particleSize = max(4, particleSize)
        self.emission = emission
        self.origin = origin ?? emission.defaultOrigin
        self.duration = max(0.4, duration)
        self.continuous = continuous
    }

    public static let defaultColors: [Color] = [
        Color(red: 0.96, green: 0.27, blue: 0.31),
        Color(red: 0.25, green: 0.64, blue: 0.96),
        Color(red: 0.38, green: 0.82, blue: 0.53),
        Color(red: 0.99, green: 0.76, blue: 0.18),
        Color(red: 0.95, green: 0.45, blue: 0.78),
        Color(red: 0.45, green: 0.85, blue: 0.92)
    ]
}

extension ConfettiParticle: Equatable {
    public static func == (lhs: ConfettiParticle, rhs: ConfettiParticle) -> Bool {
        lhs.id == rhs.id
    }
}

extension ConfettiEmission {
    var defaultOrigin: UnitPoint {
        switch self {
        case .cannon, .fountain: return .bottom
        case .rain: return .top
        case .explosion: return .center
        }
    }
}
