import Foundation

/// How particles leave the emitter.
public enum ConfettiEmission: String, CaseIterable, Hashable, Sendable {
    /// Upward burst from the bottom edge, like a party cannon.
    case cannon
    /// Fall from the top edge across the full width.
    case rain
    /// Radial burst from the center.
    case explosion
    /// Rise from the bottom center and fall back down.
    case fountain
}
