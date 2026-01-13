#if os(iOS)
import SwiftUI
import CoreLocation
import Combine

struct UserLocationMapView: View {
    @State private var coordinate: CLLocationCoordinate2D?
    @State private var speedKmh: Double = 0
    @State private var headingDegrees: Double?
    @StateObject private var locationReader = LocationReader()

    var body: some View {
        Group {
            if #available(iOS 13.0, *) {
                ZStack(alignment: .topLeading) {
                    GoogleMapsView(lastKnownLocation: $coordinate)
                        .frame(height: 280)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                    statsOverlay
                        .padding(12)
                }
            } else {
                Text("Google Maps requires iOS 13+")
            }
        }
        .onReceive(locationReader.$lastLocation) { location in
            coordinate = location?.coordinate
            if let location {
                speedKmh = max(location.speed, 0) * 3.6
            }
        }
        .onReceive(locationReader.$heading) { heading in
            headingDegrees = heading?.trueHeading ?? heading?.magneticHeading
        }
        .onAppear {
            locationReader.start()
        }
        .onDisappear {
            locationReader.stop()
        }
    }

    private var statsOverlay: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(String(format: "Speed: %.1f km/h", speedKmh))
                .font(.subheadline.bold())
            Text("Heading: \(headingLabel)")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var headingLabel: String {
        if let headingDegrees {
            return String(format: "%.0f°", headingDegrees)
        } else {
            return "—"
        }
    }
}

private final class LocationReader: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var lastLocation: CLLocation?
    @Published var heading: CLHeading?
    private let manager = CLLocationManager()
    private var lastEmission: Date?
    private let interval: TimeInterval = 5

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.pausesLocationUpdatesAutomatically = false
        manager.headingFilter = kCLHeadingFilterNone
    }

    func start() {
        manager.startUpdatingLocation()
        if CLLocationManager.headingAvailable() {
            manager.startUpdatingHeading()
        }
    }

    func stop() {
        manager.stopUpdatingLocation()
        manager.stopUpdatingHeading()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let now = Date()
        if let lastEmission, now.timeIntervalSince(lastEmission) < interval {
            return
        }
        lastEmission = now
        DispatchQueue.main.async {
            self.lastLocation = location
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        DispatchQueue.main.async {
            self.heading = newHeading
        }
    }
}
#endif

