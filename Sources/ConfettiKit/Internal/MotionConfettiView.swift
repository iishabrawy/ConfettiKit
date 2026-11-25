import Lottie
import RiveRuntime
import UIKit

/// Falling Lottie and Rive views. These cannot live in `CAEmitterLayer`.
final class MotionConfettiView: UIView {
    private static let maxPerSpawn = 20
    private static let maxLiveViews = 40
    private static let gravity: CGFloat = 920

    var configuration = ConfettiConfiguration()

    private var pieces: [Piece] = []
    private var link: CADisplayLink?
    private var lastTime: CFTimeInterval = 0
    private var rainTimer: Timer?

    /// Parsed Lottie JSON keyed by its bytes, so a burst parses each file once.
    private var lottieAnimations: [Data: LottieAnimation] = [:]
    /// Bytes of Rive files read from disk, so a burst reads each file once.
    private var riveFileData: [URL: Data] = [:]

    // MARK: - Types

    /// A created view plus whatever must stay alive with it.
    private struct Asset {
        let view: UIView
        let owner: AnyObject?
    }

    private final class Piece {
        let view: UIView
        let owner: AnyObject?
        var x: CGFloat
        var y: CGFloat
        var vx: CGFloat
        var vy: CGFloat
        var rotation: CGFloat
        var spin: CGFloat
        var life: TimeInterval = 0
        let maxLife: TimeInterval

        init(asset: Asset, x: CGFloat, y: CGFloat, vx: CGFloat, vy: CGFloat, spin: CGFloat, maxLife: TimeInterval) {
            self.view = asset.view
            self.owner = asset.owner
            self.x = x
            self.y = y
            self.vx = vx
            self.vy = vy
            self.rotation = CGFloat.random(in: -.pi ... .pi)
            self.spin = spin
            self.maxLife = maxLife
        }

        func tearDown() {
            (view as? LottieAnimationView)?.stop()
            (owner as? RiveViewModel)?.stop()
            view.removeFromSuperview()
        }
    }

    /// Keeps the display link from retaining the view, so the view can deallocate.
    @MainActor
    private final class DisplayLinkProxy: NSObject {
        weak var target: MotionConfettiView?

        init(target: MotionConfettiView) {
            self.target = target
            super.init()
        }

        @objc func tick(_ link: CADisplayLink) {
            guard let target else {
                link.invalidate()
                return
            }
            target.advance(link)
        }
    }

    // MARK: - Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Control

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
            let timer = Timer(timeInterval: 0.45, repeats: true) { [weak self] timer in
                guard let self else {
                    timer.invalidate()
                    return
                }
                MainActor.assumeIsolated { self.spawn(scale: 0.2) }
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
        pieces.forEach { $0.tearDown() }
        pieces.removeAll()
        lottieAnimations.removeAll()
        riveFileData.removeAll()
    }

    // MARK: - Spawning

    private func spawn(scale: CGFloat) {
        let budget = configuration.budgets()
        var lottieCount = min(Self.maxPerSpawn, Int((CGFloat(budget.lottie) * scale).rounded(.up)))
        var riveCount = min(Self.maxPerSpawn, Int((CGFloat(budget.rive) * scale).rounded(.up)))
        guard lottieCount + riveCount > 0, bounds.width > 1 else { return }

        let available = max(0, Self.maxLiveViews - pieces.count)
        lottieCount = min(lottieCount, available)
        riveCount = min(riveCount, available - lottieCount)

        for index in 0..<lottieCount {
            let item = configuration.lotties[index % configuration.lotties.count]
            guard let asset = makeLottie(item) else { continue }
            add(asset)
        }
        for index in 0..<riveCount {
            let item = configuration.rives[index % configuration.rives.count]
            guard let asset = makeRive(item) else { continue }
            add(asset)
        }
    }

    private func add(_ asset: Asset) {
        let view = asset.view
        let side = max(configuration.particleSize * 3.2, 40)
        view.bounds = CGRect(x: 0, y: 0, width: side, height: side)
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        addSubview(view)

        let start = launch()
        let piece = Piece(
            asset: asset,
            x: start.x,
            y: start.y,
            vx: start.vx,
            vy: start.vy,
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

    // MARK: - Animation loop

    private func startLink() {
        guard link == nil else { return }
        lastTime = CACurrentMediaTime()
        let proxy = DisplayLinkProxy(target: self)
        let link = CADisplayLink(target: proxy, selector: #selector(DisplayLinkProxy.tick(_:)))
        link.add(to: .main, forMode: .common)
        self.link = link
    }

    private func advance(_ link: CADisplayLink) {
        let now = link.timestamp
        let dt = min(0.032, now - lastTime)
        lastTime = now

        var write = 0
        for read in pieces.indices {
            let piece = pieces[read]
            guard update(piece, dt: dt) else {
                piece.tearDown()
                continue
            }
            pieces[write] = piece
            write += 1
        }
        pieces.removeSubrange(write...)

        if pieces.isEmpty && rainTimer == nil {
            self.link?.invalidate()
            self.link = nil
        }
    }

    /// Moves one piece forward. Returns `false` when the piece is finished.
    private func update(_ piece: Piece, dt: TimeInterval) -> Bool {
        piece.life += dt
        if piece.life >= piece.maxLife || piece.y > bounds.height + 80 {
            return false
        }
        piece.vy += Self.gravity * dt
        piece.x += piece.vx * dt
        piece.y += piece.vy * dt
        piece.rotation += piece.spin * dt
        let fade = piece.life / piece.maxLife
        piece.view.center = CGPoint(x: piece.x, y: piece.y)
        piece.view.transform = CGAffineTransform(rotationAngle: piece.rotation)
        piece.view.alpha = fade > 0.78 ? CGFloat(max(0, 1 - (fade - 0.78) / 0.22)) : 1
        return true
    }

    // MARK: - Lottie

    private func makeLottie(_ item: ConfettiLottie) -> Asset? {
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
            guard let animation = lottieAnimation(from: data) else { return nil }
            view = LottieAnimationView(animation: animation)
        }
        view.loopMode = .loop
        view.contentMode = .scaleAspectFit
        view.backgroundBehavior = .pauseAndRestore
        view.play()
        return Asset(view: view, owner: nil)
    }

    private func lottieAnimation(from data: Data) -> LottieAnimation? {
        if let cached = lottieAnimations[data] { return cached }
        guard let animation = try? LottieAnimation.from(data: data) else { return nil }
        lottieAnimations[data] = animation
        return animation
    }

    // MARK: - Rive

    private func makeRive(_ item: ConfettiRive) -> Asset? {
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
                guard let data = riveData(at: url) else { return nil }
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

    private func riveData(at url: URL) -> Data? {
        if let cached = riveFileData[url] { return cached }
        guard let data = try? Data(contentsOf: url) else { return nil }
        riveFileData[url] = data
        return data
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

    private func riveView(data: Data, playback: ConfettiRive.Playback) -> Asset? {
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

    /// Creates the Rive view, applies inputs, and keeps the view model alive with the piece.
    private func finish(_ model: RiveViewModel, inputs: [ConfettiRiveInput]) -> Asset {
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
        return Asset(view: view, owner: model)
    }

    private func fileParts(_ name: String, fallback: String) -> (name: String, ext: String) {
        let ns = name as NSString
        let ext = ns.pathExtension
        if ext.isEmpty { return (name, fallback) }
        return (ns.deletingPathExtension, "." + ext)
    }
}
