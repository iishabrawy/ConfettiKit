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
        emitter.stop()
        motion.stop()
    }
}
