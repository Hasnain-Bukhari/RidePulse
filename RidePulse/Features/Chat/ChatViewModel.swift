import Foundation
import SwiftUI
import Combine

@MainActor
final class ChatViewModel: ObservableObject {
    enum ConnectionState: Equatable {
        case idle
        case connecting
        case connected
        case failed(String)

        var description: String {
            switch self {
            case .idle: return "Idle"
            case .connecting: return "Connecting…"
            case .connected: return "Live"
            case .failed(let message): return "Error: \(message)"
            }
        }
    }

    @Published var messages: [Message] = []
    @Published var composerText: String = ""
    @Published var connectionState: ConnectionState = .idle

    let ride: Ride

    private let messagingService: MessagingServicing
    private let dateProvider: () -> Date
    private var streamTask: Task<Void, Never>?

    init(
        ride: Ride,
        messagingService: MessagingServicing,
        dateProvider: @escaping () -> Date
    ) {
        self.ride = ride
        self.messagingService = messagingService
        self.dateProvider = dateProvider
    }

    func onAppear() {
        startStreaming()
    }

    func onDisappear() {
        streamTask?.cancel()
        messagingService.disconnect(channelID: ride.channelID)
    }

    func reconnect() {
        streamTask?.cancel()
        streamTask = nil
        connectionState = .connecting
        startStreaming()
    }

    func sendMessage() {
        let trimmed = composerText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        composerText = ""

        let outgoing = OutgoingMessage(
            sender: .rider,
            body: trimmed,
            timestamp: dateProvider()
        )

        Task {
            do {
                try await messagingService.send(outgoing, in: ride.channelID)
            } catch {
                await MainActor.run {
                    self.connectionState = .failed("Failed to send: \(error.localizedDescription)")
                }
            }
        }
    }

    private func startStreaming() {
        guard streamTask == nil else { return }
        connectionState = .connecting

        streamTask = Task { [weak self] in
            guard let self else { return }
            let stream = await messagingService.connect(channelID: ride.channelID)
            await MainActor.run {
                self.connectionState = .connected
            }

            do {
                for try await message in stream {
                    await MainActor.run {
                        self.messages.append(message)
                    }
                }
            } catch {
                await MainActor.run {
                    self.connectionState = .failed(error.localizedDescription)
                }
            }
        }
    }
}

