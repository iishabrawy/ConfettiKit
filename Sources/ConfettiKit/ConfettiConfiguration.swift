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
}

// MARK: - Particle selection

extension ConfettiConfiguration {
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
}

// MARK: - Budgets

extension ConfettiConfiguration {
    /// How many pieces each kind should spawn.
    struct Budget: Equatable {
        enum Kind {
            case emoji, shape, image, lottie, rive
        }

        private(set) var emoji = 0
        private(set) var shape = 0
        private(set) var image = 0
        private(set) var lottie = 0
        private(set) var rive = 0

        /// Pieces drawn by the bitmap emitter (Lottie and Rive excluded).
        var staticTotal: Int { emoji + shape + image }

        mutating func assign(_ share: Int, to kind: Kind) {
            switch kind {
            case .emoji: emoji = share
            case .shape: shape = share
            case .image: image = share
            case .lottie: lottie = share
            case .rive: rive = share
            }
        }
    }

    /// Splits `count` across every non-empty group. The total is `count`.
    func budgets() -> Budget {
        let kinds = activeKinds
        var budget = Budget()
        var remaining = count
        for (index, kind) in kinds.enumerated() {
            let share = remaining / (kinds.count - index)
            budget.assign(share, to: kind)
            remaining -= share
        }
        return budget
    }

    var staticCount: Int { budgets().staticTotal }

    private var activeKinds: [Budget.Kind] {
        if usesDefaultShapes { return [.shape] }
        var kinds: [Budget.Kind] = []
        if !emojis.isEmpty { kinds.append(.emoji) }
        if !shapes.isEmpty { kinds.append(.shape) }
        if !images.isEmpty { kinds.append(.image) }
        if !lotties.isEmpty { kinds.append(.lottie) }
        if !rives.isEmpty { kinds.append(.rive) }
        return kinds
    }
}
