//
//  dooApp.swift
//  doo
//
//  Created by r00t on 2025/7/16.
//

import AppKit
import SwiftUI

@main
struct DooApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(
                    minWidth: 250, idealWidth: 300, maxWidth: 400,
                    minHeight: 233, idealHeight: 267, maxHeight: 600
                )
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 300, height: 267)
        .windowToolbarStyle(.unified(showsTitle: false))
        .commands {
            CommandGroup(after: .newItem) {
                Button("显示存储文件夹") {
                    NSWorkspace.shared.selectFile(
                        TodoMarkdownStore.storageFileURL().path,
                        inFileViewerRootedAtPath: TodoMarkdownStore.storageDirectoryURL().path
                    )
                }
                .keyboardShortcut("o", modifiers: [.command, .shift])
            }
        }
    }
}
