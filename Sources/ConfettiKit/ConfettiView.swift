import SwiftUI
import UIKit

/// Full-size SwiftUI overlay that renders confetti with `CAEmitterLayer`.
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
        let view = ConfettiEmitterView()
        view.configuration = configuration
        return view
    }

    public func updateUIView(_ uiView: UIView, context: Context) {
        guard let view = uiView as? ConfettiEmitterView else { return }
        view.configuration = configuration

        if configuration.continuous {
            view.setContinuous(isActive)
            context.coordinator.lastToken = fireToken
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

    public final class Coordinator {
        var lastToken: Int = 0
        var wasActive = false
    }
}
