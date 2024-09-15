//
//  HandTracking.swift
//  Chapter7
//
//  Created by Sho Yamane on 2024/09/07.
//

import Foundation
import ARKit

@MainActor
class HandTracking: ObservableObject {
    @Published var leftIndex: simd_float4x4?
    @Published var rightIndex: simd_float4x4?
    
    func run() async {
        let session = ARKitSession()
        let handInfo = HandTrackingProvider()
        do {
            guard HandTrackingProvider.isSupported else { return }
            
            try await session.run([handInfo])
        } catch {
            print("Error: \(error)")
        }
        
        for await update in handInfo.anchorUpdates {
            guard update.anchor.isTracked else { return }
            
            switch update.event {
            case .updated:
                if let skeleton = update.anchor.handSkeleton {
                    // 人差し指の座標取得
                    let index = skeleton.joint(.indexFingerIntermediateBase).anchorFromJointTransform
                    // 手の位置を取得
                    let root = update.anchor.originFromAnchorTransform
                    // ワールド座標系に変換
                    let worldIndex = root * index
                    // 左右を判別して保存
                    if update.anchor.chirality == .left {
                        leftIndex = worldIndex
                    } else {
                        rightIndex = worldIndex
                    }
                }
            default:
                break
            }
        }
    }
}

// simd_float4x4からsimd_float3のいち情報を取得する拡張機能
extension simd_float4x4 {
    var position: simd_float3 {
        let pos = self.columns.3
        return simd_float3(pos.x, pos.y, pos.z)
    }
}
