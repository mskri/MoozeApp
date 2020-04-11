import Cocoa

class PopoverViewController: NSViewController {
    var microphoneMutedStatusObserver: NSKeyValueObservation?
    
    @IBOutlet weak var toggleMuteButton: NSButton!
    
    @IBAction func toggleMute(_ sender: Any) {
        print("toggleMute button in popover")
        State.shared.toggleMicrophoneMute()
        setMuteButtonTitle(isMuted: State.shared.isMicrophoneMuted)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        microphoneMutedStatusObserver = State.shared.observe(\.isMicrophoneMuted, options: .new) { _, change in
            let isMuted = change.newValue ?? false
            print("POPOVER: observed value for microphoneMuted: \(isMuted)")
            self.setMuteButtonTitle(isMuted: isMuted)
        }
        
        setMuteButtonTitle(isMuted: State.shared.isMicrophoneMuted)
    }
    
    deinit {
        microphoneMutedStatusObserver?.invalidate()
    }
    
    func setMuteButtonTitle(isMuted: Bool) {
        toggleMuteButton.title = isMuted ? "Unmute" : "Mute"
    }
}
