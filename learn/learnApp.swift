//
//  learnApp.swift
//  learn
//
//  Created by r00t on 2025/7/16.
//

import SwiftUI

@main
struct learnApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(
                    minWidth: 250, idealWidth: 300, maxWidth: 400,
                    minHeight: 350, idealHeight: 500, maxHeight: 600
                )
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 300, height: 400)
        .windowStyle(.hiddenTitleBar)
        
        
//        Settings {
//            SettingsLink()
//        }
    }
}
