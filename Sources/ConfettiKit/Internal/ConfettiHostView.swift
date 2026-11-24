import UIKit

final class ConfettiHostView: UIView {
    let emitter = ConfettiEmitterView()
    let motion = MotionConfettiView()

    var configuration = ConfettiConfiguration() {
        didSet {
            emitter.configuration = configuration
            motion.configuration = configuration
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear
        emitter.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        motion.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(emitter)
        addSubview(motion)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        emitter.frame = bounds
        motion.frame = bounds
    }

    func burst() {
        emitter.burst()
        motion.burst()
    }

    func setContinuous(_ on: Bool) {
        emitter.setContinuous(on)
        motion.setContinuous(on)
    }

    func stop() {
        emitter.setContinuous(false)
        motion.stop()
    }
}
