#if os(iOS)
import AVFoundation

enum AudioSessionConfig {
    static func configure() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(
            .playAndRecord,
            mode: .voiceChat,
            options: [
                .duckOthers,
                .interruptSpokenAudioAndMixWithOthers,
                .defaultToSpeaker,
                .allowBluetooth,
                .allowBluetoothA2DP
            ]
        )
        try session.setActive(true, options: .notifyOthersOnDeactivation)
        try session.setPreferredSampleRate(48_000)
        try session.setPreferredIOBufferDuration(0.01)
    }

    static func startInterruptionHandling() {
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { notification in
            guard
                let info = notification.userInfo,
                let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
                let type = AVAudioSession.InterruptionType(rawValue: typeValue)
            else { return }

            switch type {
            case .began:
                break
            case .ended:
                try? AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
            @unknown default:
                break
            }
        }
    }
}
#endif


