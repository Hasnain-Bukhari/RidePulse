import Foundation

struct Message: Identifiable, Hashable {
    enum Sender: String {
        case rider
        case driver
        case system
    }

    let id: UUID
    let sender: Sender
    let body: String
    let timestamp: Date

    static func system(_ body: String, at date: Date = .init()) -> Message {
        Message(id: UUID(), sender: .system, body: body, timestamp: date)
    }
}

