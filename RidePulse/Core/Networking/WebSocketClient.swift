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
        Task { await self.start() }
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
        await emit(.disconnected)
    }

    // MARK: - Private

    private func start() async {
        guard shouldReconnect, state != .connecting else { return }
        listenTask?.cancel()
        pingTask?.cancel()
        state = .connecting
        let task = session.webSocketTask(with: url)
        self.task = task
        task.resume()
        listen(task: task)
        startPing(task: task)
        await emit(.connected)
    }

    private func listen(task: URLSessionWebSocketTask) {
        listenTask = Task { [weak self] in
            await self?.listenLoop(task: task)
        }
    }

    private func listenLoop(task: URLSessionWebSocketTask) async {
        while !Task.isCancelled {
            do {
                let message = try await task.receive()
                await resetBackoff()
                switch message {
                case .data(let data):
                    await emit(.message(data))
                case .string(let text):
                    await emit(.text(text))
                @unknown default:
                    break
                }
            } catch {
                if Task.isCancelled { break }
                await handleFailure(error)
                break
            }
        }
    }

    private func startPing(task: URLSessionWebSocketTask) {
        pingTask = Task { [weak self] in
            await self?.pingLoop(task: task)
        }
    }

    private func pingLoop(task: URLSessionWebSocketTask) async {
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: UInt64(pingInterval * 1_000_000_000))
            guard isConnected() else { continue }
            do {
                try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
                    task.sendPing { error in
                        if let error {
                            cont.resume(throwing: error)
                        } else {
                            cont.resume()
                        }
                    }
                }
            } catch {
                await handleFailure(error)
                break
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
        await start()
    }

    private func resetBackoff() async {
        retryAttempts = 0
        state = .connected
    }

    private func isConnected() -> Bool {
        if case .connected = state {
            return true
        }
        return false
    }

    private func handleFailure(_ error: Error) async {
        await emit(.error(error))
        await scheduleReconnect()
    }

    @inline(__always)
    private func emit(_ event: Event) async {
        onEvent?(event)
    }
}

