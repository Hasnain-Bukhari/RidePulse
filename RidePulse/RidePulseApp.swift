//
//  RidePulseApp.swift
//  RidePulse
//
//  Created by Syed Hasnain Bukhari on 13/1/2569 BE.
//

import SwiftUI
@main
struct RidePulseApp: App {
    private let environment = AppEnvironment.live()
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var permissions = AppPermissions()
    @Environment(\.scenePhase) private var scenePhase
    #endif

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.appEnvironment, environment)
                #if os(iOS)
                .task {
                    await permissions.activate()
                }
                .onChange(of: scenePhase) { phase in
                    permissions.handleScenePhase(phase)
                }
                #endif
        }
    }
}
