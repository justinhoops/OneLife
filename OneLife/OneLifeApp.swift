import SwiftUI

private struct UITestReduceMotionKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var uiTestReduceMotion: Bool {
        get { self[UITestReduceMotionKey.self] }
        set { self[UITestReduceMotionKey.self] = newValue }
    }
}

@main
struct OneLifeApp: App {
    var body: some Scene {
        WindowGroup {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-uiTestReduceMotion") {
                ContentView()
                    .environment(\.uiTestReduceMotion, true)
            } else {
                ContentView()
            }
            #else
            ContentView()
            #endif
        }
    }
}
