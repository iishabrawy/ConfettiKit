import SwiftUI
import UIKit

/// One-shot helpers for firing confetti from anywhere — a win screen, a purchase, a tap.
@MainActor
public enum Confetti {
    /// Full-screen burst. Pass any mix of arrays, or just one.
    public static func burst(
        emojis: [String] = [],
        shapes: [ConfettiShape] = [],
        images: [ConfettiImage] = [],
        lotties: [ConfettiLottie] = [],
        rives: [ConfettiRive] = [],
        colors: [Color] = ConfettiConfiguration.defaultColors,
        count: Int = 120,
        size: CGFloat = 12,
        emission: ConfettiEmission = .cannon,
        origin: UnitPoint? = nil,
        duration: TimeInterval = 3.2
    ) {
        let configuration = ConfettiConfiguration(
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
        let overlay = installOverlay(configuration: configuration)
        overlay.burst()
        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.45) {
            if overlay.superview != nil && overlay.tag == overlayTag {
                overlay.stop()
                overlay.removeFromSuperview()
            }
        }
    }

    /// Start a continuous rain on the key window. Call ``stop()`` to end it.
    public static func start(configuration: ConfettiConfiguration) {
        var config = configuration
        config.continuous = true
        installOverlay(configuration: config).setContinuous(true)
    }

    public static func stop() {
        guard let view = keyWindow?.viewWithTag(overlayTag) as? ConfettiHostView else { return }
        view.stop()
        view.removeFromSuperview()
    }

    @discardableResult
    private static func installOverlay(configuration: ConfettiConfiguration) -> ConfettiHostView {
        guard let window = keyWindow else {
            return ConfettiHostView(frame: .zero)
        }
        if let existing = window.viewWithTag(overlayTag) as? ConfettiHostView {
            existing.configuration = configuration
            return existing
        }
        let overlay = ConfettiHostView(frame: window.bounds)
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
