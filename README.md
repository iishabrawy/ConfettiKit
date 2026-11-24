# ConfettiKit

SwiftUI confetti for iOS. Throw **custom images**, **emojis**, and **shapes** — all at once, or just one of them.

```swift
import SwiftUI
import ConfettiKit

struct WinView: View {
    @State private var burst = 0

    var body: some View {
        Button("You won") { burst += 1 }
            .confettiCannon(
                trigger: $burst,
                particles: [
                    .emoji("🎉"),
                    .emoji("✨"),
                    .shape(.star),
                    .image(named: "logo")
                ]
            )
    }
}
```

Requires **iOS 17+** and SwiftUI.

## Install

### Local package (this zip)

1. Unzip `ConfettiKit`.
2. In Xcode: **File → Add Package Dependencies…**
3. Choose **Add Local…** and select the `ConfettiKit` folder.
4. Add the `ConfettiKit` library to your app target.

### Swift Package Manager

```swift
dependencies: [
    .package(path: "path/to/ConfettiKit")
]
```

## Particles

Pass any combination. Omit a kind and it will not appear.

```swift
// Only emojis
particles: [.emoji("🎉"), .emoji("❤️")]

// Only shapes
particles: [.shape(.star), .shape(.ribbon), .shape(.heart)]

// Only a custom image
particles: [.image(named: "mascot")]

// Mix all three
particles: [
    .emoji("🎊"),
    .shape(.triangle),
    .sfSymbol("star.fill"),
    .image(named: "logo"),
    .image(UIImage(named: "sticker")!)
]
```

| Factory | Recolored? |
|---|---|
| `.emoji("🎉")` | No — keeps glyph colors |
| `.shape(.star)` | Yes — uses `colors:` |
| `.sfSymbol("heart.fill")` | Yes — uses `colors:` |
| `.image(named:)` / `.image(UIImage)` | No — drawn as-is |

## SwiftUI modifiers

Attach the modifier to a **full-screen** container so particles are not clipped.

```swift
ContentView()
    .confettiCannon(
        trigger: $burst,
        particles: [.emoji("🎉"), .shape(.circle)],
        colors: [.pink, .cyan, .orange, .mint],
        count: 100,
        size: 14,
        emission: .cannon
    )
```

Boolean style — fires when `isActive` becomes `true`. Pass `continuous: true` to keep raining until it is false.

```swift
ContentView()
    .confetti(
        isActive: $won,
        particles: [.shape(.heart), .emoji("💖")],
        emission: .rain,
        continuous: true
    )
```

## Emissions

- `.cannon` — upward burst from the bottom
- `.rain` — fall from the top
- `.explosion` — radial burst from the center
- `.fountain` — rise and fall from the bottom

Override `origin:` with a `UnitPoint` to move the emitter.

## Fire from anywhere

```swift
Confetti.burst(
    particles: [
        .emoji("🏆"),
        .shape(.star),
        .image(named: "badge")
    ],
    emission: .explosion
)
```

Adds a full-screen overlay to the key window, then removes it.

## Overlay view

```swift
ZStack {
    GameView()
    ConfettiView(
        configuration: ConfettiConfiguration(
            particles: [.emoji("🎉"), .shape(.ribbon)],
            emission: .fountain
        ),
        fireToken: burst
    )
    .allowsHitTesting(false)
}
```
