//
//  VRMSpringBoneColliderGroup.swift
//  VRMKit
//
//  Created by Tomoya Hirano on 2019/12/21.
//  Copyright © 2019 tattn. All rights reserved.
//

import VRMKit
import SceneKit

final class VRMSpringBoneColliderGroup {
    let node: SCNNode
    let colliders: [SphereCollider]
    
    init(colliderGroup: VRM.SecondaryAnimation.ColliderGroup, loader: VRMSceneLoader) throws {
        self.node = try loader.node(withNodeIndex: colliderGroup.node)
        self.colliders = colliderGroup.colliders.map(SphereCollider.init)
    }
    
    final class SphereCollider {
        let offset: SCNVector3
        let radius: Double
        
        init(collider: VRM.SecondaryAnimation.ColliderGroup.Collider) {
            self.offset = collider.offset.createSCNVector3()
            self.radius = collider.radius
        }
    }
}
