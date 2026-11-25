import SwiftUI

public extension View {
    /// Fires a full-screen burst each time `trigger` changes (increment a counter).
    ///
    /// Each argument is its own array. Leave an array empty to skip that kind.
    /// Lottie and Rive files play while they fall.
    func confettiCannon(
        trigger: Binding<Int>,
        emojis: [String] = [],
        shapes: [ConfettiShape] = [],
        images: [ConfettiImage] = [],
        lotties: [ConfettiLottie] = [],
        rives: [ConfettiRive] = [],
        colors: [Color] = ConfettiConfiguration.defaultColors,
        count: Int = 80,
        size: CGFloat = 12,
        emission: ConfettiEmission = .cannon,
        origin: UnitPoint? = nil,
        duration: TimeInterval = 3.2
    ) -> some View {
        modifier(
            ConfettiCannonModifier(
                trigger: trigger,
                isActive: .constant(false),
                configuration: ConfettiConfiguration(
                    emojis: emojis,
                    shapes: shapes,
                    images: images,
                    lotties: lotties,
                    rives: rives,
                    colors: colors,
                    count: count,
                    particleSize: size,
                    emission: emission,
                    origin: origin,
                    duration: duration,
                    continuous: false
                )
            )
        )
    }

    /// Burst once when `isActive` becomes `true`. Pass `continuous: true` to keep going until it is false.
    func confetti(
        isActive: Binding<Bool>,
        emojis: [String] = [],
        shapes: [ConfettiShape] = [],
        images: [ConfettiImage] = [],
        lotties: [ConfettiLottie] = [],
        rives: [ConfettiRive] = [],
        colors: [Color] = ConfettiConfiguration.defaultColors,
        count: Int = 80,
        size: CGFloat = 12,
        emission: ConfettiEmission = .cannon,
        origin: UnitPoint? = nil,
        duration: TimeInterval = 3.2,
        continuous: Bool = false
    ) -> some View {
        modifier(
            ConfettiCannonModifier(
                trigger: .constant(0),
                isActive: isActive,
                configuration: ConfettiConfiguration(
                    emojis: emojis,
                    shapes: shapes,
                    images: images,
                    lotties: lotties,
                    rives: rives,
                    colors: colors,
                    count: count,
                    particleSize: size,
                    emission: emission,
                    origin: origin,
                    duration: duration,
                    continuous: continuous
                )
            )
        )
    }
}

struct ConfettiCannonModifier: ViewModifier {
    @Binding var trigger: Int
    @Binding var isActive: Bool
    var configuration: ConfettiConfiguration

    /// True while this modifier started the continuous rain, so it never stops another view's rain.
    @State private var ownsContinuous = false

    func body(content: Content) -> some View {
        content
            .onChange(of: trigger) { _, newValue in
                guard newValue != 0, !configuration.continuous else { return }
                Confetti.burst(configuration: configuration)
            }
            .onChange(of: isActive) { _, newValue in
                handleActiveChange(newValue)
            }
            .onAppear {
                handleAppear()
            }
            .onDisappear {
                stopContinuousIfOwned()
            }
    }

    @MainActor
    private func handleActiveChange(_ newValue: Bool) {
        if configuration.continuous {
            if newValue {
                startContinuous()
            } else {
                stopContinuousIfOwned()
            }
        } else if newValue {
            Confetti.burst(configuration: configuration)
        }
    }

    @MainActor
    private func handleAppear() {
        if trigger != 0 && !configuration.continuous {
            Confetti.burst(configuration: configuration)
        }
        if configuration.continuous && isActive {
            startContinuous()
        }
    }

    @MainActor
    private func startContinuous() {
        ownsContinuous = true
        Confetti.start(configuration: configuration)
    }

    @MainActor
    private func stopContinuousIfOwned() {
        guard ownsContinuous else { return }
        ownsContinuous = false
        Confetti.stop()
    }
}
