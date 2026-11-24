import UIKit

/// Static piece rendered into a `CAEmitterCell`. Built from the public arrays.
struct ConfettiParticle: Identifiable {
    let id = UUID()
    let representation: Representation

    enum Representation {
        case emoji(String)
        case shape(ConfettiShape)
        case named(String)
        case uiImage(UIImage)
    }

    static func emoji(_ value: String) -> ConfettiParticle {
        ConfettiParticle(representation: .emoji(value))
    }

    static func shape(_ shape: ConfettiShape) -> ConfettiParticle {
        ConfettiParticle(representation: .shape(shape))
    }

    static func image(named name: String) -> ConfettiParticle {
        ConfettiParticle(representation: .named(name))
    }

    static func image(_ image: UIImage) -> ConfettiParticle {
        ConfettiParticle(representation: .uiImage(image))
    }
}

extension Array where Element == ConfettiParticle {
    static var paper: [ConfettiParticle] {
        [.shape(.square), .shape(.rectangle), .shape(.circle), .shape(.triangle), .shape(.ribbon)]
    }
}
