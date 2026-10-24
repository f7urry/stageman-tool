//
//  StagemanToolApp.swift
//  StagemanTool
//
//  Created by F7urry on 12/10/25.
//

import SwiftUI

@main
struct StagemanToolApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(service: WindowManagerService())
        }
    }
}
