#if os(iOS)
import SwiftUI
import CoreLocation

#if canImport(GoogleMaps)
import GoogleMaps

struct GoogleMapsView: UIViewRepresentable {
    @Binding var lastKnownLocation: CLLocationCoordinate2D?

    func makeUIView(context: Context) -> GMSMapView {
        let camera = GMSCameraPosition.camera(
            withLatitude: lastKnownLocation?.latitude ?? 37.3349,
            longitude: lastKnownLocation?.longitude ?? -122.0090,
            zoom: 15
        )
        let mapView = GMSMapView(frame: .zero, camera: camera)
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
        mapView.settings.compassButton = true
        mapView.delegate = context.coordinator
        return mapView
    }

    func updateUIView(_ uiView: GMSMapView, context: Context) {
        guard let coordinate = lastKnownLocation else { return }
        let cameraUpdate = GMSCameraUpdate.setTarget(coordinate, zoom: uiView.camera.zoom)
        uiView.animate(with: cameraUpdate)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, GMSMapViewDelegate { }
}

#else
/// Fallback placeholder when GoogleMaps SDK is not linked.
struct GoogleMapsView: View {
    @Binding var lastKnownLocation: CLLocationCoordinate2D?

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "map")
                .font(.largeTitle)
            Text("Google Maps SDK not available. Add the GoogleMaps package to enable the map.")
                .multilineTextAlignment(.center)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
#endif
#endif

