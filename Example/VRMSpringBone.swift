//
//  VRMSpringBone.swift
//  SpringBoneKit
//
//  Created by Tomoya Hirano on 2019/12/20.
//  Copyright © 2019 Tomoya Hirano. All rights reserved.
//

import SceneKit
import GameKit

class VRMSpringBone: GKEntity {
    public let comment: String = ""
    public var stiffnessForce: SCNFloat = 1.0
    public var gravityPower: SCNFloat = 0.0
    public var gravityDir: SCNVector3 = .init(0, -1, 0)
    public var dragForce: SCNFloat = 0.4
    public var center: SCNNode! = nil
    public var rootBones: [SCNNode] = []
    var initialLocalRotationMap: [SCNNode : SCNQuaternion] = [:]
    public let hitRadius: SCNFloat = 0.02
    public let colliderGroups: [VRMSpringBoneColliderGroup] = []
    
    class VRMSpringBoneLogic {
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
            boneAxis = localChildPosition.normalized()
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
            nextTail = transform.worldPosition + (nextTail - transform.worldPosition).normalized() * length
            
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
                    let normal = (nextTail - collider.position).normalized()
                    let posFromCollider = collider.position + normal * (radius + collider.radius)
                    // 長さをboneLengthに強制
                    nextTail = transform.worldPosition + (posFromCollider - transform.worldPosition).normalized() * length
                }
            }
            return nextTail
        }
    }
    
    var verlet: [VRMSpringBoneLogic] = []
    
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
            let childPosition = parent.worldPosition + delta.normalized() * 0.07
            verlet.append(VRMSpringBone.VRMSpringBoneLogic(center: center, transform: parent, localChildPosition: parent.worldToLocalMatrix.multiplyPoint(childPosition)))
        } else {
            let firstChild = parent.childNodes.first
            let localPosition = firstChild!.position
            let scale = firstChild!.scale
            verlet.append(VRMSpringBone.VRMSpringBoneLogic(center: center, transform: parent, localChildPosition: SCNVector3(localPosition.x * scale.x, localPosition.y * scale.y, localPosition.z * scale.z)))
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
    
    var colliderList: [SphereCollider] = []
    
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
            for group in colliderGroups {
                for collider in group.colliders {
                    colliderList.append(SphereCollider(
                        position: group.transform.transformPoint(collider.offset),
                        radius: collider.radius
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


class MonoBehaviour {
    var transform: SCNNode!
}

class VRMSpringBoneColliderGroup: MonoBehaviour {
    class SphereCollider {
        let offset: SCNVector3! = nil
        let radius: SCNFloat = 0.1
    }
    
    var colliders: [SphereCollider] = [SphereCollider()]
}


extension SCNMatrix4 {
    /// https://gist.github.com/justinmeiners/6568753eb12714390c2a010cee48e0cf
    func multiplyPoint(_ v: SCNVector3) -> SCNVector3 {
        var vector3: SCNVector3 = SCNVector3(
            (m11 *  v.x +  m12 *  v.y +  m13 *  v.z) + m14,
            (m21 *  v.x +  m22 *  v.y +  m23 *  v.z) + m24,
            (m31 *  v.x +  m32 *  v.y +  m33 *  v.z) + m34
        )
        let num: Float = 1.0 / ( ( m41 *  v.x +  m42 *  v.y +  m43 *  v.z) + m44)
        vector3.x *= num
        vector3.y *= num
        vector3.z *= num
        return vector3
    }
}

extension SCNNode {
    
    // http://light11.hatenadiary.com/entry/2019/03/09/182229
    // https://github.com/n-yoda/unity-transform/blob/master/Assets/TransformMatrix/TransformMatrix.cs
    var localToWorldMatrix: SCNMatrix4 {
        SCNNode.localToParent(transform: parent!) * SCNNode.localToParent(transform: self)
    }
    
    //https://github.com/michidk/BrokenEngine/blob/master/BrokenEngine/GameObject.cs#L99
    var worldToLocalMatrix: SCNMatrix4 {
        localToWorldMatrix.inverted()
    }
    
    //http://edom18.hateblo.jp/entry/2018/04/26/214315
    func transformPoint(_ point: SCNVector3) -> SCNVector3 {
        localToWorldMatrix.multiplyPoint(point)
    }
    
    // https://github.com/google-ar/arcore-android-sdk/issues/570
    // http://edom18.hateblo.jp/entry/2018/04/26/214315
    func inverseTransformPoint(_ point: SCNVector3) -> SCNVector3 {
        worldToLocalMatrix.multiplyPoint(point)
//        transformPoint(point).inverted()
    }
    
    var traverse: [SCNNode] {
        childNodes
    }
}





extension SCNNode {
    static func localToParent(transform: SCNNode) -> SCNMatrix4 {
        trs(trans: transform.position, euler: transform.eulerAngles, scale: transform.scale)
    }
    
    static func trs(trans: SCNVector3, euler: SCNVector3, scale: SCNVector3) -> SCNMatrix4 {
        translate(vec: trans) * rotate(euler: euler) * self.scale(scale: scale)
    }

    static func rotate(euler: SCNVector3) -> SCNMatrix4 {
        func x(_ deg: Float) -> SCNMatrix4 {
            let rad = deg * Float.deg2rad
            let sin = sinf(rad)
            let cos = cosf(rad)
            var mat = SCNMatrix4.identity
            mat.m22 = cos
            mat.m23 = -sin
            mat.m32 = sin
            mat.m33 = cos
            return mat
        }
        func y(_ deg: Float) -> SCNMatrix4 {
            let rad = deg * Float.deg2rad
            let sin = sinf(rad)
            let cos = cosf(rad)
            var mat = SCNMatrix4.identity
            mat.m33 = cos
            mat.m31 = -sin
            mat.m13 = sin
            mat.m11 = cos
            return mat
        }
        func z(_ deg: Float) -> SCNMatrix4 {
            let rad = deg * Float.deg2rad
            let sin = sinf(rad)
            let cos = cosf(rad)
            var mat = SCNMatrix4.identity
            mat.m11 = cos
            mat.m12 = -sin
            mat.m21 = sin
            mat.m22 = cos
            return mat
        }
        return y(euler.y) * x(euler.x) * z(euler.z)
    }
    
    static func scale(scale: SCNVector3) -> SCNMatrix4 {
        SCNMatrix4.identity.scaled(scale)
    }
    
    static func translate(vec: SCNVector3) -> SCNMatrix4 {
        SCNMatrix4.identity.translated(vec)
    }
}

extension Float {
    // https://docs.unity3d.com/ja/current/ScriptReference/Mathf.Deg2Rad.html
    static var deg2rad: Float {
        (.pi * 2.0) / 360.0
    }
    
    static var rad2deg: Float {
        360.0 / (.pi * 2.0)
    }
}
