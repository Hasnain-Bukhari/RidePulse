import Foundation

struct Rider: Identifiable, Hashable {
    let id: UUID
    let name: String
    let phone: String

    static let sample = Rider(
        id: UUID(),
        name: "Taylor Swift",
        phone: "+1 (555) 123-4567"
    )
}


