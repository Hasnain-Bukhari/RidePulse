import Foundation
import CoreLocation

struct RiderLocation: Identifiable, Hashable, Equatable {
    let id: String
    let riderId: String
    let coordinate: CLLocationCoordinate2D
    let speed: Double?
    let heading: Double?
    let timestamp: Date

    static func sample(
        id: String = UUID().uuidString,
        riderId: String = "rider-\(Int.random(in: 100...999))",
        lat: Double = 37.3349,
        lng: Double = -122.0090,
        speed: Double? = Double.random(in: 4...12),
        heading: Double? = Double.random(in: 0..<360),
        timestamp: Date = .init()
    ) -> RiderLocation {
        RiderLocation(
            id: id,
            riderId: riderId,
            coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng),
            speed: speed,
            heading: heading,
            timestamp: timestamp
        )
    }
}

// MARK: - Equatable / Hashable

extension RiderLocation {
    static func == (lhs: RiderLocation, rhs: RiderLocation) -> Bool {
        lhs.id == rhs.id &&
        lhs.riderId == rhs.riderId &&
        lhs.coordinate.latitude == rhs.coordinate.latitude &&
        lhs.coordinate.longitude == rhs.coordinate.longitude &&
        lhs.speed == rhs.speed &&
        lhs.heading == rhs.heading &&
        lhs.timestamp == rhs.timestamp
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(riderId)
        hasher.combine(coordinate.latitude)
        hasher.combine(coordinate.longitude)
        hasher.combine(speed)
        hasher.combine(heading)
        hasher.combine(timestamp)
    }
}

