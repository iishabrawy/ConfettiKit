import SwiftUI
import UIKit

final class ConfettiEmitterView: UIView {
    var configuration = ConfettiConfiguration() {
        didSet { rebuildCells() }
    }

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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22, execute: item)
    }

    func setContinuous(_ on: Bool) {
        applyGeometry()
        rebuildCells()
        emitter.birthRate = on ? 1 : 0
    }

    private func applyGeometry() {
        let bounds = bounds.isEmpty ? UIScreen.main.bounds : bounds
        let origin = CGPoint(
            x: configuration.origin.x * bounds.width,
            y: configuration.origin.y * bounds.height
        )

        switch configuration.emission {
        case .cannon:
            emitter.emitterShape = .line
            emitter.emitterPosition = origin
            emitter.emitterSize = CGSize(width: bounds.width * 0.22, height: 1)
        case .rain:
            emitter.emitterShape = .rectangle
            emitter.emitterPosition = CGPoint(x: bounds.midX, y: bounds.height * 0.25)
            emitter.emitterSize = CGSize(width: bounds.width, height: max(1, bounds.height * 0.5))
        case .explosion:
            emitter.emitterShape = .point
            emitter.emitterPosition = origin
            emitter.emitterSize = .zero
        case .fountain:
            emitter.emitterShape = .point
            emitter.emitterPosition = origin
            emitter.emitterSize = .zero
        }
    }

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

        let window: Float = configuration.continuous ? 6 : 0.22
        let total = max(configuration.staticCount, 1)
        let perCell = max(0.4, Float(total) / Float(images.count) / window)
        emitter.emitterCells = images.map { image in
            makeCell(image: image, birthRate: perCell)
        }
    }

    private func makeCell(image: CGImage, birthRate: Float) -> CAEmitterCell {
        let cell = CAEmitterCell()
        cell.contents = image
        cell.contentsScale = 3
        cell.birthRate = birthRate
        cell.lifetime = Float(configuration.duration)
        cell.lifetimeRange = Float(configuration.duration) * 0.28
        cell.spin = 3.4
        cell.spinRange = 6.5
        cell.scale = max(0.18, configuration.particleSize / ParticleImageRenderer.canvasSize)
        cell.scaleRange = cell.scale * 0.45
        cell.scaleSpeed = -cell.scale / CGFloat(max(configuration.duration, 1)) * 0.35
        cell.alphaRange = 0.15
        cell.alphaSpeed = -0.12
        cell.velocityRange = 90

        switch configuration.emission {
        case .cannon:
            cell.emissionLongitude = -.pi / 2
            cell.emissionRange = .pi / 3.4
            cell.velocity = 380
            cell.velocityRange = 140
            cell.yAcceleration = 260
            cell.xAcceleration = 8
        case .rain:
            cell.emissionLongitude = .pi / 2
            cell.emissionRange = .pi / 4
            cell.velocity = 70
            cell.velocityRange = 90
            cell.yAcceleration = 160
            cell.xAcceleration = 0
        case .explosion:
            cell.emissionLongitude = 0
            cell.emissionRange = .pi * 2
            cell.velocity = 280
            cell.velocityRange = 120
            cell.yAcceleration = 160
        case .fountain:
            cell.emissionLongitude = -.pi / 2
            cell.emissionRange = .pi / 6.5
            cell.velocity = 460
            cell.velocityRange = 80
            cell.yAcceleration = 420
        }
        return cell
    }
}
