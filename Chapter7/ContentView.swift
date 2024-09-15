//
//  ContentView.swift
//  Chapter7
//
//  Created by Sho Yamane on 2024/09/07.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
    
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Image("background")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 25.0))
            Button(action: {
                Task {
                    await openImmersiveSpace(id: "ImmersiveSpace")
                    dismiss()
                }
            }, label: {
                Text("Start")
                    .font(.extraLargeTitle)
                    .padding(32)
            })
        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
}
