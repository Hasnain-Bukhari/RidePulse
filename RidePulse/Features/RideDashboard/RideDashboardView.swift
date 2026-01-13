import SwiftUI

struct RideDashboardView: View {
    @StateObject var viewModel: RideDashboardViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.spacing) {
                #if os(iOS)
                UserLocationMapView()
                #endif
                rideCard
                statusCard
                contactCard
            }
            .padding()
        }
        .navigationTitle("Ride Overview")
    }

    private var rideCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Current Ride")
                .font(.headline)
            LabeledContent("Pickup", value: viewModel.ride.pickup)
            LabeledContent("Drop-off", value: viewModel.ride.dropoff)
            LabeledContent("Rider", value: viewModel.ride.rider.name)
            Text("Channel ID: \(viewModel.ride.channelID.prefix(8))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Status")
                .font(.headline)
            Text(viewModel.statusText)
                .font(.title3)
                .bold()
            Text(viewModel.etaText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            ProgressView(value: progressValue)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
    }

    private var contactCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Contact")
                .font(.headline)
            Label(viewModel.ride.rider.phone, systemImage: "phone.fill")
            Label("Chat with driver to coordinate pickup", systemImage: "bubble.left.and.bubble.right.fill")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
    }

    private var progressValue: Double {
        switch viewModel.ride.status {
        case .searchingDriver: return 0.2
        case .driverEnRoute: return 0.4
        case .driverArrived: return 0.6
        case .inProgress: return 0.8
        case .completed: return 1.0
        case .cancelled: return 0.0
        }
    }
}

#Preview {
    RideDashboardView(viewModel: RideDashboardViewModel(ride: .sample))
}

