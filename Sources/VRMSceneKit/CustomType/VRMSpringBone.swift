//
//  VRMSpringBone.swift
//  SpringBoneKit
//
//  Created by Tomoya Hirano on 2019/12/20.
//  Copyright © 2019 Tomoya Hirano. All rights reserved.
//

import SceneKit
import GameKit
@testable import VRMKit
@testable import VRMSceneKit

final class VRMSpringBone: GKEntity {
    public let comment: String = ""
    public var stiffnessForce: SCNFloat = 1.0
    public var gravityPower: SCNFloat = 0.0
    public var gravityDir: SCNVector3 = .init(0, -1, 0)
    public var dragForce: SCNFloat = 0.4
    public var center: SCNNode! = nil
    public var rootBones: [SCNNode] = []
    var initialLocalRotationMap: [SCNNode : SCNQuaternion] = [:]
    public let hitRadius: SCNFloat = 0.02
    public var colliderGroups: [VRMSpringBoneColliderGroup] = []
    
    class SpringBoneLogic {
        private let transform: SCNNode
        public var head: SCNNode { transform }
        public var tail: SCNVector3 { transform.localToWorldMatrix.multiplyPoint(boneAxis * length) }
        let length: SCNFloat
        var currentTail: SCNVector3!
        var prevTail: SCNVector3!
        public let localRotation: SCNQuaternion!
        public let boneAxis: SCNVector3!
        public var radius: SCNFloat = 0.5
        
        init(center: SCNNode?, transform: SCNNode, localChildPosition: SCNVector3) {
            self.transform = transform
            let worldChildPosition = transform.transformPoint(localChildPosition)
            currentTail = center?.inverseTransformPoint(worldChildPosition) ?? worldChildPosition
            prevTail = currentTail
            localRotation = transform.orientation
            boneAxis = localChildPosition.normalized
            length = localChildPosition.magnitude()
        }
        
        var parentRotation: SCNQuaternion {
            transform.parent?.worldOrientation ?? SCNQuaternion.identity
        }
        
        func update(center: SCNNode?, stiffnessForce: SCNFloat, dragForce: SCNFloat, external: SCNVector3, colliders: [SphereCollider]) {
            let currentTail: SCNVector3 = center?.transformPoint(self.currentTail) ?? self.currentTail
            let prevTail: SCNVector3 = center?.transformPoint(self.prevTail) ?? self.prevTail
            // verlet積分で次の位置を計算
            var nextTail: SCNVector3 = currentTail
                + (currentTail - prevTail) * (1.0 - dragForce) // 前フレームの移動を継続する(減衰もあるよ)
                + parentRotation * localRotation * boneAxis * stiffnessForce // 親の回転による子ボーンの移動目標
                + external // 外力による移動量
            
            // 長さをboneLengthに強制
            nextTail = transform.worldPosition + (nextTail - transform.worldPosition).normalized * length
            
            // Collisionで移動
            nextTail = collision(colliders, nextTail: nextTail)
            
            self.prevTail = center?.inverseTransformPoint(currentTail) ?? currentTail
            self.currentTail = center?.inverseTransformPoint(nextTail) ?? nextTail
            
            // 回転を適用
            head.worldOrientation = applyRotation(nextTail)
        }
        
        func applyRotation(_ nextTail: SCNVector3) -> SCNQuaternion {
            let rotation = parentRotation * localRotation
            return SCNQuaternion(from: rotation * boneAxis, to: nextTail - transform.worldPosition) * rotation
        }
        
        func collision(_ colliders: [SphereCollider], nextTail: SCNVector3) -> SCNVector3 {
            var nextTail = nextTail
            for collider in colliders {
                let r = radius + collider.radius
                if (nextTail - collider.position).magnitudeSquared() <= (r * r) {
                    // ヒット。Colliderの半径方向に押し出す
                    let normal = (nextTail - collider.position).normalized
                    let posFromCollider = collider.position + normal * (radius + collider.radius)
                    // 長さをboneLengthに強制
                    nextTail = transform.worldPosition + (posFromCollider - transform.worldPosition).normalized * length
                }
            }
            return nextTail
        }
    }
    
    var verlet: [SpringBoneLogic] = []
    
    func awake() {
        setup()
    }
    
    func setup(_ force: Bool = false) {
        if !rootBones.isEmpty {
            if force || initialLocalRotationMap.isEmpty {
                initialLocalRotationMap = [:]
            } else {
                for kv in initialLocalRotationMap {
                    kv.key.orientation = kv.value
                }
                initialLocalRotationMap = [:]
            }
            verlet = []
            
            for go in rootBones {
                for x in go.traverse {
                    initialLocalRotationMap[x] = x.orientation
                }
                setupRecursive(center: center, parent: go)
            }
        }
    }
    
    func setLocalRotationsIdentity() {
        for verlet in verlet {
            verlet.head.orientation = SCNQuaternion.identity
        }
    }
    
    func setupRecursive(center: SCNNode, parent: SCNNode) {
        if parent.childNodes.isEmpty {
            let delta: SCNVector3 = parent.worldPosition - parent.parent!.worldPosition
            let childPosition = parent.worldPosition + delta.normalized * 0.07
            verlet.append(SpringBoneLogic(center: center, transform: parent, localChildPosition: parent.worldToLocalMatrix.multiplyPoint(childPosition)))
        } else {
            let firstChild = parent.childNodes.first
            let localPosition = firstChild!.position
            let scale = firstChild!.scale
            verlet.append(SpringBoneLogic(center: center, transform: parent, localChildPosition: SCNVector3(localPosition.x * scale.x, localPosition.y * scale.y, localPosition.z * scale.z)))
        }
        
        //http://narudesign.com/devlog/unity-child-object-only/
        parent.childNodes.forEach { (child) in
            setupRecursive(center: center, parent: child)
        }
    }
    
    struct SphereCollider {
        let position: SCNVector3
        let radius: SCNFloat
    }
    
    private var colliderList: [SphereCollider] = []
    
    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)
        if verlet.isEmpty {
            if rootBones.isEmpty {
                return
            }
            setup()
        }
        colliderList = []
        if !colliderGroups.isEmpty {
            for colliderGroup in colliderGroups {
                for collider in colliderGroup.colliders {
                    colliderList.append(SphereCollider(
                        position: colliderGroup.node.transformPoint(collider.offset),
                        radius: SCNFloat(collider.radius)
                    ))
                }
            }
        }
        let stiffness = stiffnessForce * SCNFloat(seconds)
        let external = gravityDir * (gravityPower * SCNFloat(seconds))
        for verlet in verlet {
            verlet.radius = hitRadius
            verlet.update(center: center,
                          stiffnessForce: stiffness,
                          dragForce: dragForce,
                          external: external,
                          colliders: colliderList)
        }
    }
}



