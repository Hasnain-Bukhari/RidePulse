#if os(iOS)
import SwiftUI
import CoreLocation

#if canImport(GoogleMaps)
import GoogleMaps

struct LiveRidersMapView: UIViewRepresentable {
    @Binding var riders: [RiderLocation]

    func makeUIView(context: Context) -> GMSMapView {
        let camera = GMSCameraPosition(latitude: riders.first?.coordinate.latitude ?? 37.3349,
                                       longitude: riders.first?.coordinate.longitude ?? -122.0090,
                                       zoom: 14)
        let map = GMSMapView(frame: .zero, camera: camera)
        map.settings.compassButton = true
        map.settings.myLocationButton = true
        context.coordinator.mapView = map
        return map
    }

    func updateUIView(_ mapView: GMSMapView, context: Context) {
        context.coordinator.updateMarkers(riders: riders, on: mapView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        var markers: [String: GMSMarker] = [:]
        weak var mapView: GMSMapView?

        func updateMarkers(riders: [RiderLocation], on mapView: GMSMapView) {
            let riderIds = Set(riders.map { $0.riderId })
            // Remove stale
            for (id, marker) in markers where !riderIds.contains(id) {
                marker.map = nil
                markers.removeValue(forKey: id)
            }

            for rider in riders {
                let marker = markers[rider.riderId] ?? GMSMarker()
                marker.icon = GMSMarker.markerImage(with: .systemBlue)
                marker.title = rider.riderId
                if let speed = rider.speed {
                    marker.snippet = String(format: "Speed %.1f m/s", speed)
                }
                CATransaction.begin()
                CATransaction.setAnimationDuration(0.6)
                marker.position = rider.coordinate
                if let heading = rider.heading {
                    marker.rotation = heading
                }
                marker.map = mapView
                CATransaction.commit()
                markers[rider.riderId] = marker
            }
        }
    }
}

#else
struct LiveRidersMapView: View {
    @Binding var riders: [RiderLocation]
    var body: some View {
        VStack {
            Image(systemName: "map")
                .font(.largeTitle)
            Text("Google Maps SDK not available. Riders: \(riders.count)")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(height: 280)
        .frame(maxWidth: .infinity)
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
#endif
#endif

