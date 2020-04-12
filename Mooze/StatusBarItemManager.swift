import Foundation
import Cocoa
import AMCoreAudio
import Magnet
import Carbon

// TODO: when app quits, unmute?

class StatusBarItemManager: NSObject {
    @IBOutlet weak var menu: NSMenu?
    @IBOutlet weak var toggleMuteMenuItem: NSMenuItem!

    @IBAction func toggleMenuBarItemAction(_ sender: Any) {
        toggleMicrophoneMute()
    }
    
    @IBAction func showPreferences(_ sender: Any) {
           let storyboard = NSStoryboard(name: "Main", bundle: nil)
           guard let vc = storyboard.instantiateController(withIdentifier: .init(stringLiteral: "preferencesID")) as? PreferencesViewController else { return }
           
           let window = NSWindow(contentViewController: vc)
           window.makeKeyAndOrderFront(nil)
       }

    let statusBarButton: NSStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    var popover: NSPopover?
    var microphoneMutedStatusObserver: NSKeyValueObservation?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let isEveryInputDeviceMuted = AudioHelper.isEveryInputDeviceMuted()
        print("On app startup all input devices are muted: \(isEveryInputDeviceMuted)")
        State.shared.isMicrophoneMuted = isEveryInputDeviceMuted
        
        microphoneMutedStatusObserver = State.shared.observe(\.isMicrophoneMuted, options: .new) { _, change in
            let isMuted = change.newValue ?? false
            print("observed value for microphoneMuted: \(isMuted)")
            self.setMicrophoneMuteState(isMuted: isMuted)
        }
        
        initNotificationCenterListeners()
        initStatusBarButton(isEveryInputDeviceMuted)
        initPopover()
        initGlobalHotKeys()
    }
    
    deinit {
        microphoneMutedStatusObserver?.invalidate()
    }
    
    func initNotificationCenterListeners() {
        NotificationCenter.defaultCenter.subscribe(self, eventType: AudioHardwareEvent.self, dispatchQueue: DispatchQueue.main)
        NotificationCenter.defaultCenter.subscribe(self, eventType: AudioDeviceEvent.self, dispatchQueue: DispatchQueue.main)
        NotificationCenter.defaultCenter.subscribe(self, eventType: AudioStreamEvent.self, dispatchQueue: DispatchQueue.main)
    }
    
    func initStatusBarButton(_ mutedIcon: Bool) {
        statusBarButton.menu = menu

        if let button = statusBarButton.button {
            button.image = NSImage(named: mutedIcon ? "microphone-off" : "microphone-on")
            button.target = self
        }
    }
    
    func initPopover() {
        popover = NSPopover()
        popover?.behavior = .transient
    }
    
    // TODO: allow setting preferred key combo
    func initGlobalHotKeys() {
        // after registering the key, another key with same identifie has to be unregistered first before7
        // the new one will become active
        // HotKeyCenter.shared.unregisterAll()
        let carbonModifiers = cmdKey + controlKey + optionKey
        if let keyCombo = KeyCombo(keyCode: kVK_ANSI_M, carbonModifiers: carbonModifiers) {
            let hotKey = HotKey(identifier: "CommandOptionControlM", keyCombo: keyCombo, target: self, action: #selector(toggleMicrophoneMute))
            hotKey.register() // or HotKeyCenter.shared.register(with: hotKey)
          }
    }
    
    func setMicrophoneMuteState(isMuted: Bool) {
        if isMuted {
            toggleMuteMenuItem.title = "Unmute microphone"
            setStatusBarIcon(status: .muted)
            AudioHelper.muteMicrophones()
        } else {
            toggleMuteMenuItem.title = "Mute microphone"
            setStatusBarIcon(status: .notmuted)
            AudioHelper.unmuteMicrophones()
        }
    }
    
    enum StatusBarIcon {
        case muted
        case notmuted
    }
    
    func setStatusBarIcon(status: StatusBarIcon) {
        if let button = statusBarButton.button {
            switch status {
            case .muted:
                button.image = NSImage(named: "microphone-off")
            case .notmuted:
                button.image = NSImage(named: "microphone-on")
            }
        }
    }
    
    @objc func toggleMicrophoneMute() {
        State.shared.toggleMicrophoneMute()
    }
}

// TODO: when new device is added it should be muted automatically if mute is enabled
extension StatusBarItemManager: EventSubscriber {
    func eventReceiver(_ event: Event) {
        print(event)
    
        switch event {
        case let event as AudioDeviceEvent:
            switch event {
            case let .listDidChange(audioDevice):
                print("listDidChange \(audioDevice)")
            case .volumeDidChange(let audioDevice, let channel, let direction):
                if direction == .playback {
                    return
                }
                // TODO: should unmute the devices? If user changes input volume in preferences this is triggered
                // muteDidChange == input volume was set to 0
                let volume = audioDevice.volume(channel: channel, direction: .recording) ?? 1
                
                if volume > 0 && State.shared.isMicrophoneMuted {
                    // Resets mic muted state in app when user changes input volume in system preferences
                    State.shared.isMicrophoneMuted = false
                } else if volume == 0 {
                    // Updates icon and sets app state correctly when user sets input volume to 0 in system preferences
                    State.shared.isMicrophoneMuted = true
                }
//            case .muteDidChange(let audioDevice, let channel, let direction):
//                if direction == .playback {
//                    return
//                }
            default:
                break
            }
        case let event as AudioHardwareEvent:
            switch event {
            case .deviceListChanged:
                print("deviceListChanged")
                // Mute all devices when new one is added and the mute status is true
                if !State.shared.isMicrophoneMuted {
                    print("mute all inputs because of new device")
                    State.shared.isMicrophoneMuted = true
                }
            default:
                break
            }
        default:
            break
        }
    }
}
