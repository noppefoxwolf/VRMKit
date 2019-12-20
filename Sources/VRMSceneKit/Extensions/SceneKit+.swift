//
//  SceneKit+.swift
//  VRMSceneKit
//
//  Created by Tatsuya Tanaka on 20180911.
//  Copyright © 2018年 tattn. All rights reserved.
//

import SceneKit
import SpriteKit

extension SCNVector3 {
    static func + (_ left: SCNVector3, _ right: SCNVector3) -> SCNVector3 {
        return SCNVector3(left.x + right.x, left.y + right.y, left.z + right.z)
    }

    static func - (_ left: SCNVector3, _ right: SCNVector3) -> SCNVector3 {
        return SCNVector3(left.x - right.x, left.y - right.y, left.z - right.z)
    }

    static func * (_ left: SCNVector3, _ value: SCNFloat) -> SCNVector3 {
        return SCNVector3(left.x * value, left.y * value, left.z * value)
    }

    static func / (_ left: SCNVector3, _ value: SCNFloat) -> SCNVector3 {
        return left * (1.0 / value)
    }

    static func += (_ left: inout SCNVector3, _ right: SCNVector3) {
        left = left + right
    }

    static func -= (_ left: inout SCNVector3, _ right: SCNVector3) {
        left = left - right
    }

    static func *= (_ left: inout SCNVector3, _ right: SCNFloat) {
        left = left * right
    }

    static func /= (_ left: inout SCNVector3, _ right: SCNFloat) {
        left = left / right
    }

    var length: SCNFloat {
        return SCNFloat(sqrtf(x * x + y * y + z * z))
    }

    var normalized: SCNVector3 {
        return self * (1.0 / length)
    }

    mutating func normalize() {
        self = normalized
    }
    
    var magnitude: SCNFloat {
        SCNFloat(simd.length(self.toSimd()))
    }
    
    var magnitudeSquared: SCNFloat {
        SCNFloat(simd.length_squared(self.toSimd()))
    }
}

func cross(_ left: SCNVector3, _ right: SCNVector3) -> SCNVector3 {
    return SCNVector3(left.y * right.z - left.z * right.y, left.z * right.x - left.x * right.z, left.x * right.y - left.y * right.x)
}

func normal(_ v0: SCNVector3, _ v1: SCNVector3, _ v2: SCNVector3) -> SCNVector3 {
    let e1 = v1 - v0
    let e2 = v2 - v0
    let n = cross(e1, e2)

    return n.normalized
}

func dot(_ left: SCNVector3, _ right: SCNVector3) -> SCNFloat {
    SCNFloat(simd.dot(left.toSimd(), right.toSimd()))
}

extension SCNMaterial {
    static var `default`: SCNMaterial {
        let material = SCNMaterial()
        material.diffuse.contents = SKColor(red: 1, green: 1, blue: 1, alpha: 1)
        material.metalness.contents = SKColor(white: 1, alpha: 1)
        material.roughness.contents = SKColor(white: 1, alpha: 1)
        material.isDoubleSided = false
        material.lightingModel = .physicallyBased
        return material
    }
}

extension SCNMatrix4 {
    init(_ v: [SCNFloat]) throws {
        guard v.count == 16 else { throw "SCNMatrix4: values.count must be 16" }
        self.init(m11: v[0], m12: v[1], m13: v[2], m14: v[3],
                  m21: v[4], m22: v[5], m23: v[6], m24: v[7],
                  m31: v[8], m32: v[9], m33: v[10], m34: v[11],
                  m41: v[12], m42: v[13], m43: v[14], m44: v[15])
    }
    
    static func * (_ left: SCNMatrix4, _ value: SCNVector3) -> SCNVector3 {
        let vector3: SCNVector3 = SCNVector3(
            (left.m11 *  value.x +  left.m12 *  value.y +  left.m13 *  value.z) + left.m14,
            (left.m21 *  value.x +  left.m22 *  value.y +  left.m23 *  value.z) + left.m24,
            (left.m31 *  value.x +  left.m32 *  value.y +  left.m33 *  value.z) + left.m34
        )
        let num: Float = 1.0 / ( ( left.m41 *  value.x +  left.m42 *  value.y +  left.m43 *  value.z) + left.m44)
        return vector3 * num
    }
    
    static func * (_ left: SCNMatrix4, right: SCNMatrix4) -> SCNMatrix4 {
        SCNMatrix4Mult(left, right)
    }

    var inverted: SCNMatrix4 {
        SCNMatrix4Invert(self)
    }
}

extension SCNQuaternion {
    static let identity: SCNQuaternion = GLKQuaternionIdentity.toSCN()
    static let identityUpVector:SCNVector3 = SCNVector3(0, 1, 0)
    
    init(from: SCNVector3, to: SCNVector3, opposing180Axis:SCNVector3 = identityUpVector) {
        let fromNormal = from.normalized, toNormal = to.normalized
        let dotProduct = dot(fromNormal, toNormal)
        if dotProduct >= 1.0 {
            self = GLKQuaternionIdentity.toSCN()
        } else if dotProduct < (-1.0 + SCNFloat.leastNormalMagnitude) {
            self = GLKQuaternionMakeWithAngleAndVector3Axis(Float.pi, opposing180Axis.toGLK()).toSCN()
        } else {
            let s = sqrt((1.0 + dotProduct) * 2.0)
            let xyz = cross(fromNormal, toNormal) / s
            self = SCNQuaternion(xyz.x, xyz.y, xyz.z, (s * 0.5))
        }
    }
    
    static func * (_ left: SCNQuaternion, _ right: SCNQuaternion) -> SCNQuaternion {
        GLKQuaternionMultiply(left.toGLK(), right.toGLK()).toSCN()
    }
    
    static func * (_ left: SCNQuaternion, _ right: SCNVector3) -> SCNVector3 {
        GLKQuaternionRotateVector3(left.toGLK(), right.toGLK()).toSCN()
    }
    
    mutating func normalize() {
        self = GLKQuaternionNormalize(self.toGLK()).toSCN()
    }
}

extension String: Error {}












// SCNMathExtensions
// @author: Slipp Douglas Thompson
// @license: Public Domain per The Unlicense.  See accompanying LICENSE file or <http://unlicense.org/>.

import SceneKit
import simd



// MARK: Type Conversions

extension SCNVector3 {
    public func toSimd() -> SIMD3<Float> {
        SIMD3<Float>(self)
    }
    public func toGLK() -> GLKVector3 {
        SCNVector3ToGLKVector3(self)
    }
}
extension SIMD3 where Scalar == Float {
    public func toSCN() -> SCNVector3 {
        SCNVector3(self)
    }
}

extension SIMD3 where Scalar == Double {
    public func toSCN() -> SCNVector3 {
        SCNVector3(self)
    }
}

extension GLKVector3 {
    public func toSCN() -> SCNVector3 {
        SCNVector3FromGLKVector3(self)
    }
}

extension SCNQuaternion {
    public var q:(Float,Float,Float,Float) {
        return (Float(self.x), Float(self.y), Float(self.z), Float(self.w))
    }
    public init(q:(Float,Float,Float,Float)) {
        self.init(x: SCNFloat(q.0), y: SCNFloat(q.1), z: SCNFloat(q.2), w: SCNFloat(q.3))
    }
    
    public func toGLK() -> GLKQuaternion {
        return GLKQuaternion(q: self.q)
    }
}
extension GLKQuaternion {
    public func toSCN() -> SCNQuaternion {
        return SCNQuaternion(q: self.q)
    }
}

extension SCNMatrix4 {
    public func toSimd() -> float4x4 {
        float4x4(self)
    }
    public func toGLK() -> GLKMatrix4 {
        SCNMatrix4ToGLKMatrix4(self)
    }
}
extension float4x4 {
    public func toSCN() -> SCNMatrix4 {
        SCNMatrix4(self)
    }
}
extension GLKMatrix4 {
    public func toSCN() -> SCNMatrix4 {
        SCNMatrix4FromGLKMatrix4(self)
    }
}




extension SCNMatrix4 {
    
    // MARK: Translate
    
    public func translated(_ translation:SCNVector3) -> SCNMatrix4 {
        return SCNMatrix4Translate(self, translation.x, translation.y, translation.z)
    }
    public mutating func translate(_ translation:SCNVector3) {
        self = self.translated(translation)
    }
    
    // MARK: Scale
    
    public func scaled(_ scale:SCNVector3) -> SCNMatrix4 {
        return SCNMatrix4Scale(self, scale.x, scale.y, scale.z)
    }
    public mutating func scale(_ scale:SCNVector3) {
        self = self.scaled(scale)
    }
}


