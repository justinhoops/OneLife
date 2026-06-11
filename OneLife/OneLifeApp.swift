//
//  OneLifeApp.swift
//  OneLife
//
//  Created by Justin Jeffery on 2/8/26.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

@main
struct OneLifeApp: App {
    @StateObject private var rootViewModel = GameViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(vm: rootViewModel)
                #if canImport(UIKit)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)) { _ in
                    rootViewModel.handleMemoryPressure()
                }
                #endif
        }
    }
}
