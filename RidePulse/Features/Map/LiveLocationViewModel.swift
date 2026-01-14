import Foundation
import CoreLocation
import Combine

@MainActor
final class LiveLocationViewModel: ObservableObject {
    @Published private(set) var riders: [RiderLocation] = []
    private var ridersMap: [String: RiderLocation] = [:]

    func applyRemoteUpdate(_ rider: RiderLocation) {
        ridersMap[rider.riderId] = rider
        riders = Array(ridersMap.values)
    }

    func pruneOlder(olderThan seconds: TimeInterval = 60) {
        let cutoff = Date().addingTimeInterval(-seconds)
        ridersMap = ridersMap.filter { $0.value.timestamp >= cutoff }
        riders = Array(ridersMap.values)
    }
}

