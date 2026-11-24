# ConfettiKit

SwiftUI confetti for iOS 17+. Each kind is its own array. Pass all of them, or only the ones you want.

- `emojis: [String]`
- `shapes: [ConfettiShape]`
- `images: [ConfettiImage]`
- `lotties: [ConfettiLottie]` — JSON or dotLottie, played while they fall
- `rives: [ConfettiRive]` — `.riv` files, played while they fall

```swift
import SwiftUI
import ConfettiKit

struct WinView: View {
    @State private var burst = 0

    var body: some View {
        Button("You won") { burst += 1 }
            .confettiCannon(
                trigger: $burst,
                emojis: ["🎉", "✨"],
                shapes: [.star, .ribbon],
                images: [.named("logo")],
                lotties: [.named("confetti")],
                rives: [.named("badge")]
            )
    }
}
```

Add the Lottie JSON / `.lottie` and the Rive `.riv` to your app target. Names can include the extension.

## One kind

```swift
.confettiCannon(trigger: $burst, emojis: ["🎉", "❤️"])

.confettiCannon(trigger: $burst, shapes: [.star, .heart, .ribbon])

.confettiCannon(trigger: $burst, images: [.named("mascot"), .image(photo)])

.confettiCannon(trigger: $burst, lotties: [.named("pop"), .file(fileURL)])

.confettiCannon(trigger: $burst, rives: [.named("truck", animation: "drive")])
```

`count` is the total number of pieces, split across the arrays you passed. Lottie and Rive are capped at 20 views per burst.

## Files

| Array | Factory | Notes |
|---|---|---|
| emojis | `"🎉"` | Original glyph colors |
| shapes | `.star`, `.circle`, `.square`, `.rectangle`, `.triangle`, `.heart`, `.ribbon`, `.diamond` | Tinted with `colors` |
| images | `.named("logo")`, `.image(uiImage)` | Drawn as-is |
| lotties | `.named("confetti")`, `.file(url)`, `.data(json)` | Loops while falling |
| rives | `.named("badge", artboard:animation:stateMachine:)` `.url(url)` `.data(data)` | Loops while falling |

## From anywhere

```swift
Confetti.burst(
    emojis: ["🏆"],
    shapes: [.star],
    images: [.named("badge")],
    lotties: [.named("spark")],
    rives: [.named("medal")],
    emission: .rain
)
```

`.rain` fills the top half of the screen, then pieces drift to the bottom on random paths.

## Rive states

A state machine starts at its entry state. Inputs move it. Pass one machine, or several states so each piece picks one at random.

```swift
rives: [
    .named(
        "badge",
        stateMachine: "State Machine 1",
        inputs: [.trigger("pop"), .bool("happy", true), .number("level", 2)]
    ),
    .named(
        "badge",
        states: [
            .animation("idle"),
            .machine("State Machine 1", inputs: [.trigger("win")]),
            .machine("State Machine 1", inputs: [.bool("happy", false)])
        ]
    )
]
```

Input names are the ones in the Rive editor: boolean, number, or trigger.

## Install

This package depends on [Lottie](https://github.com/airbnb/lottie-spm) and [Rive](https://github.com/rive-app/rive-ios). Xcode fetches both when you add ConfettiKit.

Private remote: push this folder to a private GitHub repo, then in Xcode choose **File → Add Package Dependencies…** and paste the repo URL. Sign in with an account that can read the repo.
