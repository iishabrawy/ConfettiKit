import Foundation

/// Geometric pieces built from bezier paths, rasterized once and tinted by ``ConfettiConfiguration/colors``.
public enum ConfettiShape: String, CaseIterable, Hashable, Sendable {
    case circle
    case square
    case rectangle
    case triangle
    case star
    case heart
    case ribbon
    case diamond
}
