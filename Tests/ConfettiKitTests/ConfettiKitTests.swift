import XCTest
@testable import ConfettiKit
import UIKit

final class ConfettiKitTests: XCTestCase {
    func testEmptyConfigurationUsesPaperShapes() {
        let config = ConfettiConfiguration()
        XCTAssertTrue(config.usesDefaultShapes)
        XCTAssertFalse(config.staticParticles.isEmpty)
    }

    func testArraysStaySeparate() {
        let config = ConfettiConfiguration(
            emojis: ["🎉", "✨"],
            shapes: [.star, .heart],
            images: [.named("logo")],
            lotties: [.named("pop")],
            rives: [.named("badge")]
        )
        XCTAssertEqual(config.emojis, ["🎉", "✨"])
        XCTAssertEqual(config.shapes, [.star, .heart])
        XCTAssertEqual(config.staticParticles.count, 5)
        XCTAssertEqual(config.lotties.count, 1)
        XCTAssertEqual(config.rives.count, 1)
    }

    func testLottieOnlyDoesNotAddShapes() {
        let config = ConfettiConfiguration(lotties: [.named("pop")])
        XCTAssertTrue(config.staticParticles.isEmpty)
        XCTAssertEqual(config.budgets().lottie, config.count)
        XCTAssertEqual(config.budgets().shape, 0)
    }

    func testCountIsSplitAcrossGroups() {
        let config = ConfettiConfiguration(
            emojis: ["🎉"],
            shapes: [.circle],
            images: [.named("logo")],
            count: 90
        )
        let budget = config.budgets()
        XCTAssertEqual(budget.emoji + budget.shape + budget.image, 90)
        XCTAssertEqual(budget.emoji, 30)
        XCTAssertEqual(budget.shape, 30)
        XCTAssertEqual(budget.image, 30)
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

    func testRiveStatesPickOnePlayback() {
        let item = ConfettiRive.named(
            "badge",
            stateMachine: "ignored",
            inputs: [.trigger("always")],
            states: [
                .animation("idle"),
                .machine("State Machine 1", inputs: [.bool("happy", true)])
            ]
        )
        let playback = item.nextPlayback()
        if playback.animation == "idle" {
            XCTAssertNil(playback.stateMachine)
            XCTAssertEqual(playback.inputs, [.trigger("always")])
        } else {
            XCTAssertEqual(playback.stateMachine, "State Machine 1")
            XCTAssertEqual(playback.inputs, [.trigger("always"), .bool("happy", true)])
        }
    }

    func testEmojiRenders() {
        let images = ParticleImageRenderer.images(for: .emoji("🎉"), colors: [.red])
        XCTAssertEqual(images.count, 1)
    }
}
