import SwiftUI
import KaribTruckCore

/// Point d'entrée de l'app iPad. Le projet Xcode se génère avec XcodeGen
/// (`App/project.yml`) — voir App/README.md.
@main
struct KaribTruckApp: App {
    @StateObject private var store = Store()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(store)
                #if targetEnvironment(simulator)
                .onAppear { store.seedDemoIfRequested() }
                #endif
        }
    }
}
