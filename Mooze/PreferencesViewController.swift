import Cocoa

class PreferencesViewController: NSViewController {

    @IBOutlet var toggleMuteMicroPhoneOnLeftClickCheckBox: NSButtonCell!
    @IBAction func toggleMuteMicrophoneOnLeftClick(_ sender: NSButton) {
        switch sender.state {
        case .on:
            print("on")
            UserDefaults.standard.set(true, forKey: "ToggleMuteMicrophoneOnStatusBarIconLeftClick")
        case .off:
            print("off")
            UserDefaults.standard.set(false, forKey: "ToggleMuteMicrophoneOnStatusBarIconLeftClick")
        default: break
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        let toggleMuteOnLeftClick = UserDefaults.standard.bool(forKey: "ToggleMuteMicrophoneOnStatusBarIconLeftClick")
        toggleMuteMicroPhoneOnLeftClickCheckBox.state = toggleMuteOnLeftClick ? .on : .off
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    override func viewWillAppear() {
        view.window?.styleMask.remove(.resizable)
        view.window?.styleMask.remove(.miniaturizable)
        view.window?.center()
    }
}
