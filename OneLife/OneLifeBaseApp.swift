import SwiftUI

struct LifeSimBaseApp: App {
    @StateObject private var rootViewModel = GameViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(vm: rootViewModel)
        }
    }
}

