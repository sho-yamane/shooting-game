//
//  ImmersiveView.swift
//  Chapter7
//
//  Created by Sho Yamane on 2024/09/07.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ImmersiveView: View {
    // 画面遷移のための関数（環境値）
    @Environment(\.openWindow) var openWindow
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    // ゲームロジック
    @StateObject var logic = ShootingLogic()
    // 弾　Entity
    @State var bullet: ModelEntity?
    // ARKitのハンドトラッキング機能
    @StateObject var handTracking = HandTracking()
    // ARKitのワールドトラッキング機能
    @StateObject var worldTraking = WorldTracking()
    // ARKitのシーン再構築機能
    @StateObject var sceneReconstruction = SceneReconstruction()
    // ARKitの画像トラッキング機能
    @StateObject var imageTracking = ImageTracking()
    // 弾発射音
    @State var bulletAudio: AudioPlaybackController?
    // ターゲットへの命中音
    @State var targetAudio: AudioPlaybackController?
    
    var body: some View {
        RealityView { content, attachments in
            if let bulletScene = try? await Entity(
                named: "Bullet",
                in: realityKitContentBundle
            ) {
                bullet = bulletScene.findEntity(named: "Sphere") as? ModelEntity
                // 弾発射音の読み込み
                if let audioEnt = bulletScene.findEntity(named: "SpatialAudio"),
                   let resource = try? await AudioFileResource(
                        named: "/Root/shoot_mp3", from: "Bullet.usda", in: realityKitContentBundle
                   )
                {
                    bulletAudio = audioEnt.prepareAudio(resource)
                    content.add(audioEnt)
                }
            }
            
            if let targetScene = try? await Entity(
                named: "Target",
                in: realityKitContentBundle
            ) {
                if let target = targetScene.findEntity(named: "Robot") {
                    // ターゲット管理用Entityへの追加
                    logic.targetRoot.position = simd_float3(0, 1, -1)
                    logic.targetRoot.addChild(target)
                                        
                    _ = content.subscribe(to: CollisionEvents.Began.self, on: target) {
                        event in
                        
                        logic.hit(event) {
                            targetAudio?.entity?.position = event.entityB.position
                            targetAudio?.stop()
                            targetAudio?.play()
                        }
                    }
                    
                    if let attachedUI = attachments.entity(for: "Menu") {
                        target.addChild(attachedUI)
                    }
                }
                
                if let audioEnt = targetScene.findEntity(named: "SpatialAudio"),
                   let resource = try? await AudioFileResource(
                        named: "/Root/hit_mp3", from: "Target.usda", in: realityKitContentBundle
                   )
                {
                    targetAudio = audioEnt.prepareAudio(resource)
                    content.add(audioEnt)
                }
                
                if let audioEnt = targetScene.findEntity(named: "AmbientAudio"),
                   let resource = try? await AudioFileResource(
                        named: "/Root/bgm_mp3", from: "Target.usda", in: realityKitContentBundle
                   )
                {
                    let audio = audioEnt.prepareAudio(resource)
                    content.add(audioEnt)
                    audio.play()
                }
            }
            
            content.add(logic.bulletRoot)
            content.add(logic.targetRoot)
            content.add(sceneReconstruction.root)
        } update: { content, attachments in
                if let image = imageTracking.imageTransform {
                    logic.targetRoot.transform.matrix = image
                }
                if let leftIndex = handTracking.leftIndex,
                   let rightIndex = handTracking.rightIndex {
                    if distance(leftIndex.position, rightIndex.position) < 0.04 {
                        if let device = worldTraking.deviceTransform {
                            let vec = device * simd_float4(0, 0, -1, 0)
                            logic.shoot(
                                bullet: bullet,
                                position: leftIndex.position,
                                velocity: simd_float3(vec.x, vec.y, vec.z) * 5
                            ) {
                                bulletAudio?.entity?.position = leftIndex.position
                                bulletAudio?.stop()
                                bulletAudio?.play()
                            }
                        }
                    }
                }
        } attachments: {
            Attachment(id: "Menu") {
                VStack {
                    Text("Score: \(logic.score) Time: \(Int(logic.time))")
                        .font(.extraLargeTitle)
                    Spacer()
                    HStack {
                        // デバッグ用
                        #if targetEnvironment(simulator)
                        Button("Shoot!!") {
                            logic.shoot(bullet: bullet, position: SIMD3(0, 1.2, -0.5), velocity: SIMD3(0, 0, -5)) {
                                bulletAudio?.entity?.position = SIMD3(0, 1.2, -0.5)
                                bulletAudio?.stop()
                                bulletAudio?.play()
                            }
                        }
                        #endif
                        
                        Button("リセット") {
                            logic.reset()
                        }
                        Button("終了") {
                            Task {
                                openWindow(id: "Window")
                                await dismissImmersiveSpace()
                            }
                        }
                    }
                    Spacer()
                }
                .offset(z: 100)
            }
        }
        .task {
            await logic.run()
        }
        .task {
            await handTracking.run()
        }
        .task {
            await worldTraking.run()
        }
        .task {
            await sceneReconstruction.run()
        }
        .task {
            await imageTracking.run()
        }
    }
}

#Preview(immersionStyle: .mixed) {
    ImmersiveView()
}
