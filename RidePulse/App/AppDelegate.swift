#if os(iOS)
import UIKit
#if canImport(GoogleMaps)
import GoogleMaps
#endif

/// Bridges Google Maps SDK initialization for SwiftUI lifecycle apps.
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
#if canImport(GoogleMaps)
        let apiKey = ProcessInfo.processInfo.environment["GOOGLE_MAPS_API_KEY"] ?? "<#INSERT_GOOGLE_MAPS_API_KEY#>"
        GMSServices.provideAPIKey(apiKey)
#endif
        return true
    }
}
#endif


