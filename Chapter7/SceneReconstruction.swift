//
//  SceneReconstruction.swift
//  Chapter7
//
//  Created by Sho Yamane on 2024/09/14.
//

import Foundation
import ARKit
import RealityKit

@MainActor
class SceneReconstruction: ObservableObject {
    // 障害物の保持
    var root = Entity()
    // 障害物管理辞書
    private var meshEntities = [UUID: ModelEntity]()
    
    func run() async {
        let session = ARKitSession()
        let sceneReconstruction = SceneReconstructionProvider()
        do {
            guard SceneReconstructionProvider.isSupported else { return }
            try await session.run([sceneReconstruction])
        } catch {
            print("Error: \(error)")
        }
        
        // 障害物の更新処理
        for await update in sceneReconstruction.anchorUpdates {
            let meshAnchor = update.anchor
            // 障害物用のメッシュ作成
            guard let shape = try? await ShapeResource.generateStaticMesh(from: meshAnchor) else { return }
            
            switch update.event {
            // 障害物が新規追加された場合
            case .added:
                // 追加された物体から障害物Entityを作成、物理演算機能を追加
                let entity = ModelEntity()
                entity.transform = Transform(
                    matrix: meshAnchor.originFromAnchorTransform
                )
                entity.collision = CollisionComponent(
                    shapes: [shape],
                    isStatic: true
                )
                entity.components.set(InputTargetComponent())
                entity.physicsBody = PhysicsBodyComponent(mode: .static)
                // 管理用辞書とルートEntityに追加
                meshEntities[meshAnchor.id] = entity
                root.addChild(entity)
            // 障害物の形状がアップデートされた場合
            case .updated:
                // 物体のidを取得して形状と位置を更新
                guard let entity = meshEntities[meshAnchor.id] else { continue }
                entity.transform = Transform(
                    matrix: meshAnchor.originFromAnchorTransform
                )
                entity.collision?.shapes = [shape]
            // 障害物が削除された場合
            case .removed:
                meshEntities[meshAnchor.id]?.removeFromParent()
                meshEntities.removeValue(forKey: meshAnchor.id)
            }
        }
    }
}
