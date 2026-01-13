#if os(iOS)
import Foundation
import CoreLocation
import AVFoundation
import SwiftUI
import Combine

@MainActor
final class AppPermissions: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
    }

    func activate() async {
        configureAudioSession()
        requestMicrophone()
        requestLocationAlways()
        startBackgroundLocationUpdates()
        AudioSessionConfig.startInterruptionHandling()
    }

    func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .active:
            configureAudioSession()
            startBackgroundLocationUpdates()
        case .background:
            startBackgroundLocationUpdates()
            try? AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
        case .inactive:
            break
        @unknown default:
            break
        }
    }

    private func configureAudioSession() {
        try? AudioSessionConfig.configure()
    }

    private func requestMicrophone() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if !granted {
                print("Microphone permission denied.")
            }
        }
    }

    private func requestLocationAlways() {
        locationManager.requestWhenInUseAuthorization()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.locationManager.requestAlwaysAuthorization()
        }
    }

    private func startBackgroundLocationUpdates() {
        let status = locationManager.authorizationStatus
        guard status == .authorizedAlways || status == .authorizedWhenInUse else { return }
        locationManager.startUpdatingLocation()
        locationManager.startMonitoringSignificantLocationChanges()
    }
}

extension AppPermissions: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            startBackgroundLocationUpdates()
        case .denied, .restricted:
            print("Location permission denied or restricted.")
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location updates failed: \(error)")
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Hook for consuming location updates.
    }
}
#else
import Foundation
import Combine
import SwiftUI

@MainActor
final class AppPermissions: ObservableObject {
    func activate() async {
        // macOS stub: nothing to request.
    }
}
#endif

