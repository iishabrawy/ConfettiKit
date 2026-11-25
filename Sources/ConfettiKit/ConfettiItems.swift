import UIKit

/// One image in the `images` array. Asset name or a bitmap you already have.
public struct ConfettiImage {
    enum Source {
        case named(String)
        case image(UIImage)
    }

    let source: Source

    /// Asset catalog / bundle image. Not recolored.
    public static func named(_ name: String) -> ConfettiImage {
        ConfettiImage(source: .named(name))
    }

    /// Logo, sticker, or photo. Not recolored.
    public static func image(_ image: UIImage) -> ConfettiImage {
        ConfettiImage(source: .image(image))
    }
}

/// One Lottie file in the `lotties` array. JSON or dotLottie.
public struct ConfettiLottie {
    enum Source {
        case named(String, Bundle)
        case file(URL)
        case data(Data)
    }

    let source: Source

    /// `name` is the file in the app bundle, with or without `.json` / `.lottie`.
    public static func named(_ name: String, bundle: Bundle = .main) -> ConfettiLottie {
        ConfettiLottie(source: .named(name, bundle))
    }

    /// A Lottie JSON or `.lottie` file on disk.
    public static func file(_ url: URL) -> ConfettiLottie {
        ConfettiLottie(source: .file(url))
    }

    /// Raw Lottie JSON.
    public static func data(_ data: Data) -> ConfettiLottie {
        ConfettiLottie(source: .data(data))
    }
}

/// One input on a Rive state machine. These move the file between states.
public enum ConfettiRiveInput: Equatable, Sendable {
    case bool(String, Bool)
    case number(String, Double)
    case trigger(String)
}

/// One way to play a Rive file. Pass several and each piece picks one at random.
public enum ConfettiRiveState: Equatable, Sendable {
    /// A linear animation on the artboard.
    case animation(String)
    /// A state machine, plus the inputs that put it in a state.
    case machine(String, inputs: [ConfettiRiveInput] = [])
}

/// One Rive file in the `rives` array. `.riv` in the bundle, a URL, or bytes.
public struct ConfettiRive {
    enum Source {
        case named(String, Bundle)
        case url(URL)
        case data(Data)
    }

    struct Playback {
        var artboard: String?
        var animation: String?
        var stateMachine: String?
        var inputs: [ConfettiRiveInput]
    }

    let source: Source
    let artboard: String?
    let animation: String?
    let stateMachine: String?
    let inputs: [ConfettiRiveInput]
    let states: [ConfettiRiveState]

    /// `name` is the `.riv` in the app bundle, with or without the extension.
    ///
    /// Pass `states` to explore more than one. Each falling piece picks a state at random.
    public static func named(
        _ name: String,
        bundle: Bundle = .main,
        artboard: String? = nil,
        animation: String? = nil,
        stateMachine: String? = nil,
        inputs: [ConfettiRiveInput] = [],
        states: [ConfettiRiveState] = []
    ) -> ConfettiRive {
        make(
            source: .named(name, bundle),
            artboard: artboard,
            animation: animation,
            stateMachine: stateMachine,
            inputs: inputs,
            states: states
        )
    }

    /// A `.riv` file at a file URL or a remote URL.
    public static func url(
        _ url: URL,
        artboard: String? = nil,
        animation: String? = nil,
        stateMachine: String? = nil,
        inputs: [ConfettiRiveInput] = [],
        states: [ConfettiRiveState] = []
    ) -> ConfettiRive {
        make(
            source: .url(url),
            artboard: artboard,
            animation: animation,
            stateMachine: stateMachine,
            inputs: inputs,
            states: states
        )
    }

    /// The bytes of a `.riv` file.
    public static func data(
        _ data: Data,
        artboard: String? = nil,
        animation: String? = nil,
        stateMachine: String? = nil,
        inputs: [ConfettiRiveInput] = [],
        states: [ConfettiRiveState] = []
    ) -> ConfettiRive {
        make(
            source: .data(data),
            artboard: artboard,
            animation: animation,
            stateMachine: stateMachine,
            inputs: inputs,
            states: states
        )
    }

    private static func make(
        source: Source,
        artboard: String?,
        animation: String?,
        stateMachine: String?,
        inputs: [ConfettiRiveInput],
        states: [ConfettiRiveState]
    ) -> ConfettiRive {
        ConfettiRive(
            source: source,
            artboard: artboard,
            animation: animation,
            stateMachine: stateMachine,
            inputs: inputs,
            states: states
        )
    }

    /// One playback for a single piece. A non-empty `states` list wins, picked at random.
    func nextPlayback() -> Playback {
        if let state = states.randomElement() {
            switch state {
            case .animation(let name):
                return Playback(artboard: artboard, animation: name, stateMachine: nil, inputs: inputs)
            case .machine(let name, let stateInputs):
                return Playback(
                    artboard: artboard,
                    animation: nil,
                    stateMachine: name,
                    inputs: inputs + stateInputs
                )
            }
        }
        return Playback(
            artboard: artboard,
            animation: animation,
            stateMachine: stateMachine,
            inputs: inputs
        )
    }
}
