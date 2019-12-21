//
//  SCNNode+.swift
//  VRMSceneKit
//
//  Created by Tomoya Hirano on 2019/12/21.
//  Copyright © 2019 tattn. All rights reserved.
//

import SceneKit

extension SCNNode {
    var localToWorldMatrix: SCNMatrix4 {
        (parent?.localToParentMatrix ?? SCNMatrix4Identity) * self.localToParentMatrix
    }
    
    var worldToLocalMatrix: SCNMatrix4 {
        localToWorldMatrix.inverted
    }
    
    func transformPoint(_ point: SCNVector3) -> SCNVector3 {
        localToWorldMatrix * point
    }
    
    func inverseTransformPoint(_ point: SCNVector3) -> SCNVector3 {
        worldToLocalMatrix * point
    }
}

extension SCNNode {
    var localToParentMatrix: SCNMatrix4 {
        SCNMatrix4Identity.translated(position) * SCNMatrix4Identity.rotated(angle: 0, rotate: eulerAngles) * SCNMatrix4Identity.scaled(scale)
    }
}

extension SCNMatrix4: CustomDebugStringConvertible {
    public var debugDescription: String {
        """
        ⎡\(m11) \(m12) \(m13) \(m14)⎤
        ⎢\(m21) \(m22) \(m23) \(m24)⎥
        ⎢\(m31) \(m32) \(m33) \(m34)⎥
        ⎣\(m41) \(m42) \(m43) \(m44)⎦
        """
    }
}
extension simd_float4x4: CustomDebugStringConvertible, CustomStringConvertible {
    public var description: String { debugDescription }
    public var debugDescription: String {
        """
        ⎡\(columns.0.x) \(columns.1.x) \(columns.2.x) \(columns.3.x)⎤
        ⎢\(columns.0.y) \(columns.1.y) \(columns.2.y) \(columns.3.y)⎥
        ⎢\(columns.0.z) \(columns.1.z) \(columns.2.z) \(columns.3.z)⎥
        ⎣\(columns.0.w) \(columns.1.w) \(columns.2.w) \(columns.3.w)⎦
        """
    }
}
