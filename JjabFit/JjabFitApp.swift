// JjabFitApp.swift — app entry point

import SwiftUI

@main
struct JjabFitApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(model)
                .preferredColorScheme(.dark)
        }
    }
}
