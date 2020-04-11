import AMCoreAudio

public class AudioHelper {
    static func isEveryInputDeviceMuted() -> Bool {
        var devicesMuteStatuses: [Bool] = []
        
        for device in AudioDevice.allInputDevices() {
            let isMuted = device.isMuted(channel: UInt32(0), direction: .recording) ?? false
            devicesMuteStatuses.append(isMuted)
        }

        return !devicesMuteStatuses.contains(false)
    }
    
    static func muteMicrophones() {
        for device in AudioDevice.allInputDevices() {
            if device.setMute(true, channel: UInt32(0), direction: .recording) == false {
                print("ERROR: Unable to mute \(device.id)")
            }
        }
    }

    static func unmuteMicrophones() {
        for device in AudioDevice.allInputDevices() {
            if device.setMute(false, channel: UInt32(0), direction: .recording) == false {
                print("ERROR: Unable to unmute \(device.id)")
            }
        }
    }
}
