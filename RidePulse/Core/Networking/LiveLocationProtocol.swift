import Foundation
import CoreLocation

struct LiveLocationMessage: Codable {
    let type: String = "location"
    let roomId: String
    let riderId: String
    let lat: Double
    let lng: Double
    let heading: Double?
    let speed: Double?
    let ts: Double
}

enum LiveLocationProtocol {
    static func encode(roomId: String, riderId: String, location: CLLocation) throws -> Data {
        let message = LiveLocationMessage(
            roomId: roomId,
            riderId: riderId,
            lat: location.coordinate.latitude,
            lng: location.coordinate.longitude,
            heading: location.course >= 0 ? location.course : nil,
            speed: location.speed >= 0 ? location.speed : nil,
            ts: location.timestamp.timeIntervalSince1970
        )
        return try JSONEncoder().encode(message)
    }

    static func decode(_ data: Data) throws -> RiderLocation {
        let message = try JSONDecoder().decode(LiveLocationMessage.self, from: data)
        return RiderLocation(
            id: UUID().uuidString,
            riderId: message.riderId,
            coordinate: CLLocationCoordinate2D(latitude: message.lat, longitude: message.lng),
            speed: message.speed,
            heading: message.heading,
            timestamp: Date(timeIntervalSince1970: message.ts)
        )
    }
}

