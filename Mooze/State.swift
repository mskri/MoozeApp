import Cocoa

class State: NSObject {
    static let shared = State()

    @objc dynamic var isMicrophoneMuted: Bool = false

    private override init() {}

    func toggleMicrophoneMute() {
        isMicrophoneMuted = !isMicrophoneMuted
    }
}
