import SwiftUI
import UIKit

/// Full-size overlay. Prefer ``View/confettiCannon(trigger:emojis:shapes:images:lotties:rives:colors:count:size:emission:origin:duration:)``
/// when you want the burst on the key window instead of clipped to this view.
public struct ConfettiView: UIViewRepresentable {
    var configuration: ConfettiConfiguration
    var fireToken: Int
    var isActive: Bool

    public init(
        configuration: ConfettiConfiguration = ConfettiConfiguration(),
        fireToken: Int = 0,
        isActive: Bool = false
    ) {
        self.configuration = configuration
        self.fireToken = fireToken
        self.isActive = isActive
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    public func makeUIView(context: Context) -> UIView {
        let view = ConfettiHostView()
        view.configuration = configuration
        return view
    }

    public func updateUIView(_ uiView: UIView, context: Context) {
        guard let view = uiView as? ConfettiHostView else { return }
        view.configuration = configuration

        if configuration.continuous {
            applyContinuous(to: view, coordinator: context.coordinator)
            return
        }

        if fireToken != context.coordinator.lastToken {
            context.coordinator.lastToken = fireToken
            if fireToken != 0 {
                view.burst()
            }
        } else if isActive && !context.coordinator.wasActive {
            view.burst()
        }
        context.coordinator.wasActive = isActive
    }

    /// Stops timers and display links when SwiftUI removes the view.
    public static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        (uiView as? ConfettiHostView)?.stop()
    }

    /// Only touches the emitter when the active flag actually changed.
    private func applyContinuous(to view: ConfettiHostView, coordinator: Coordinator) {
        if coordinator.appliedContinuous != isActive {
            coordinator.appliedContinuous = isActive
            view.setContinuous(isActive)
        }
        coordinator.lastToken = fireToken
    }

    public final class Coordinator {
        var lastToken: Int = 0
        var wasActive = false
        var appliedContinuous: Bool?
    }
}
