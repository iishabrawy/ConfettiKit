import SwiftUI

public extension View {
    /// Fires a full-screen confetti burst each time `trigger` changes (increment a counter).
    /// Safe to attach to a button — particles render on the key window, not inside the control.
    func confettiCannon(
        trigger: Binding<Int>,
        particles: [ConfettiParticle] = .default,
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
                    particles: particles,
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

    /// Burst once when `isActive` becomes `true`. Pass `continuous: true` to keep raining until it is false.
    func confetti(
        isActive: Binding<Bool>,
        particles: [ConfettiParticle] = .default,
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
                    particles: particles,
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

    func body(content: Content) -> some View {
        content
            .onChange(of: trigger) { _, newValue in
                guard newValue != 0, !configuration.continuous else { return }
                fireBurst()
            }
            .onChange(of: isActive) { _, newValue in
                if configuration.continuous {
                    if newValue { Confetti.start(configuration: configuration) }
                    else { Confetti.stop() }
                } else if newValue {
                    fireBurst()
                }
            }
            .onAppear {
                if trigger != 0 && !configuration.continuous {
                    fireBurst()
                }
                if configuration.continuous && isActive {
                    Confetti.start(configuration: configuration)
                }
            }
            .onDisappear {
                if configuration.continuous {
                    Confetti.stop()
                }
            }
    }

    private func fireBurst() {
        Confetti.burst(
            particles: configuration.particles,
            colors: configuration.colors,
            count: configuration.count,
            size: configuration.particleSize,
            emission: configuration.emission,
            origin: configuration.origin,
            duration: configuration.duration
        )
    }
}
