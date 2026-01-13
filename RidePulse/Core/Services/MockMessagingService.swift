import Foundation

actor MockMessagingService: MessagingServicing {
    private var continuations: [String: AsyncThrowingStream<Message, Error>.Continuation] = [:]

    func connect(channelID: String) async -> AsyncThrowingStream<Message, Error> {
        AsyncThrowingStream { [weak self] continuation in
            guard let self else { return }
            Task { [weak self] in
                guard let self else { return }
                await self.storeContinuation(continuation, for: channelID)
                await self.sendSystem("Connected to channel \(channelID.prefix(6))", channelID: channelID)
                try? await Task.sleep(nanoseconds: 1_200_000_000)
                await self.sendSystem("Driver is en route and 6 minutes away.", channelID: channelID)
            }
            continuation.onTermination = { [weak self] _ in
                Task { await self?.cleanup(channelID: channelID) }
            }
        }
    }

    func send(_ message: OutgoingMessage, in channelID: String) async throws {
        let chatMessage = Message(
            id: UUID(),
            sender: message.sender,
            body: message.body,
            timestamp: message.timestamp
        )
        continuations[channelID]?.yield(chatMessage)
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            await self?.sendDriverEcho(for: chatMessage, channelID: channelID)
        }
    }

    func disconnect(channelID: String) {
        continuations[channelID]?.finish()
        continuations[channelID] = nil
    }

    private func storeContinuation(
        _ continuation: AsyncThrowingStream<Message, Error>.Continuation,
        for channelID: String
    ) {
        continuations[channelID] = continuation
    }

    private func sendSystem(_ body: String, channelID: String) {
        continuations[channelID]?.yield(.system(body))
    }

    private func sendDriverEcho(for message: Message, channelID: String) {
        guard message.sender == .rider else { return }
        continuations[channelID]?.yield(
            Message(
                id: UUID(),
                sender: .driver,
                body: "Driver: I see your message \"\(message.body)\". On my way!",
                timestamp: Date()
            )
        )
    }

    private func cleanup(channelID: String) {
        continuations[channelID]?.finish()
        continuations[channelID] = nil
    }
}

