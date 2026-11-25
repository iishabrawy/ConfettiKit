import SwiftUI
import UIKit

final class ConfettiEmitterView: UIView {
    private static let burstWindow: TimeInterval = 0.22
    private static let continuousWindow: Float = 6

    var configuration = ConfettiConfiguration() {
        didSet { rebuildCells() }
    }

    // `layerClass` guarantees the backing layer is a `CAEmitterLayer`.
    private var emitter: CAEmitterLayer { layer as! CAEmitterLayer }
    private var burstWorkItem: DispatchWorkItem?

    override class var layerClass: AnyClass { CAEmitterLayer.self }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear
        emitter.birthRate = 0
        emitter.emitterMode = .surface
        emitter.renderMode = .oldestLast
        emitter.masksToBounds = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        applyGeometry()
    }

    // MARK: - Control

    func burst() {
        applyGeometry()
        rebuildCells()
        emitter.beginTime = CACurrentMediaTime()
        emitter.birthRate = 1
        burstWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            self?.emitter.birthRate = 0
        }
        burstWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.burstWindow, execute: item)
    }

    func setContinuous(_ on: Bool) {
        applyGeometry()
        rebuildCells()
        emitter.birthRate = on ? 1 : 0
    }

    /// Stops emitting without rebuilding cells or geometry.
    func stop() {
        burstWorkItem?.cancel()
        burstWorkItem = nil
        emitter.birthRate = 0
    }

    // MARK: - Geometry

    private var fallbackBounds: CGRect {
        window?.windowScene?.screen.bounds ?? .zero
    }

    private func applyGeometry() {
        let area = bounds.isEmpty ? fallbackBounds : bounds
        let origin = CGPoint(
            x: configuration.origin.x * area.width,
            y: configuration.origin.y * area.height
        )

        switch configuration.emission {
        case .cannon:
            emitter.emitterShape = .line
            emitter.emitterPosition = origin
            emitter.emitterSize = CGSize(width: area.width * 0.22, height: 1)
        case .rain:
            emitter.emitterShape = .rectangle
            emitter.emitterPosition = CGPoint(x: area.midX, y: area.height * 0.25)
            emitter.emitterSize = CGSize(width: area.width, height: max(1, area.height * 0.5))
        case .explosion, .fountain:
            emitter.emitterShape = .point
            emitter.emitterPosition = origin
            emitter.emitterSize = .zero
        }
    }

    // MARK: - Cells

    private func rebuildCells() {
        let colors = configuration.colors.map(\.uiColor)
        var images: [CGImage] = []
        for particle in configuration.staticParticles {
            images.append(contentsOf: ParticleImageRenderer.images(for: particle, colors: colors))
        }
        guard !images.isEmpty else {
            emitter.emitterCells = []
            return
        }

        let window: Float = configuration.continuous ? Self.continuousWindow : Float(Self.burstWindow)
        let total = max(configuration.staticCount, 1)
        let perCell = max(0.4, Float(total) / Float(images.count) / window)
        emitter.emitterCells = images.map { image in
            makeCell(image: image, birthRate: perCell)
        }
    }

    private func makeCell(image: CGImage, birthRate: Float) -> CAEmitterCell {
        let cell = CAEmitterCell()
        cell.contents = image
        cell.contentsScale = ParticleImageRenderer.renderScale
        cell.birthRate = birthRate
        cell.lifetime = Float(configuration.duration)
        cell.lifetimeRange = Float(configuration.duration) * 0.28
        cell.spin = 3.4
        cell.spinRange = 6.5
        cell.scale = max(0.18, configuration.particleSize / ParticleImageRenderer.canvasSize)
        cell.scaleRange = cell.scale * 0.45
        cell.scaleSpeed = -cell.scale / Float(max(configuration.duration, 1)) * 0.35
        cell.alphaRange = 0.15
        cell.alphaSpeed = -0.12

        let tuning = configuration.emission.cellTuning
        cell.emissionLongitude = tuning.longitude
        cell.emissionRange = tuning.range
        cell.velocity = tuning.velocity
        cell.velocityRange = tuning.velocityRange
        cell.yAcceleration = tuning.yAcceleration
        cell.xAcceleration = tuning.xAcceleration
        return cell
    }
}
