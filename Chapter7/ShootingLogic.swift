//
//  ShootingLogic.swift
//  Chapter7
//
//  Created by Sho Yamane on 2024/09/07.
//

import Foundation
import RealityKit

@MainActor
class ShootingLogic: ObservableObject {
    // 弾管理用
    var bulletRoot = Entity()
    // ターゲット管理用
    var targetRoot = Entity()
    // 残り時間
    @Published var time: Float = 30
    // 特典
    @Published var score: Int = 0
    // 前回の発射時間
    private var previousTime: Float = 30
    
    func run() async {
        while true {
            // 200Hzで更新する
            let interval: Float = 1.0 / 200
            let intervalNanos = UInt64(Float(NSEC_PER_SEC) * interval)
            do {
                try await Task.sleep(nanoseconds: intervalNanos)
            } catch {
                return
            }
            
            time -= interval
            if time < 0.0 {
                time = 0.0
            } else {
                targetRoot.children.first?.position = simd_float3(sin(time / 2.0) / 2.0, 0, 0)
            }
        }
    }
    
    func reset() {
        bulletRoot.children.removeAll()
        score = 0
        time = 30
        previousTime = 30
    }
    
    func shoot(
        bullet: ModelEntity?,
        position: simd_float3,
        velocity: simd_float3,
        shootAction: () -> Void
    ) {
        guard time > 0.0 && previousTime - time >= 0.1 else { return }
        previousTime = time
        
        if let bullet {
            let bulletClone = bullet.clone(recursive: true)
            bulletClone.position = position
            bulletClone.physicsMotion?.linearVelocity = velocity
            bulletRoot.addChild(bulletClone)
            shootAction()
        }
    }
    
    func hit (
        _ event: CollisionEvents.Began,
        hitAction: () -> Void
    ) {
        if event.entityA.name != event.entityB.name {
            score += 1
            event.entityB.removeFromParent()
            hitAction()
        }
    }
}
