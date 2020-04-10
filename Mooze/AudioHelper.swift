import Foundation
import AMCoreAudio

public class AudioHelper {
    static func muteAllInputDevices() {
        for device in AudioDevice.allInputDevices() {
            let channel = UInt32(0)
            let direction = Direction.recording
            if device.setMute(true, channel: channel, direction: direction) == false {
                print("Unable to update mute state for channel \(channel) and direction \(direction)")
            }
        }
    }

    static func unmuteAllInputDevices() {
        for device in AudioDevice.allInputDevices() {
            let channel = UInt32(0)
            let direction = Direction.recording
            if device.setMute(false, channel: channel, direction: direction) == false {
                print("Unable to update mute state for channel \(channel) and direction \(direction)")
            }
        }
    }
}
