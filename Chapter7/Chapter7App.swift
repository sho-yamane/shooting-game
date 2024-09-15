//
//  Chapter7App.swift
//  Chapter7
//
//  Created by Sho Yamane on 2024/09/07.
//

import SwiftUI

@main
struct Chapter7App: App {
    var body: some Scene {
        WindowGroup(id: "Window") {
            ContentView()
        }

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView()
        }
    }
}
