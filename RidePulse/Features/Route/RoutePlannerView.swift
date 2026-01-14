#if os(iOS)
import SwiftUI
import CoreLocation

struct RoutePlannerView: View {
    @StateObject var viewModel: RoutePlannerViewModel
    let roomId: String
    var onShare: (Data) -> Void = { _ in }

    var body: some View {
        NavigationStack {
            VStack(spacing: AppTheme.spacing) {
                routeForm
                RoutePreviewMapView(plan: viewModel.plan)
                    .frame(height: 260)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                stopsList
                Button {
                    if let data = viewModel.encodedRoute(roomId: roomId) {
                        onShare(data)
                    }
                } label: {
                    Label("Share Route", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.isLeader)
                .opacity(viewModel.isLeader ? 1 : 0.6)
                Text(viewModel.isLeader ? "Leader can edit and share" : "View-only (leader locked)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle("Route Planner")
        }
    }

    private var routeForm: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Start", text: Binding(
                get: { viewModel.plan.start.name },
                set: { viewModel.updateStart(name: $0) }
            ))
            .textFieldStyle(.roundedBorder)

            TextField("Destination", text: Binding(
                get: { viewModel.plan.destination.name },
                set: { viewModel.updateDestination(name: $0) }
            ))
            .textFieldStyle(.roundedBorder)
        }
    }

    private var stopsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Stops (\(viewModel.plan.stops.count))")
                    .font(.headline)
                Spacer()
            }
            if viewModel.plan.stops.isEmpty {
                Text("No stops added").font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.plan.stops) { stop in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(stop.name)
                            Text(String(format: "%.4f, %.4f", stop.coordinate.latitude, stop.coordinate.longitude))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if viewModel.isLeader {
                            Button {
                                viewModel.removeStop(stop)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}

#else
import SwiftUI
struct RoutePlannerView: View {
    @StateObject var viewModel: RoutePlannerViewModel
    let roomId: String
    var onShare: (Data) -> Void = { _ in }
    var body: some View {
        Text("Route planner is iOS-only.")
    }
}
#endif

