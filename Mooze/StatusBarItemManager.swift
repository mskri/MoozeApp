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
        guard let preferencesViewController =
            storyboard.instantiateController(withIdentifier: .init(stringLiteral: "preferencesID")) as?
            PreferencesViewController else { return }

        let window = NSWindow(contentViewController: preferencesViewController)
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
    }

    let statusBarButton: NSStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    var microphoneMutedStatusObserver: NSKeyValueObservation?

    override func awakeFromNib() {
        super.awakeFromNib()

        let isDefaultInputDeviceMuted = AudioHelper.isDefaultInputDeviceMuted()

        print("On app startup default input device is muted: \(isDefaultInputDeviceMuted)")
        State.shared.isMicrophoneMuted = isDefaultInputDeviceMuted

        microphoneMutedStatusObserver = State.shared.observe(\.isMicrophoneMuted, options: .new) { _, change in
            let isMuted = change.newValue ?? false
            print("observed value for microphoneMuted: \(isMuted)")
            self.setMicrophoneMuteState(isMuted: isMuted)
        }

        initNotificationCenterListeners()
        initStatusBarButton(isDefaultInputDeviceMuted)
        initGlobalHotKeys()
    }

    deinit {
        microphoneMutedStatusObserver?.invalidate()
    }

    func initNotificationCenterListeners() {
        NotificationCenter.defaultCenter.subscribe(
            self,
            eventType: AudioHardwareEvent.self,
            dispatchQueue: DispatchQueue.main
        )

        NotificationCenter.defaultCenter.subscribe(self,
            eventType: AudioDeviceEvent.self,
            dispatchQueue: DispatchQueue.main
        )

        NotificationCenter.defaultCenter.subscribe(
            self,
            eventType: AudioStreamEvent.self,
            dispatchQueue: DispatchQueue.main
        )
    }

    func initStatusBarButton(_ mutedIcon: Bool) {
//        statusBarButton.menu = menu

        if let button = statusBarButton.button {
            button.image = NSImage(named: mutedIcon ? "microphone-off" : "microphone-on")
            button.target = self
            button.action = #selector(self.statusBarIconClicked(sender:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    // TODO: allow setting preferred key combo
    func initGlobalHotKeys() {
        // after registering the key, another key with same identifie has to be unregistered first before7
        // the new one will become active
        // HotKeyCenter.shared.unregisterAll()
        let carbonModifiers = cmdKey + controlKey + optionKey
        if let keyCombo = KeyCombo(keyCode: kVK_ANSI_M, carbonModifiers: carbonModifiers) {
            let hotKey = HotKey(
                identifier: "CommandOptionControlM",
                keyCombo: keyCombo,
                target: self,
                action: #selector(toggleMicrophoneMute)
            )
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

    @objc func statusBarIconClicked(sender: NSStatusItem) {
        let event = NSApp.currentEvent!
        let toggleMuteOnLeftClick = UserDefaults.standard.bool(forKey: "ToggleMuteMicrophoneOnStatusBarIconLeftClick")

        if event.type == NSEvent.EventType.rightMouseUp {
            if toggleMuteOnLeftClick {
                openMenu()
            } else {
                toggleMicrophoneMute()
            }
        } else {
            if !toggleMuteOnLeftClick {
                openMenu()
            } else {
                toggleMicrophoneMute()
            }
        }
    }

    @objc func openMenu() {
        if let button = statusBarButton.button {
            // TODO: why doesn't detecting left/right clicks on NSStatusItem work if `.menu = menu` is set?
            // For now set the menu to nil after showing it so we get right clicks too
            statusBarButton.menu = menu
            button.performClick(nil)
            statusBarButton.menu = nil
        }
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

                let volume = audioDevice.volume(channel: channel, direction: .recording) ?? 1

                if volume > 0 && State.shared.isMicrophoneMuted {
                    // Resets mic muted state in app when user changes input volume in system preferences
                    State.shared.isMicrophoneMuted = false
                } else if volume == 0 {
                    // Updates icon and sets app state correctly when user sets input volume to 0 in system preferences
                    State.shared.isMicrophoneMuted = true
                }
            case .muteDidChange(let audioDevice, let channel, let direction):
                if direction == .playback {
                    return
                }
                print("\(audioDevice.id) mute did change")
            default:
                break
            }
        case let event as AudioHardwareEvent:
            switch event {
            case .deviceListChanged:
                print("Device list changed")
            case let .defaultInputDeviceChanged(audioDevice):
                print("Default input device changed to \(audioDevice)")
                audioDevice.setMute(State.shared.isMicrophoneMuted, channel: UInt32(0), direction: .recording)
            default:
                break
            }
        default:
            break
        }
    }
}
