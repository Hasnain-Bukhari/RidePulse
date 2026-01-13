import SwiftUI

struct ChatView: View {
    @StateObject var viewModel: ChatViewModel
    @Namespace private var bottomID

    var body: some View {
        VStack(spacing: AppTheme.spacing) {
            header
            Divider()
            messages
            composer
        }
        .padding()
        .navigationTitle("Ride Chat")
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Driver Chat")
                    .font(.headline)
                Text("Ride \(viewModel.ride.id.uuidString.prefix(6)) • \(viewModel.connectionState.description)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)
        }
    }

    private var messages: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: AppTheme.spacing) {
                    ForEach(viewModel.messages) { message in
                        MessageBubbleView(message: message)
                            .id(message.id)
                    }
                    Color.clear
                        .frame(height: 1)
                        .id(bottomID)
                }
                .onChange(of: viewModel.messages.count) { _ in
                    withAnimation {
                        proxy.scrollTo(bottomID, anchor: .bottom)
                    }
                }
            }
        }
    }

    private var composer: some View {
        HStack {
            textField

            Button {
                viewModel.sendMessage()
            } label: {
                Image(systemName: "paperplane.fill")
                    .padding(10)
            }
            .background(AppTheme.accent.opacity(0.1))
            .clipShape(Circle())
            .disabled(isSendDisabled)
        }
    }

    @ViewBuilder
    private var textField: some View {
#if os(iOS)
        TextField("Message driver…", text: $viewModel.composerText)
            .textFieldStyle(.roundedBorder)
            .textInputAutocapitalization(.sentences)
#else
        TextField("Message driver…", text: $viewModel.composerText)
            .textFieldStyle(.roundedBorder)
#endif
    }

    private var statusColor: Color {
        switch viewModel.connectionState {
        case .connected:
            return .green
        case .connecting:
            return .yellow
        case .failed:
            return .red
        case .idle:
            return .gray
        }
    }

    private var isSendDisabled: Bool {
        let trimmed = viewModel.composerText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return true }
        if case .failed = viewModel.connectionState { return true }
        return false
    }
}

#Preview {
    ChatView(
        viewModel: ChatViewModel(
            ride: .sample,
            messagingService: MockMessagingService(),
            dateProvider: Date.init
        )
    )
    .environment(\.appEnvironment, .preview())
}

