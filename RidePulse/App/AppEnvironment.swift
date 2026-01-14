import SwiftUI

struct AppEnvironment {
    let messagingService: MessagingServicing
    let dateProvider: () -> Date

    static func live() -> AppEnvironment {
        // Replace URL with your WebSocket endpoint when wiring to backend.
        let baseURL = URL(string: "wss://example.com/realtime/ride")!
        return AppEnvironment(
            messagingService: MockMessagingService(),
            dateProvider: Date.init
        )
    }

    static func preview() -> AppEnvironment {
        AppEnvironment(
            messagingService: MockMessagingService(),
            dateProvider: Date.init
        )
    }
}

private struct AppEnvironmentKey: EnvironmentKey {
    static let defaultValue: AppEnvironment = .preview()
}

extension EnvironmentValues {
    var appEnvironment: AppEnvironment {
        get { self[AppEnvironmentKey.self] }
        set { self[AppEnvironmentKey.self] = newValue }
    }
}


