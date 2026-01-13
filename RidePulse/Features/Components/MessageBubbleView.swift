import SwiftUI

struct MessageBubbleView: View {
    let message: Message

    private var isMine: Bool {
        message.sender == .rider
    }

    var body: some View {
        HStack {
            if isMine { Spacer() }
            VStack(alignment: .leading, spacing: 4) {
                Text(senderLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(message.body)
                    .padding(10)
                    .background(bubbleColor)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            if !isMine { Spacer() }
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    private var senderLabel: String {
        switch message.sender {
        case .rider: return "You"
        case .driver: return "Driver"
        case .system: return "System"
        }
    }

    private var bubbleColor: Color {
        switch message.sender {
        case .rider: return AppTheme.rider
        case .driver: return AppTheme.driver
        case .system: return AppTheme.system
        }
    }
}

#Preview {
    VStack(spacing: AppTheme.spacing) {
        MessageBubbleView(message: .system("Driver is nearby"))
        MessageBubbleView(
            message: Message(id: UUID(), sender: .driver, body: "On my way!", timestamp: Date())
        )
        MessageBubbleView(
            message: Message(id: UUID(), sender: .rider, body: "Great, see you soon.", timestamp: Date())
        )
    }
    .padding()
}

