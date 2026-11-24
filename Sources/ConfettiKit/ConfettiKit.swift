import SwiftUI
import UIKit

/// One-shot helpers for firing confetti from anywhere — a win screen, a purchase, a tap.
@MainActor
public enum Confetti {
    /// Drops a full-screen confetti burst into the key window.
    /// Mix ``ConfettiParticle/emoji(_:)``, ``ConfettiParticle/shape(_:)``, and
    /// ``ConfettiParticle/image(named:)`` — or pass only one kind.
    public static func burst(
        particles: [ConfettiParticle] = .default,
        colors: [Color] = ConfettiConfiguration.defaultColors,
        count: Int = 120,
        size: CGFloat = 12,
        emission: ConfettiEmission = .cannon,
        origin: UnitPoint? = nil,
        duration: TimeInterval = 3.2
    ) {
        let configuration = ConfettiConfiguration(
            particles: particles,
            colors: colors,
            count: count,
            particleSize: size,
            emission: emission,
            origin: origin,
            duration: duration,
            continuous: false
        )
        let overlay = installOverlay(configuration: configuration)
        overlay.burst()
        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.45) {
            if overlay.superview != nil && overlay.tag == overlayTag {
                overlay.removeFromSuperview()
            }
        }
    }

    /// Start a continuous rain/fountain on the key window. Call ``stop()`` to end it.
    public static func start(configuration: ConfettiConfiguration) {
        var config = configuration
        config.continuous = true
        installOverlay(configuration: config).setContinuous(true)
    }

    public static func stop() {
        keyWindow?.viewWithTag(overlayTag)?.removeFromSuperview()
    }

    @discardableResult
    private static func installOverlay(configuration: ConfettiConfiguration) -> ConfettiEmitterView {
        guard let window = keyWindow else {
            return ConfettiEmitterView(frame: .zero)
        }
        if let existing = window.viewWithTag(overlayTag) as? ConfettiEmitterView {
            existing.configuration = configuration
            return existing
        }
        let overlay = ConfettiEmitterView(frame: window.bounds)
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlay.configuration = configuration
        overlay.tag = overlayTag
        window.addSubview(overlay)
        return overlay
    }

    private static let overlayTag = 81_160_411

    private static var keyWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }
    }
}
