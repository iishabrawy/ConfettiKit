import CoreGraphics
import SwiftUI

/// How particles leave the emitter.
public enum ConfettiEmission: String, CaseIterable, Hashable, Sendable {
    /// Upward burst from the origin. The origin defaults to the bottom edge.
    case cannon
    /// Falls across the full width. Pieces start in the top half of the screen.
    case rain
    /// Radial burst from the origin. The origin defaults to the center.
    case explosion
    /// Rises from the origin and falls back down. The origin defaults to the bottom center.
    case fountain
}

extension ConfettiEmission {
    var defaultOrigin: UnitPoint {
        switch self {
        case .cannon, .fountain: return .bottom
        case .rain: return .top
        case .explosion: return .center
        }
    }

    /// Physics for one `CAEmitterCell`. Values are unchanged from the previous inline switch.
    struct CellTuning {
        let longitude: CGFloat
        let range: CGFloat
        let velocity: CGFloat
        let velocityRange: CGFloat
        let yAcceleration: CGFloat
        let xAcceleration: CGFloat
    }

    var cellTuning: CellTuning {
        switch self {
        case .cannon:
            return CellTuning(
                longitude: -.pi / 2,
                range: .pi / 3.4,
                velocity: 380,
                velocityRange: 140,
                yAcceleration: 260,
                xAcceleration: 8
            )
        case .rain:
            return CellTuning(
                longitude: .pi / 2,
                range: .pi / 4,
                velocity: 70,
                velocityRange: 90,
                yAcceleration: 160,
                xAcceleration: 0
            )
        case .explosion:
            return CellTuning(
                longitude: 0,
                range: .pi * 2,
                velocity: 280,
                velocityRange: 120,
                yAcceleration: 160,
                xAcceleration: 0
            )
        case .fountain:
            return CellTuning(
                longitude: -.pi / 2,
                range: .pi / 6.5,
                velocity: 460,
                velocityRange: 80,
                yAcceleration: 420,
                xAcceleration: 0
            )
        }
    }
}
