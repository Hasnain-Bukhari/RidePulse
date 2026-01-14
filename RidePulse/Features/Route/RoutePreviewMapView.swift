#if os(iOS)
import SwiftUI
import CoreLocation

#if canImport(GoogleMaps)
import GoogleMaps

struct RoutePreviewMapView: UIViewRepresentable {
    let plan: RoutePlan

    func makeUIView(context: Context) -> GMSMapView {
        let camera = GMSCameraPosition(latitude: plan.start.coordinate.latitude,
                                       longitude: plan.start.coordinate.longitude,
                                       zoom: 13)
        let map = GMSMapView(frame: .zero, camera: camera)
        map.settings.compassButton = true
        map.settings.myLocationButton = true
        return map
    }

    func updateUIView(_ mapView: GMSMapView, context: Context) {
        mapView.clear()
        let markers = [plan.start] + plan.stops + [plan.destination]
        for stop in markers {
            let marker = GMSMarker(position: stop.coordinate)
            marker.title = stop.name
            marker.map = mapView
        }
        if let polyline = plan.polyline, let path = GMSPath(fromEncodedPath: polyline) {
            let line = GMSPolyline(path: path)
            line.strokeWidth = 4
            line.strokeColor = .systemBlue
            line.map = mapView
            mapView.animate(with: GMSCameraUpdate.fit(GMSCoordinateBounds(path: path), withPadding: 32))
        } else {
            let coords = markers.map(\.coordinate)
            if let first = coords.first {
                var bounds = GMSCoordinateBounds(coordinate: first, coordinate: first)
                coords.forEach { bounds = bounds.includingCoordinate($0) }
                mapView.animate(with: GMSCameraUpdate.fit(bounds, withPadding: 32))
            }
        }
    }
}

#else
struct RoutePreviewMapView: View {
    let plan: RoutePlan
    var body: some View {
        VStack {
            Image(systemName: "map")
                .font(.largeTitle)
            Text("Google Maps not available. Showing \(plan.stops.count) stops.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
#endif
#endif

