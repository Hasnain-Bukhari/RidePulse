//
//  ContentView.swift
//  RidePulse
//
//  Created by Syed Hasnain Bukhari on 13/1/2569 BE.
//

import SwiftUI
struct RootView: View {
    @Environment(\.appEnvironment) private var environment
    @State private var ride: Ride = .sample

    var body: some View {
        TabView {
            RideDashboardView(viewModel: RideDashboardViewModel(ride: ride))
                .tabItem {
                    Label("Ride", systemImage: "car.fill")
                }

            ChatView(
                viewModel: ChatViewModel(
                    ride: ride,
                    messagingService: environment.messagingService,
                    dateProvider: environment.dateProvider
                )
            )
            .tabItem {
                Label("Chat", systemImage: "bubble.left.and.bubble.right.fill")
            }

#if os(iOS)
            RoutePlannerView(
                viewModel: RoutePlannerViewModel(plan: RoutePlan.sample()),
                roomId: ride.channelID
            )
            .tabItem {
                Label("Route", systemImage: "point.topleft.down.curvedto.point.bottomright.up")
            }
#endif
        }
    }
}

#Preview {
    RootView()
        .environment(\.appEnvironment, .preview())
}
