import SwiftUI
import UIKit

/// One-shot helpers for firing confetti from anywhere: a win screen, a purchase, a tap.
@MainActor
public enum Confetti {
    private static let overlayTag = 81_160_411
    private static let overlayLinger: TimeInterval = 0.45

    private static var cleanupTask: Task<Void, Never>?
    private static var isContinuousRunning = false

    // MARK: - Public API

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
        burst(
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
    }

    /// Full-screen burst from a ready-made configuration. `continuous` is ignored.
    public static func burst(configuration: ConfettiConfiguration) {
        var config = configuration
        config.continuous = false
        let overlay = installOverlay(configuration: config)
        overlay.burst()
        scheduleCleanup(of: overlay, after: config.duration + overlayLinger)
    }

    /// Start a continuous rain on the key window. Call ``stop()`` to end it.
    public static func start(configuration: ConfettiConfiguration) {
        cancelCleanup()
        isContinuousRunning = true
        var config = configuration
        config.continuous = true
        installOverlay(configuration: config).setContinuous(true)
    }

    public static func stop() {
        cancelCleanup()
        isContinuousRunning = false
        guard let view = keyWindow?.viewWithTag(overlayTag) as? ConfettiHostView else { return }
        view.stop()
        view.removeFromSuperview()
    }

    // MARK: - Overlay

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

    /// Removes the overlay after a burst. A newer burst replaces the pending cleanup,
    /// and a running continuous rain is never cleaned up here.
    private static func scheduleCleanup(of overlay: ConfettiHostView, after delay: TimeInterval) {
        cancelCleanup()
        guard !isContinuousRunning else { return }
        cleanupTask = Task { @MainActor [weak overlay] in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled, let overlay, overlay.superview != nil else { return }
            overlay.stop()
            overlay.removeFromSuperview()
        }
    }

    private static func cancelCleanup() {
        cleanupTask?.cancel()
        cleanupTask = nil
    }

    // MARK: - Windows

    private static var keyWindow: UIWindow? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let active = scenes.filter { $0.activationState == .foregroundActive }
        return keyWindow(in: active) ?? keyWindow(in: scenes)
    }

    private static func keyWindow(in scenes: [UIWindowScene]) -> UIWindow? {
        scenes.flatMap(\.windows).first { $0.isKeyWindow }
    }
}
