import Lottie
import RiveRuntime
import UIKit

/// Falling Lottie and Rive views. These cannot live in `CAEmitterLayer`.
final class MotionConfettiView: UIView {
    var configuration = ConfettiConfiguration()
    private var pieces: [Piece] = []
    private var link: CADisplayLink?
    private var lastTime: CFTimeInterval = 0
    private var rainTimer: Timer?

    private final class Piece {
        let view: UIView
        var x: CGFloat
        var y: CGFloat
        var vx: CGFloat
        var vy: CGFloat
        var rotation: CGFloat
        var spin: CGFloat
        var life: TimeInterval = 0
        let maxLife: TimeInterval

        init(view: UIView, x: CGFloat, y: CGFloat, vx: CGFloat, vy: CGFloat, spin: CGFloat, maxLife: TimeInterval) {
            self.view = view
            self.x = x
            self.y = y
            self.vx = vx
            self.vy = vy
            self.rotation = CGFloat.random(in: -.pi ... .pi)
            self.spin = spin
            self.maxLife = maxLife
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func burst() {
        spawn(scale: 1)
        startLink()
    }

    func setContinuous(_ on: Bool) {
        rainTimer?.invalidate()
        rainTimer = nil
        if on {
            spawn(scale: 0.35)
            startLink()
            let timer = Timer(timeInterval: 0.45, repeats: true) { [weak self] _ in
                self?.spawn(scale: 0.2)
            }
            RunLoop.main.add(timer, forMode: .common)
            rainTimer = timer
        }
    }

    func stop() {
        rainTimer?.invalidate()
        rainTimer = nil
        link?.invalidate()
        link = nil
        pieces.forEach { $0.view.removeFromSuperview() }
        pieces.removeAll()
    }

    private func spawn(scale: CGFloat) {
        let budget = configuration.budgets()
        let lottieCount = min(20, Int((CGFloat(budget.lottie) * scale).rounded(.up)))
        let riveCount = min(20, Int((CGFloat(budget.rive) * scale).rounded(.up)))
        guard lottieCount + riveCount > 0, bounds.width > 1 else { return }

        for index in 0..<lottieCount {
            let item = configuration.lotties[index % configuration.lotties.count]
            guard let view = makeLottie(item) else { continue }
            add(view)
        }
        for index in 0..<riveCount {
            let item = configuration.rives[index % configuration.rives.count]
            guard let view = makeRive(item) else { continue }
            add(view)
        }
    }

    private func add(_ view: UIView) {
        let side = max(configuration.particleSize * 3.2, 40)
        view.bounds = CGRect(x: 0, y: 0, width: side, height: side)
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        addSubview(view)

        let speed = launch()
        let piece = Piece(
            view: view,
            x: speed.x,
            y: speed.y,
            vx: speed.vx,
            vy: speed.vy,
            spin: CGFloat.random(in: -2.2...2.2),
            maxLife: configuration.duration * Double.random(in: 0.85...1.2)
        )
        view.center = CGPoint(x: piece.x, y: piece.y)
        pieces.append(piece)
    }

    private func launch() -> (x: CGFloat, y: CGFloat, vx: CGFloat, vy: CGFloat) {
        let width = bounds.width
        let height = bounds.height
        switch configuration.emission {
        case .cannon:
            let angle = -CGFloat.pi / 2 + CGFloat.random(in: -0.7...0.7)
            let speed = CGFloat.random(in: 460...820)
            return (
                width * configuration.origin.x + CGFloat.random(in: -width * 0.12...width * 0.12),
                height * configuration.origin.y,
                cos(angle) * speed,
                sin(angle) * speed
            )
        case .rain:
            return (
                CGFloat.random(in: 0...width),
                CGFloat.random(in: -30...height * 0.5),
                CGFloat.random(in: -90...90),
                CGFloat.random(in: 30...160)
            )
        case .explosion:
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 180...520)
            return (
                width * configuration.origin.x,
                height * configuration.origin.y,
                cos(angle) * speed,
                sin(angle) * speed
            )
        case .fountain:
            let angle = -CGFloat.pi / 2 + CGFloat.random(in: -0.35...0.35)
            let speed = CGFloat.random(in: 560...860)
            return (
                width * configuration.origin.x,
                height * configuration.origin.y,
                cos(angle) * speed,
                sin(angle) * speed
            )
        }
    }

    private func startLink() {
        guard link == nil else { return }
        lastTime = CACurrentMediaTime()
        let link = CADisplayLink(target: self, selector: #selector(step))
        link.add(to: .main, forMode: .common)
        self.link = link
    }

    @objc private func step(_ link: CADisplayLink) {
        let now = link.timestamp
        let dt = min(0.032, now - lastTime)
        lastTime = now
        let gravity: CGFloat = 920
        var alive: [Piece] = []
        for piece in pieces {
            piece.life += dt
            if piece.life >= piece.maxLife || piece.y > bounds.height + 80 {
                piece.view.removeFromSuperview()
                continue
            }
            piece.vy += gravity * dt
            piece.x += piece.vx * dt
            piece.y += piece.vy * dt
            piece.rotation += piece.spin * dt
            let fade = piece.life / piece.maxLife
            piece.view.center = CGPoint(x: piece.x, y: piece.y)
            piece.view.transform = CGAffineTransform(rotationAngle: piece.rotation)
            piece.view.alpha = fade > 0.78 ? CGFloat(max(0, 1 - (fade - 0.78) / 0.22)) : 1
            alive.append(piece)
        }
        pieces = alive
        if pieces.isEmpty && rainTimer == nil {
            self.link?.invalidate()
            self.link = nil
        }
    }

    private func makeLottie(_ item: ConfettiLottie) -> LottieAnimationView? {
        let view: LottieAnimationView
        switch item.source {
        case .named(let name, let bundle):
            let base = (name as NSString).deletingPathExtension
            if name.lowercased().hasSuffix(".lottie") {
                view = LottieAnimationView(dotLottieName: base, bundle: bundle)
            } else {
                view = LottieAnimationView(name: base, bundle: bundle)
            }
        case .file(let url):
            if url.pathExtension.lowercased() == "lottie" {
                view = LottieAnimationView(
                    dotLottieFilePath: url.path,
                    animationId: nil,
                    dotLottieCache: nil,
                    configuration: .shared,
                    completion: { animationView, _ in
                        animationView.loopMode = .loop
                        animationView.play()
                    }
                )
            } else {
                view = LottieAnimationView(filePath: url.path)
            }
        case .data(let data):
            guard let animation = try? LottieAnimation.from(data: data) else { return nil }
            view = LottieAnimationView(animation: animation)
        }
        view.loopMode = .loop
        view.contentMode = .scaleAspectFit
        view.backgroundBehavior = .pauseAndRestore
        view.play()
        return view
    }

    private func makeRive(_ item: ConfettiRive) -> UIView? {
        let playback = item.nextPlayback()
        switch item.source {
        case .named(let name, let bundle):
            let parts = fileParts(name, fallback: ".riv")
            let model = riveModel(
                fileName: parts.name,
                ext: parts.ext,
                bundle: bundle,
                playback: playback
            )
            return finish(model, inputs: playback.inputs)
        case .url(let url):
            if url.isFileURL {
                guard let data = try? Data(contentsOf: url) else { return nil }
                return riveView(data: data, playback: playback)
            }
            let model: RiveViewModel
            if let stateMachine = playback.stateMachine {
                model = RiveViewModel(
                    webURL: url.absoluteString,
                    stateMachineName: stateMachine,
                    autoPlay: true,
                    artboardName: playback.artboard
                )
            } else {
                model = RiveViewModel(
                    webURL: url.absoluteString,
                    animationName: playback.animation,
                    autoPlay: true,
                    artboardName: playback.artboard
                )
            }
            return finish(model, inputs: playback.inputs)
        case .data(let data):
            return riveView(data: data, playback: playback)
        }
    }

    private func riveModel(
        fileName: String,
        ext: String,
        bundle: Bundle,
        playback: ConfettiRive.Playback
    ) -> RiveViewModel {
        if let stateMachine = playback.stateMachine {
            return RiveViewModel(
                fileName: fileName,
                extension: ext,
                in: bundle,
                stateMachineName: stateMachine,
                autoPlay: true,
                artboardName: playback.artboard
            )
        }
        return RiveViewModel(
            fileName: fileName,
            extension: ext,
            in: bundle,
            animationName: playback.animation,
            autoPlay: true,
            artboardName: playback.artboard
        )
    }

    private func riveView(data: Data, playback: ConfettiRive.Playback) -> UIView? {
        guard let file = try? RiveFile(data: data, loadCdn: false) else { return nil }
        let model = RiveModel(riveFile: file)
        let viewModel: RiveViewModel
        if let stateMachine = playback.stateMachine {
            viewModel = RiveViewModel(
                model,
                stateMachineName: stateMachine,
                artboardName: playback.artboard
            )
        } else {
            viewModel = RiveViewModel(
                model,
                animationName: playback.animation,
                artboardName: playback.artboard
            )
        }
        return finish(viewModel, inputs: playback.inputs)
    }

    private func finish(_ model: RiveViewModel, inputs: [ConfettiRiveInput]) -> UIView {
        let view = model.createRiveView()
        for input in inputs {
            switch input {
            case .bool(let name, let value):
                model.setInput(name, value: value)
            case .number(let name, let value):
                model.setInput(name, value: value)
            case .trigger(let name):
                model.triggerInput(name)
            }
        }
        return view
    }

    private func fileParts(_ name: String, fallback: String) -> (name: String, ext: String) {
        let ns = name as NSString
        let ext = ns.pathExtension
        if ext.isEmpty { return (name, fallback) }
        return (ns.deletingPathExtension, "." + ext)
    }
}
