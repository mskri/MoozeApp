import Cocoa
import AMCoreAudio

class PopoverViewController: NSViewController {
    // TODO: buttons should also change status bar icon (via event listener5)

    @IBAction func muteMicrophone(_ sender: Any) {
        print("mute all input devices")
        AudioHelper.muteAllInputDevices()
    }
    
    @IBAction func unmuteMicrophone(_ sender: Any) {
        print("unmute all input devices")
        AudioHelper.unmuteAllInputDevices()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
}

