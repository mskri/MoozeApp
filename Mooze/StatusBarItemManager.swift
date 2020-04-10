import Foundation
import Cocoa
import AMCoreAudio
import Magnet
import Carbon

class StatusBarItemManager: NSObject {
    var statusBarItem: NSStatusItem?
    var popover: NSPopover?
    var popoverVC: PopoverViewController?
    
    // TODO: this should be determined by checking if there are
    // input devices with microphone open when app starts
    var micsMuted = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
     
        initStatusBarItem()
        initPopover()
        initNotificationCenterListeners()
        initGlobalHotKeys()
    }
    
    fileprivate func initNotificationCenterListeners() {
        NotificationCenter.defaultCenter.subscribe(self, eventType: AudioHardwareEvent.self, dispatchQueue: DispatchQueue.main)
        NotificationCenter.defaultCenter.subscribe(self, eventType: AudioDeviceEvent.self, dispatchQueue: DispatchQueue.main)
        NotificationCenter.defaultCenter.subscribe(self, eventType: AudioStreamEvent.self, dispatchQueue: DispatchQueue.main)
               
    }
    
    fileprivate func initStatusBarItem() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusBarItem?.button {
            button.image = NSImage(named: "microphone-off")
            button.target = self
            button.action = #selector(showPopoverVC)
        }
    }
    
    
    @objc func toggleMute() {
        if micsMuted {
            print("unmute")
            AudioHelper.unmuteAllInputDevices()
            toggleStatusBarIcon(muted: false)
            micsMuted = false
        } else {
            print("mute")
            AudioHelper.muteAllInputDevices()
            toggleStatusBarIcon(muted: true)
            micsMuted = true
        }
    }
    
    // TODO: icon should be changed based on the events + checking that all devices are muted
    fileprivate func toggleStatusBarIcon(muted: Bool) {
        if let button = statusBarItem?.button {
            if muted {
                button.image = NSImage(named: "microphone-off")
            } else {
                button.image = NSImage(named: "microphone-on")
            }
        }
    }
    
    fileprivate func initPopover() {
        popover = NSPopover()
        popover?.behavior = .transient
    }
    
    fileprivate func initGlobalHotKeys() {
        // after registering the key, another key with same identifie has to be unregistered first before7
        // the new one will become active
        // HotKeyCenter.shared.unregisterAll()
        let carbonModifiers = cmdKey + controlKey + optionKey
        print(carbonModifiers)
        if let keyCombo = KeyCombo(keyCode: kVK_ANSI_M, carbonModifiers: carbonModifiers) {
            let hotKey = HotKey(identifier: "CommandOptionControlM", keyCombo: keyCombo, target: self, action: #selector(toggleMute))
            hotKey.register() // or HotKeyCenter.shared.register(with: hotKey)
          }
    }
    
    @objc fileprivate func showPopoverVC() {
        guard let popover = popover, let button = statusBarItem?.button else { return }
        
        if popoverVC == nil {
            let storyboard = NSStoryboard(name: "Main", bundle: nil)
            guard let vc = storyboard.instantiateController(withIdentifier: .init(stringLiteral: "popoverID")) as? PopoverViewController else { return }
            popoverVC = vc
        }
        
        popover.contentViewController = popoverVC
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }
}

// TODO: when new device is added it should be muted automatically if mute is enabled
extension StatusBarItemManager: EventSubscriber {
    func eventReceiver(_ event: Event) {
        print(event)
    }
}

