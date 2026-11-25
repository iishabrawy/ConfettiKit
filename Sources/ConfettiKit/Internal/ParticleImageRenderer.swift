import SwiftUI
import UIKit

enum ParticleImageRenderer {
    static let canvasSize: CGFloat = 32

    /// Pixel density used for every rendered bitmap and for `CAEmitterCell.contentsScale`.
    static let renderScale: CGFloat = 3

    /// Emoji and shape bitmaps are deterministic, so they are rendered once and reused.
    private static let imageCache = NSCache<NSString, CGImage>()

    // MARK: - Public entry point

    static func images(
        for particle: ConfettiParticle,
        colors: [UIColor],
        size: CGFloat = canvasSize
    ) -> [CGImage] {
        switch particle.representation {
        case .emoji(let value):
            let image = cached(key: "emoji|\(value)|\(size)") {
                renderEmoji(value, size: size)
            }
            return [image].compactMap { $0 }
        case .shape(let shape):
            return colors.compactMap { color in
                cached(key: "shape|\(shape.rawValue)|\(key(for: color))|\(size)") {
                    renderShape(shape, color: color, size: size)
                }
            }
        case .named(let name):
            return [rasterize(UIImage(named: name), size: CGSize(width: size, height: size))].compactMap { $0 }
        case .uiImage(let image):
            return [rasterize(image, size: CGSize(width: size, height: size))].compactMap { $0 }
        }
    }

    // MARK: - Rendering

    static func renderEmoji(_ string: String, size: CGFloat) -> CGImage? {
        let font = UIFont.systemFont(ofSize: size)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let text = string as NSString
        var bounds = text.size(withAttributes: attributes)
        bounds.width = max(bounds.width, 1)
        bounds.height = max(bounds.height, 1)
        let renderer = UIGraphicsImageRenderer(size: bounds, format: makeFormat())
        return renderer.image { _ in
            text.draw(at: .zero, withAttributes: attributes)
        }.cgImage
    }

    static func renderShape(_ shape: ConfettiShape, color: UIColor, size: CGFloat) -> CGImage? {
        let canvas = CGSize(width: size, height: size)
        let renderer = UIGraphicsImageRenderer(size: canvas, format: makeFormat())
        return renderer.image { _ in
            color.setFill()
            path(for: shape, in: CGRect(origin: .zero, size: canvas)).fill()
        }.cgImage
    }

    private static func rasterize(_ image: UIImage?, size: CGSize) -> CGImage? {
        guard let image else { return nil }
        let aspect = image.size.width / max(image.size.height, 1)
        let draw: CGRect
        if aspect > 1 {
            let height = size.width / aspect
            draw = CGRect(x: 0, y: (size.height - height) / 2, width: size.width, height: height)
        } else {
            let width = size.height * aspect
            draw = CGRect(x: (size.width - width) / 2, y: 0, width: width, height: size.height)
        }
        return UIGraphicsImageRenderer(size: size, format: makeFormat()).image { _ in
            image.draw(in: draw)
        }.cgImage
    }

    private static func makeFormat() -> UIGraphicsImageRendererFormat {
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        format.scale = renderScale
        return format
    }

    // MARK: - Cache

    private static func cached(key: String, render: () -> CGImage?) -> CGImage? {
        let cacheKey = key as NSString
        if let image = imageCache.object(forKey: cacheKey) { return image }
        guard let image = render() else { return nil }
        imageCache.setObject(image, forKey: cacheKey)
        return image
    }

    private static func key(for color: UIColor) -> String {
        guard let components = color.cgColor.components else { return color.description }
        return components.map { String(format: "%.4f", Double($0)) }.joined(separator: ",")
    }

    // MARK: - Paths

    static func path(for shape: ConfettiShape, in rect: CGRect) -> UIBezierPath {
        let inset = rect.insetBy(dx: rect.width * 0.08, dy: rect.height * 0.08)
        switch shape {
        case .circle:
            return UIBezierPath(ovalIn: inset)
        case .square:
            return squarePath(in: inset)
        case .rectangle:
            return rectanglePath(in: inset)
        case .ribbon:
            return ribbonPath(in: inset)
        case .triangle:
            return trianglePath(in: inset)
        case .diamond:
            return diamondPath(in: inset)
        case .star:
            return starPath(center: CGPoint(x: inset.midX, y: inset.midY), outer: min(inset.width, inset.height) / 2)
        case .heart:
            return heartPath(in: inset)
        }
    }

    private static func squarePath(in inset: CGRect) -> UIBezierPath {
        let side = min(inset.width, inset.height)
        let square = CGRect(
            x: inset.midX - side / 2,
            y: inset.midY - side / 2,
            width: side,
            height: side
        )
        return UIBezierPath(roundedRect: square, cornerRadius: side * 0.12)
    }

    private static func rectanglePath(in inset: CGRect) -> UIBezierPath {
        let rect = CGRect(
            x: inset.minX + inset.width * 0.08,
            y: inset.midY - inset.height * 0.18,
            width: inset.width * 0.84,
            height: inset.height * 0.36
        )
        return UIBezierPath(roundedRect: rect, cornerRadius: rect.height * 0.28)
    }

    private static func ribbonPath(in inset: CGRect) -> UIBezierPath {
        let rect = CGRect(
            x: inset.midX - inset.width * 0.16,
            y: inset.minY,
            width: inset.width * 0.32,
            height: inset.height
        )
        return UIBezierPath(roundedRect: rect, cornerRadius: rect.width * 0.35)
    }

    private static func trianglePath(in inset: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: inset.midX, y: inset.minY))
        path.addLine(to: CGPoint(x: inset.maxX, y: inset.maxY))
        path.addLine(to: CGPoint(x: inset.minX, y: inset.maxY))
        path.close()
        return path
    }

    private static func diamondPath(in inset: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: inset.midX, y: inset.minY))
        path.addLine(to: CGPoint(x: inset.maxX, y: inset.midY))
        path.addLine(to: CGPoint(x: inset.midX, y: inset.maxY))
        path.addLine(to: CGPoint(x: inset.minX, y: inset.midY))
        path.close()
        return path
    }

    private static func starPath(center: CGPoint, outer: CGFloat, points: Int = 5) -> UIBezierPath {
        let inner = outer * 0.42
        let path = UIBezierPath()
        let step = CGFloat.pi / CGFloat(points)
        var angle = -CGFloat.pi / 2
        for i in 0..<(points * 2) {
            let radius = i.isMultiple(of: 2) ? outer : inner
            let point = CGPoint(
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius
            )
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
            angle += step
        }
        path.close()
        return path
    }

    private static func heartPath(in rect: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        let w = rect.width
        let h = rect.height
        let x = rect.minX
        let y = rect.minY
        path.move(to: CGPoint(x: x + w / 2, y: y + h * 0.92))
        path.addCurve(
            to: CGPoint(x: x, y: y + h * 0.32),
            controlPoint1: CGPoint(x: x + w * 0.15, y: y + h * 0.72),
            controlPoint2: CGPoint(x: x, y: y + h * 0.55)
        )
        path.addCurve(
            to: CGPoint(x: x + w / 2, y: y + h * 0.28),
            controlPoint1: CGPoint(x: x, y: y + h * 0.08),
            controlPoint2: CGPoint(x: x + w * 0.32, y: y + h * 0.02)
        )
        path.addCurve(
            to: CGPoint(x: x + w, y: y + h * 0.32),
            controlPoint1: CGPoint(x: x + w * 0.68, y: y + h * 0.02),
            controlPoint2: CGPoint(x: x + w, y: y + h * 0.08)
        )
        path.addCurve(
            to: CGPoint(x: x + w / 2, y: y + h * 0.92),
            controlPoint1: CGPoint(x: x + w, y: y + h * 0.55),
            controlPoint2: CGPoint(x: x + w * 0.85, y: y + h * 0.72)
        )
        path.close()
        return path
    }
}
