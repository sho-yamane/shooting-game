//
//  WorldTracking.swift
//  Chapter7
//
//  Created by Sho Yamane on 2024/09/14.
//

import Foundation
import ARKit

import QuartzCore

@MainActor
class WorldTracking: ObservableObject {
    private let session = ARKitSession()
    private let worldTracking = WorldTrackingProvider()
    
    func run() async {
        // ARKitの初期化とワールドトラッキングの有効化
        do {
            guard WorldTrackingProvider.isSupported else { return }
            try await session.run([worldTracking])
        } catch {
            print("Error: \(error)")
        }
    }
    
    var deviceTransform: simd_float4x4? {
        let device = worldTracking.queryDeviceAnchor(atTimestamp: CACurrentMediaTime())
        return device?.originFromAnchorTransform
    }
}
