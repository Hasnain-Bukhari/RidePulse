import Foundation

struct OutgoingMessage {
    let sender: Message.Sender
    let body: String
    let timestamp: Date
}

protocol MessagingServicing {
    func connect(channelID: String) async -> AsyncThrowingStream<Message, Error>
    func send(_ message: OutgoingMessage, in channelID: String) async throws
    func disconnect(channelID: String)
}

