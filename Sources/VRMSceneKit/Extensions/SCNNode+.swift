//
//  SCNNode+.swift
//  VRMSceneKit
//
//  Created by Tomoya Hirano on 2019/12/21.
//  Copyright © 2019 tattn. All rights reserved.
//

import SceneKit

extension SCNNode {
    
    // http://light11.hatenadiary.com/entry/2019/03/09/182229
    // https://github.com/n-yoda/unity-transform/blob/master/Assets/TransformMatrix/TransformMatrix.cs
    var localToWorldMatrix: SCNMatrix4 {
        SCNNode.localToParent(transform: parent!) * SCNNode.localToParent(transform: self)
    }
    
    //https://github.com/michidk/BrokenEngine/blob/master/BrokenEngine/GameObject.cs#L99
    var worldToLocalMatrix: SCNMatrix4 {
        localToWorldMatrix.inverted
    }
    
    //http://edom18.hateblo.jp/entry/2018/04/26/214315
    func transformPoint(_ point: SCNVector3) -> SCNVector3 {
        localToWorldMatrix * point
    }
    
    // https://github.com/google-ar/arcore-android-sdk/issues/570
    // http://edom18.hateblo.jp/entry/2018/04/26/214315
    func inverseTransformPoint(_ point: SCNVector3) -> SCNVector3 {
        worldToLocalMatrix * point
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
            var mat = SCNMatrix4Identity
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
            var mat = SCNMatrix4Identity
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
            var mat = SCNMatrix4Identity
            mat.m11 = cos
            mat.m12 = -sin
            mat.m21 = sin
            mat.m22 = cos
            return mat
        }
        return y(euler.y) * x(euler.x) * z(euler.z)
    }
    
    static func scale(scale: SCNVector3) -> SCNMatrix4 {
        SCNMatrix4Identity.scaled(scale)
    }
    
    static func translate(vec: SCNVector3) -> SCNMatrix4 {
        SCNMatrix4Identity.translated(vec)
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
