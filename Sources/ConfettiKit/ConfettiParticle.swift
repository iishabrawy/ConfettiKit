import SwiftUI
import UIKit

/// A single confetti ingredient. Mix emojis, shapes, and images — or pass just one kind.
public struct ConfettiParticle: Identifiable {
    public let id: UUID
    let representation: Representation

    enum Representation {
        case emoji(String)
        case shape(ConfettiShape)
        case sfSymbol(String)
        case named(String)
        case uiImage(UIImage)
    }

    init(id: UUID = UUID(), representation: Representation) {
        self.id = id
        self.representation = representation
    }

    /// Renders the emoji glyph as a particle (keeps its original colors).
    public static func emoji(_ value: String) -> ConfettiParticle {
        ConfettiParticle(representation: .emoji(value))
    }

    /// Vector shape, tinted with ``ConfettiConfiguration/colors``.
    public static func shape(_ shape: ConfettiShape) -> ConfettiParticle {
        ConfettiParticle(representation: .shape(shape))
    }

    /// SF Symbol, tinted with ``ConfettiConfiguration/colors``.
    public static func sfSymbol(_ name: String) -> ConfettiParticle {
        ConfettiParticle(representation: .sfSymbol(name))
    }

    /// Image from the asset catalog or bundle. Drawn as-is (not recolored).
    public static func image(named name: String) -> ConfettiParticle {
        ConfettiParticle(representation: .named(name))
    }

    /// Arbitrary bitmap — logos, stickers, photos. Drawn as-is.
    public static func image(_ image: UIImage) -> ConfettiParticle {
        ConfettiParticle(representation: .uiImage(image))
    }
}

public extension Array where Element == ConfettiParticle {
    /// Colorful paper bits. Used when you don't pass ``particles``.
    static var `default`: [ConfettiParticle] {
        [.shape(.square), .shape(.rectangle), .shape(.circle), .shape(.triangle), .shape(.ribbon)]
    }

    static var emojis: [ConfettiParticle] {
        [.emoji("🎉"), .emoji("✨"), .emoji("🎊"), .emoji("⭐️"), .emoji("💥")]
    }

    static var shapes: [ConfettiParticle] {
        ConfettiShape.allCases.map { .shape($0) }
    }
}
