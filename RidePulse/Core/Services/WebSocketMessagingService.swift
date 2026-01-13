import Foundation

actor WebSocketMessagingService: MessagingServicing {
    private let baseURL: URL
    private let session: URLSession
    private var tasks: [String: URLSessionWebSocketTask] = [:]

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func connect(channelID: String) async -> AsyncThrowingStream<Message, Error> {
        let url = baseURL.appending(path: channelID)
        let task = session.webSocketTask(with: url)
        tasks[channelID] = task
        task.resume()

        return AsyncThrowingStream { [weak self] continuation in
            guard let self else { return }
            Task { await self.receiveLoop(channelID: channelID, task: task, continuation: continuation) }
            continuation.onTermination = { [weak self] _ in
                Task { await self?.disconnect(channelID: channelID) }
            }
        }
    }

    func send(_ message: OutgoingMessage, in channelID: String) async throws {
        guard let task = tasks[channelID] else { return }
        let payload = WireMessage(sender: message.sender.rawValue, body: message.body, timestamp: message.timestamp)
        let data = try JSONEncoder().encode(payload)
        try await task.send(.data(data))
    }

    func disconnect(channelID: String) {
        tasks[channelID]?.cancel(with: .goingAway, reason: nil)
        tasks[channelID] = nil
    }

    private func receiveLoop(
        channelID: String,
        task: URLSessionWebSocketTask,
        continuation: AsyncThrowingStream<Message, Error>.Continuation
    ) async {
        do {
            while true {
                let message = try await task.receive()
                switch message {
                case .string(let body):
                    if let decoded = decodeWireMessage(from: body) {
                        continuation.yield(decoded)
                    }
                case .data(let data):
                    if let decoded = decodeWireMessage(from: data) {
                        continuation.yield(decoded)
                    }
                @unknown default:
                    break
                }
            }
        } catch {
            continuation.finish(throwing: error)
        }
    }

    private func decodeWireMessage(from data: Data) -> Message? {
        guard let wire = try? JSONDecoder().decode(WireMessage.self, from: data),
              let sender = Message.Sender(rawValue: wire.sender) else { return nil }
        return Message(id: UUID(), sender: sender, body: wire.body, timestamp: wire.timestamp)
    }

    private func decodeWireMessage(from string: String) -> Message? {
        guard let data = string.data(using: .utf8) else { return nil }
        return decodeWireMessage(from: data)
    }
}

private struct WireMessage: Codable {
    let sender: String
    let body: String
    let timestamp: Date
}

