import Foundation
import CoreLocation

struct RouteStop: Identifiable, Codable, Hashable, Equatable {
    let id: String
    let name: String
    let coordinate: CLLocationCoordinate2D

    init(id: String = UUID().uuidString, name: String, coordinate: CLLocationCoordinate2D) {
        self.id = id
        self.name = name
        self.coordinate = coordinate
    }

    enum CodingKeys: String, CodingKey {
        case id, name, lat, lng
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        let lat = try c.decode(Double.self, forKey: .lat)
        let lng = try c.decode(Double.self, forKey: .lng)
        coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(coordinate.latitude, forKey: .lat)
        try c.encode(coordinate.longitude, forKey: .lng)
    }

    static func == (lhs: RouteStop, rhs: RouteStop) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.coordinate.latitude == rhs.coordinate.latitude &&
        lhs.coordinate.longitude == rhs.coordinate.longitude
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(coordinate.latitude)
        hasher.combine(coordinate.longitude)
    }
}

struct RoutePlan: Identifiable, Codable, Hashable, Equatable {
    let id: String
    var start: RouteStop
    var destination: RouteStop
    var stops: [RouteStop]
    var polyline: String?
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        start: RouteStop,
        destination: RouteStop,
        stops: [RouteStop] = [],
        polyline: String? = nil,
        updatedAt: Date = .init()
    ) {
        self.id = id
        self.start = start
        self.destination = destination
        self.stops = stops
        self.polyline = polyline
        self.updatedAt = updatedAt
    }

    static func sample() -> RoutePlan {
        let start = RouteStop(name: "Apple Park", coordinate: .init(latitude: 37.3349, longitude: -122.0090))
        let dest = RouteStop(name: "Googleplex", coordinate: .init(latitude: 37.4220, longitude: -122.0841))
        let stop = RouteStop(name: "Coffee Stop", coordinate: .init(latitude: 37.3861, longitude: -122.0839))
        return RoutePlan(start: start, destination: dest, stops: [stop])
    }
}

