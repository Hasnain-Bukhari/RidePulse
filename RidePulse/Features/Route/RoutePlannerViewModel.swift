import Foundation
import CoreLocation
import Combine

@MainActor
final class RoutePlannerViewModel: ObservableObject {
    @Published var plan: RoutePlan
    @Published var isLeader: Bool = true

    init(plan: RoutePlan = .sample()) {
        self.plan = plan
    }

    func updateStart(name: String) {
        plan.start = RouteStop(id: plan.start.id, name: name, coordinate: plan.start.coordinate)
        plan.updatedAt = Date()
    }

    func updateDestination(name: String) {
        plan.destination = RouteStop(id: plan.destination.id, name: name, coordinate: plan.destination.coordinate)
        plan.updatedAt = Date()
    }

    func addStop(name: String, coordinate: CLLocationCoordinate2D) {
        plan.stops.append(RouteStop(name: name, coordinate: coordinate))
        plan.updatedAt = Date()
    }

    func removeStop(_ stop: RouteStop) {
        plan.stops.removeAll { $0.id == stop.id }
        plan.updatedAt = Date()
    }

    func applyRemote(_ remote: RoutePlan) {
        plan = remote
    }

    func encodedRoute(roomId: String) -> Data? {
        try? RouteShareProtocol.encode(roomId: roomId, plan: plan)
    }
}

