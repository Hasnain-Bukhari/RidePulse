import Foundation

actor WebSocketClient {
    enum State: Equatable {
        case disconnected
        case connecting
        case connected
        case failed(String)
    }

    enum Event {
        case connected
        case disconnected
        case message(Data)
        case text(String)
        case error(Error)
    }

    private let url: URL
    private let session: URLSession
    private var task: URLSessionWebSocketTask?
    private var state: State = .disconnected
    private var retryAttempts = 0
    private let maxBackoff: TimeInterval = 30
    private var shouldReconnect = true
    private var listenTask: Task<Void, Never>?
    private var pingTask: Task<Void, Never>?
    private let pingInterval: TimeInterval = 15

    private var onEvent: ((Event) -> Void)?

    init(url: URL, session: URLSession = .shared) {
        self.url = url
        self.session = session
    }

    func connect(onEvent: @escaping (Event) -> Void) {
        self.onEvent = onEvent
        shouldReconnect = true
        start()
    }

    func send(text: String) async {
        guard case .connected = state, let task else { return }
        do {
            try await task.send(.string(text))
        } catch {
            await handleFailure(error)
        }
    }

    func send(data: Data) async {
        guard case .connected = state, let task else { return }
        do {
            try await task.send(.data(data))
        } catch {
            await handleFailure(error)
        }
    }

    func disconnect() async {
        shouldReconnect = false
        listenTask?.cancel()
        pingTask?.cancel()
        task?.cancel(with: .goingAway, reason: nil)
        task = nil
        state = .disconnected
        onEvent?(.disconnected)
    }

    // MARK: - Private

    private func start() {
        guard shouldReconnect, state != .connecting else { return }
        listenTask?.cancel()
        pingTask?.cancel()
        state = .connecting
        let task = session.webSocketTask(with: url)
        self.task = task
        task.resume()
        listen(task: task)
        startPing(task: task)
        onEvent?(.connected)
    }

    private func listen(task: URLSessionWebSocketTask) {
        listenTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                do {
                    let message = try await task.receive()
                    await self.resetBackoff()
                    switch message {
                    case .data(let data):
                        self.onEvent?(.message(data))
                    case .string(let text):
                        self.onEvent?(.text(text))
                    @unknown default:
                        break
                    }
                } catch {
                    if Task.isCancelled { break }
                    await self.handleFailure(error)
                    break
                }
            }
        }
    }

    private func startPing(task: URLSessionWebSocketTask) {
        pingTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(pingInterval * 1_000_000_000))
                guard self.state == .connected else { continue }
                try? await task.sendPing()
            }
        }
    }

    private func scheduleReconnect() async {
        guard shouldReconnect, state != .disconnected else { return }
        state = .disconnected
        retryAttempts += 1
        let base = min(pow(2.0, Double(retryAttempts)), maxBackoff)
        let jitter = Double.random(in: 0.8...1.2)
        let delay = base * jitter
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        start()
    }

    private func resetBackoff() {
        retryAttempts = 0
        state = .connected
    }

    private func handleFailure(_ error: Error) async {
        onEvent?(.error(error))
        await scheduleReconnect()
    }
}

