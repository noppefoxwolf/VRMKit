//
//  VRMSpringBone.swift
//  SpringBoneKit
//
//  Created by Tomoya Hirano on 2019/12/20.
//  Copyright © 2019 Tomoya Hirano. All rights reserved.
//

import SceneKit

class Transform: Hashable {
    let node: SCNNode
    
    init(_ node: SCNNode) {
        self.node = node
    }
    
    static func == (lhs: Transform, rhs: Transform) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(node)
    }
}

class VRMSpringBone {
    public let comment: String = ""
    public let stiffnessForce: SCNFloat = 1.0
    public let gravityPower: SCNFloat = 0.0
    public let gravityDir: SCNVector3 = .init(0, -1, 0)
    public let dragForce: SCNFloat = 0.4
    public var center: Transform! = nil
    public var rootBones: [Transform] = []
    var initialLocalRotationMap: [Transform : SCNQuaternion] = [:]
    public let hitRadius: SCNFloat = 0.02
    public let colliderGroups: [VRMSpringBoneColliderGroup] = []
    
    class VRMSpringBoneLogic {
        private let transform: Transform
        public var head: Transform { transform }
        public var tail: SCNVector3 { transform.localToWorldMatrix.multiplyPoint(boneAxis * length) }
        var length: SCNFloat!
        var currentTail: SCNVector3!
        var prevTail: SCNVector3!
        var localDir: SCNVector3!
        public var localRotation: SCNQuaternion!
        public var boneAxis: SCNVector3!
        public var radius: SCNFloat!
        
        init(center: Transform?, transform: Transform, localChildPosition: SCNVector3) {
            self.transform = transform
            let worldChildPosition = transform.transformPoint(localChildPosition)
            currentTail = center?.inverseTransformPoint(worldChildPosition) ?? worldChildPosition
            prevTail = currentTail
            localRotation = transform.localRotation
            boneAxis = localChildPosition.normalized()
            length = localChildPosition.magnitude()
        }
        
        var parentRotation: SCNQuaternion {
            transform.parent?.rotation ?? SCNQuaternion.identity
        }
        
        func update(center: Transform?, stiffnessForce: SCNFloat, dragForce: SCNFloat, external: SCNVector3, colliders: [SphereCollider]) {
            let currentTail: SCNVector3 = center?.transformPoint(self.currentTail) ?? self.currentTail
            let prevTail: SCNVector3 = center?.transformPoint(self.prevTail) ?? self.prevTail
            // verlet積分で次の位置を計算
            var nextTail: SCNVector3 = currentTail
                + (currentTail - prevTail) * (1.0 - dragForce) // 前フレームの移動を継続する(減衰もあるよ)
                + parentRotation * localRotation * boneAxis * stiffnessForce // 親の回転による子ボーンの移動目標
                + external // 外力による移動量
            
            // 長さをboneLengthに強制
            nextTail = transform.position + (nextTail - transform.position).normalized() * length
            
            // Collisionで移動
            nextTail = collision(colliders, nextTail: nextTail)
            
            self.prevTail = center?.inverseTransformPoint(currentTail) ?? currentTail
            self.currentTail = center?.inverseTransformPoint(nextTail) ?? nextTail
            
            // 回転を適用
            head.rotation = applyRotation(nextTail)
        }
        
        func applyRotation(_ nextTail: SCNVector3) -> SCNQuaternion {
            let rotation = parentRotation * localRotation
            return SCNQuaternion(from: rotation * boneAxis, to: nextTail - transform.position) * rotation
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
                    nextTail = transform.position + (posFromCollider - transform.position).normalized() * length
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
                    kv.key.localRotation = kv.value
                }
                initialLocalRotationMap = [:]
            }
            verlet = []
            
            for go in rootBones {
                for x in go.transform.traverse {
                    initialLocalRotationMap[x] = x.localRotation
                }
                setupRecursive(center: center, parent: go)
            }
        }
    }
    
    func setLocalRotationsIdentity() {
        for verlet in verlet {
            verlet.head.localRotation = SCNQuaternion.identity
        }
    }
    
    static func getChildren(parent: Transform) -> [Transform] {
        var res: [Transform] = []
        for i in 0..<parent.childCount {
            res.append(parent.getChild(i))
        }
        return res
    }
    
    func setupRecursive(center: Transform, parent: Transform) {
        if parent.childCount == 0 {
            let delta: SCNVector3 = parent.position - parent.parent!.position
            let childPosition = parent.position + delta.normalized() * 0.07
            verlet.append(VRMSpringBone.VRMSpringBoneLogic(center: center, transform: parent, localChildPosition: parent.worldToLocalMatrix.multiplyPoint(childPosition)))
        } else {
            let firstChild = VRMSpringBone.getChildren(parent: parent).first
            let localPosition = firstChild!.localPosition
            let scale = firstChild!.lossyScale
            verlet.append(VRMSpringBone.VRMSpringBoneLogic(center: center, transform: parent, localChildPosition: SCNVector3(localPosition.x * scale.x, localPosition.y * scale.y, localPosition.z * scale.z)))
        }
        
        //http://narudesign.com/devlog/unity-child-object-only/
        for child in parent.children {
            setupRecursive(center: center, parent: child)
        }
    }
    
    struct SphereCollider {
        let position: SCNVector3
        let radius: SCNFloat
    }
    
    var colliderList: [SphereCollider] = []
    
    func lateUpdate() {
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
        let stiffness = stiffnessForce * SCNFloat(Time.shared.deltaTime)
        let external = gravityDir * (gravityPower * SCNFloat(Time.shared.deltaTime))
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

class Time {
    static let shared: Time = .init()
    private var lastUpdateTime: TimeInterval = 0
    func update(at time: TimeInterval) {
        if lastUpdateTime == 0 {
            lastUpdateTime = time
        }
        let deltaTime: TimeInterval = time - lastUpdateTime
        self.deltaTime = deltaTime
    }
    private(set) var deltaTime: TimeInterval = 0
}

class MonoBehaviour {
    var transform: Transform!
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

extension Transform {
    var position: SCNVector3 {
        node.worldPosition
    }
    
    // http://light11.hatenadiary.com/entry/2019/03/09/182229
    // https://github.com/n-yoda/unity-transform/blob/master/Assets/TransformMatrix/TransformMatrix.cs
    var localToWorldMatrix: SCNMatrix4 {
        node.worldTransform
    }
    
    //https://github.com/michidk/BrokenEngine/blob/master/BrokenEngine/GameObject.cs#L99
    var worldToLocalMatrix: SCNMatrix4 {
        node.transform
    }
    
    //http://edom18.hateblo.jp/entry/2018/04/26/214315
    func transformPoint(_ point: SCNVector3) -> SCNVector3 {
        localToWorldMatrix.multiplyPoint(point)
    }
    
    // https://github.com/google-ar/arcore-android-sdk/issues/570
    // http://edom18.hateblo.jp/entry/2018/04/26/214315
    func inverseTransformPoint(_ point: SCNVector3) -> SCNVector3 {
        let m: SCNMatrix4 = transform.worldToLocalMatrix
        let r: SCNVector3 = m.multiplyPoint(point)
        return r
    }
    
    var localRotation: SCNQuaternion {
        get { node.orientation }
        set { node.orientation = newValue }
    }
    
    var parent: Transform? { //ここの方怪しい
        guard let parent = node.parent else { return nil }
        return Transform(parent)
    }
    
    var rotation: SCNQuaternion {
        get { node.worldOrientation }
        set { node.worldOrientation = newValue }
    }
    
    var transform: Transform {
        self
    }
    
    var traverse: [Transform] {
        node.childNodes.map(Transform.init)
    }
    
    var childCount: Int {
        node.childNodes.count
    }
    
    func getChild(_ i: Int) -> Transform {
        Transform(node.childNodes[i])
    }
    
    var localPosition: SCNVector3 {
        node.position
    }
    
    // TODO: Worldのscaleを返す
    var lossyScale: SCNVector3 {
        node.scale
    }
    
    var children: [Transform] {
        node.childNodes.map(Transform.init)
    }
}
