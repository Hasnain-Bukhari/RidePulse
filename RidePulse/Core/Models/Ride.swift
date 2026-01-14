import Foundation

struct Ride: Identifiable, Hashable {
    enum Status: String {
        case searchingDriver
        case driverEnRoute
        case driverArrived
        case inProgress
        case completed
        case cancelled
    }

    let id: UUID
    let rider: Rider
    let pickup: String
    let dropoff: String
    let status: Status
    let etaMinutes: Int?
    let channelID: String

    static let sample: Ride = .init(
        id: UUID(),
        rider: Rider.sample,
        pickup: "1 Infinite Loop, Cupertino",
        dropoff: "1600 Amphitheatre Pkwy, Mountain View",
        status: .driverEnRoute,
        etaMinutes: 6,
        channelID: UUID().uuidString
    )
}


