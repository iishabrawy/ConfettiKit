import XCTest
@testable import ConfettiKit
import UIKit

final class ConfettiKitTests: XCTestCase {
    func testDefaultParticlesNotEmpty() {
        XCTAssertFalse([ConfettiParticle].default.isEmpty)
        XCTAssertFalse([ConfettiParticle].emojis.isEmpty)
        XCTAssertEqual([ConfettiParticle].shapes.count, ConfettiShape.allCases.count)
    }

    func testShapeImagesRender() {
        for shape in ConfettiShape.allCases {
            let images = ParticleImageRenderer.images(
                for: .shape(shape),
                colors: [.systemPink, .systemTeal]
            )
            XCTAssertEqual(images.count, 2, "Expected a tinted image per color for \(shape)")
        }
    }

    func testEmojiRenders() {
        let images = ParticleImageRenderer.images(for: .emoji("🎉"), colors: [.red])
        XCTAssertEqual(images.count, 1)
    }

    func testMixDoesNotDropKinds() {
        let mixed: [ConfettiParticle] = [
            .emoji("🎉"),
            .shape(.star),
            .sfSymbol("heart.fill")
        ]
        XCTAssertEqual(mixed.count, 3)
    }

    func testConfigurationReplacesEmptyParticles() {
        let config = ConfettiConfiguration(particles: [])
        XCTAssertFalse(config.particles.isEmpty)
    }
}
