import SwiftUI

/// Knobs for a burst or a continuous rain.
///
/// Pass any mix of arrays. Empty arrays are skipped. If every array is empty,
/// a default set of paper shapes is used.
public struct ConfettiConfiguration {
    public var emojis: [String]
    public var shapes: [ConfettiShape]
    public var images: [ConfettiImage]
    public var lotties: [ConfettiLottie]
    public var rives: [ConfettiRive]
    public var colors: [Color]
    public var count: Int
    public var particleSize: CGFloat
    public var emission: ConfettiEmission
    public var origin: UnitPoint
    public var duration: TimeInterval
    public var continuous: Bool

    public init(
        emojis: [String] = [],
        shapes: [ConfettiShape] = [],
        images: [ConfettiImage] = [],
        lotties: [ConfettiLottie] = [],
        rives: [ConfettiRive] = [],
        colors: [Color] = ConfettiConfiguration.defaultColors,
        count: Int = 80,
        particleSize: CGFloat = 12,
        emission: ConfettiEmission = .cannon,
        origin: UnitPoint? = nil,
        duration: TimeInterval = 3.2,
        continuous: Bool = false
    ) {
        self.emojis = emojis
        self.shapes = shapes
        self.images = images
        self.lotties = lotties
        self.rives = rives
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

    var usesDefaultShapes: Bool {
        emojis.isEmpty && shapes.isEmpty && images.isEmpty && lotties.isEmpty && rives.isEmpty
    }

    /// Bitmap pieces for the emitter. Lottie and Rive are not included.
    var staticParticles: [ConfettiParticle] {
        if usesDefaultShapes { return .paper }
        var list: [ConfettiParticle] = []
        list.append(contentsOf: emojis.map { .emoji($0) })
        list.append(contentsOf: shapes.map { .shape($0) })
        for item in images {
            switch item.source {
            case .named(let name): list.append(.image(named: name))
            case .image(let image): list.append(.image(image))
            }
        }
        return list
    }

    /// How many pieces each non-empty group should spawn. Total is `count`.
    func budgets() -> (emoji: Int, shape: Int, image: Int, lottie: Int, rive: Int) {
        var keys: [String] = []
        if usesDefaultShapes { keys.append("shape") }
        else {
            if !emojis.isEmpty { keys.append("emoji") }
            if !shapes.isEmpty { keys.append("shape") }
            if !images.isEmpty { keys.append("image") }
            if !lotties.isEmpty { keys.append("lottie") }
            if !rives.isEmpty { keys.append("rive") }
        }
        guard !keys.isEmpty else { return (0, 0, 0, 0, 0) }
        var remaining = count
        var shares: [String: Int] = [:]
        for (index, key) in keys.enumerated() {
            let left = keys.count - index
            let share = remaining / left
            shares[key] = share
            remaining -= share
        }
        return (
            shares["emoji"] ?? 0,
            shares["shape"] ?? 0,
            shares["image"] ?? 0,
            shares["lottie"] ?? 0,
            shares["rive"] ?? 0
        )
    }

    var staticCount: Int {
        let budget = budgets()
        return budget.emoji + budget.shape + budget.image
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
