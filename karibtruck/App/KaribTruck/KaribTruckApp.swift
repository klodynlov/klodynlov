import SwiftUI
import KaribTruckCore

/// Point d'entrée de l'app iPad. À compiler dans Xcode (SwiftUI n'existe pas sur
/// Linux) après avoir ajouté le package local `KaribTruckCore` — voir App/README.md.
@main
struct KaribTruckApp: App {
    @StateObject private var store = Store()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
