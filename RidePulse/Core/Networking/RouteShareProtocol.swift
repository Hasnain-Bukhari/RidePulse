import Foundation
internal import _LocationEssentials

struct RouteShareMessage: Codable {
    let type: String = "route-set"
    let roomId: String
    let route: RoutePayload
}

struct RoutePayload: Codable {
    let id: String
    let start: RouteStopPayload
    let destination: RouteStopPayload
    let stops: [RouteStopPayload]
    let polyline: String?
    let updatedAt: Double
}

struct RouteStopPayload: Codable {
    let id: String
    let name: String
    let lat: Double
    let lng: Double
}

enum RouteShareProtocol {
    static func encode(roomId: String, plan: RoutePlan) throws -> Data {
        let payload = RoutePayload(
            id: plan.id,
            start: plan.start.payload,
            destination: plan.destination.payload,
            stops: plan.stops.map { $0.payload },
            polyline: plan.polyline,
            updatedAt: plan.updatedAt.timeIntervalSince1970
        )
        let message = RouteShareMessage(roomId: roomId, route: payload)
        return try JSONEncoder().encode(message)
    }

    static func decode(_ data: Data) throws -> RoutePlan {
        let message = try JSONDecoder().decode(RouteShareMessage.self, from: data)
        return message.route.toRoutePlan()
    }
}

private extension RouteStop {
    var payload: RouteStopPayload {
        RouteStopPayload(id: id, name: name, lat: coordinate.latitude, lng: coordinate.longitude)
    }
}

private extension RoutePayload {
    func toRoutePlan() -> RoutePlan {
        RoutePlan(
            id: id,
            start: start.toRouteStop(),
            destination: destination.toRouteStop(),
            stops: stops.map { $0.toRouteStop() },
            polyline: polyline,
            updatedAt: Date(timeIntervalSince1970: updatedAt)
        )
    }
}

private extension RouteStopPayload {
    func toRouteStop() -> RouteStop {
        RouteStop(id: id, name: name, coordinate: .init(latitude: lat, longitude: lng))
    }
}

