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

    static func isDefaultInputDeviceMuted() -> Bool {
        let device = AudioDevice.defaultInputDevice()
        let isMuted = device?.isMuted(channel: UInt32(0), direction: .recording) ?? false
        return isMuted
    }

    static func muteMicrophones() {
        let channel = UInt32(0)
        let defaultDevice = AudioDevice.defaultInputDevice()

        if defaultDevice?.setMute(true, channel: channel, direction: .recording) == false {
            print("ERROR: Unable to set mute default input device")
        }
    }

    static func unmuteMicrophones() {
        let channel = UInt32(0)
        let defaultDevice = AudioDevice.defaultInputDevice()

        if defaultDevice?.setMute(false, channel: channel, direction: .recording) == false {
            print("ERROR: Unable to set mute default input device")
        }
    }
}
