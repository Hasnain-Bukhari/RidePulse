import Foundation
import SwiftUI
import Combine

@MainActor
final class RideDashboardViewModel: ObservableObject {
    @Published var ride: Ride
    @Published var liveRiders: [RiderLocation] = [
        RiderLocation.sample(riderId: "you", lat: 37.3349, lng: -122.0090),
        RiderLocation.sample(riderId: "driver", lat: 37.3355, lng: -122.0105)
    ]

    init(ride: Ride) {
        self.ride = ride
    }

    var statusText: String {
        switch ride.status {
        case .searchingDriver: return "Searching for a driver"
        case .driverEnRoute: return "Driver en route"
        case .driverArrived: return "Driver arrived"
        case .inProgress: return "Ride in progress"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }

    var etaText: String {
        if let eta = ride.etaMinutes {
            return "\(eta) min ETA"
        } else {
            return "ETA pending"
        }
    }
}

