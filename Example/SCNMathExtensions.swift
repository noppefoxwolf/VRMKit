// SCNMathExtensions
// @author: Slipp Douglas Thompson
// @license: Public Domain per The Unlicense.  See accompanying LICENSE file or <http://unlicense.org/>.

import SceneKit

import simd



/// On macOS, SceneKit types use `CGFloat`, which can either be a 32-bit `Float` or a 64-bit `Double`; however, on iOS/tvOS/watchOS, SceneKit types just use `Float`.
/// Because of this, we need to do some finagling to get these extension to work on all platform— and a `SCNFloat` typealias is the cleanest way I found to minimize the amount of `#if` junk below.
#if os(macOS)
    #if (arch(x86_64))
        public typealias SCNSimdFloat3 = double3
    #else
        public typealias SCNSimdFloat3 = float3
    #endif
#else
    public typealias SCNSimdFloat3 = SIMD3<Float>
    
    extension SCNFloat
    {
        typealias NativeType = Float
        var native:NativeType { return self }
    }
#endif



// MARK: Type Conversions

extension SCNVector3 {
    public func toSimd() -> SCNSimdFloat3 {
        SCNSimdFloat3(self)
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




// MARK: SCNVector3 Extensions

// NOTE: Methods below are ordered alphabetically (by base operation name).
//     Decided that this is better than grouping by category because those groupings are somewhat subjective, change with each Swift version (if based on protocols), and this just seemed simpler.  Maybe I'll reorg this in the future though.
extension SCNVector3
{
    public static let zero = SCNVector3Zero
    
    
    // MARK: Add
    
    public static func + (a:SCNVector3, b:SCNVector3) -> SCNVector3 { return a.added(to: b) }
    public func added(to other:SCNVector3) -> SCNVector3 {
        return (self.toSimd() + other.toSimd()).toSCN()
    }
    public static func += (v:inout SCNVector3, o:SCNVector3) { v.add(o) }
    public mutating func add(_ other:SCNVector3) {
        self = self.added(to: other)
    }
    
    // MARK: Cross Product
    
    public func crossProduct(_ other:SCNVector3) -> SCNVector3 {
        return simd.cross(self.toSimd(), other.toSimd()).toSCN()
    }
    public mutating func formCrossProduct(_ other:SCNVector3) {
        self = self.crossProduct(other)
    }
    public static func crossProductOf(_ a:SCNVector3, _ b:SCNVector3) -> SCNVector3 {
        return a.crossProduct(b)
    }
    
    // MARK: Divide
    
    public static func / (a:SCNVector3, b:SCNVector3) -> SCNVector3 { return a.divided(by: b) }
    public func divided(by other:SCNVector3) -> SCNVector3 {
        return (self.toSimd() / other.toSimd()).toSCN()
    }
    public static func / (a:SCNVector3, b:SCNFloat) -> SCNVector3 { return a.divided(by: b) }
    public func divided(by scalar:SCNFloat) -> SCNVector3 {
        return (self.toSimd() * recip(scalar.native)).toSCN()
    }
    public static func /= (v:inout SCNVector3, o:SCNVector3) { v.divide(by: o) }
    public mutating func divide(by other:SCNVector3) {
        self = self.divided(by: other)
    }
    public static func /= (v:inout SCNVector3, o:SCNFloat) { v.divide(by: o) }
    public mutating func divide(by scalar:SCNFloat) {
        self = self.divided(by: scalar)
    }
    
    // MARK: Dot Product
    
    public func dotProduct(_ other:SCNVector3) -> SCNFloat {
        return SCNFloat(simd.dot(self.toSimd(), other.toSimd()))
    }
    public static func dotProductOf(_ a:SCNVector3, _ b:SCNVector3) -> SCNFloat {
        return a.dotProduct(b)
    }
    
    // MARK: Is… Flags
    
    public var isFinite:Bool {
        return self.x.isFinite && self.y.isFinite && self.z.isFinite
    }
    public var isInfinite:Bool {
        return self.x.isInfinite || self.y.isInfinite || self.z.isInfinite
    }
    public var isNaN:Bool {
        return self.x.isNaN || self.y.isNaN || self.z.isNaN
    }
    public var isZero:Bool {
        return self.x.isZero && self.y.isZero && self.z.isZero
    }
    
    // MARK: Magnitude
    
    public func magnitude() -> SCNFloat {
        return SCNFloat(simd.length(self.toSimd()))
    }
    public func magnitudeSquared() -> SCNFloat {
        return SCNFloat(simd.length_squared(self.toSimd()))
    }
    
    // MARK: Mix
    
    public func mixed(with other:SCNVector3, ratio:SCNFloat) -> SCNVector3 {
        return simd.mix(self.toSimd(), other.toSimd(), t: ratio.native).toSCN()
    }
    public mutating func mix(with other:SCNVector3, ratio:SCNFloat) {
        self = self.mixed(with: other, ratio: ratio)
    }
    public static func mixOf(_ a:SCNVector3, _ b:SCNVector3, ratio:SCNFloat) -> SCNVector3 {
        return a.mixed(with: b, ratio: ratio)
    }
    
    // MARK: Multiply
    
    public static func * (a:SCNVector3, b:SCNVector3) -> SCNVector3 { return a.multiplied(by: b) }
    public func multiplied(by other:SCNVector3) -> SCNVector3 {
        return (self.toSimd() * other.toSimd()).toSCN()
    }
    public static func * (a:SCNVector3, b:SCNFloat) -> SCNVector3 { return a.multiplied(by: b) }
    public func multiplied(by scalar:SCNFloat) -> SCNVector3 {
        return (self.toSimd() * scalar.native).toSCN()
    }
    public static func *= (v:inout SCNVector3, o:SCNVector3) { v.multiply(by: o) }
    public mutating func multiply(by other:SCNVector3) {
        self = self.multiplied(by: other)
    }
    public static func *= (v:inout SCNVector3, o:SCNFloat) { v.multiply(by: o) }
    public mutating func multiply(by scalar:SCNFloat) {
        self = self.multiplied(by: scalar)
    }
    
    // MARK: Invert
    
    public static prefix func - (v:SCNVector3) -> SCNVector3 { return v.inverted() }
    public func inverted() -> SCNVector3 {
        return (SCNSimdFloat3(0, 0, 0) - self.toSimd()).toSCN()
    }
    public mutating func invert() {
        self = self.inverted()
    }
    
    // MARK: Normalize
    
    public func normalized() -> SCNVector3 {
        return simd.normalize(self.toSimd()).toSCN()
    }
    public mutating func normalize() {
        self = self.normalized()
    }
    
    // MARK: Project
    
    public func projected(onto other:SCNVector3) -> SCNVector3 {
        return simd.project(self.toSimd(), other.toSimd()).toSCN()
    }
    public mutating func project(onto other:SCNVector3) {
        self = self.projected(onto: other)
    }
    
    // MARK: Reflect
    
    public func reflected(normal:SCNVector3) -> SCNVector3 {
        return simd.reflect(self.toSimd(), n: normal.toSimd()).toSCN()
    }
    public mutating func reflect(normal:SCNVector3) {
        self = self.reflected(normal: normal)
    }
    
    // MARK: Refract
    
    public func refracted(normal:SCNVector3, refractiveIndex:SCNFloat) -> SCNVector3 {
        return simd.refract(self.toSimd(), n: normal.toSimd(), eta: refractiveIndex.native).toSCN()
    }
    public mutating func refract(normal:SCNVector3, refractiveIndex:SCNFloat) {
        self = self.refracted(normal: normal, refractiveIndex: refractiveIndex)
    }
    
    // MARK: Replace
    
    public mutating func replace(x:SCNFloat?=nil, y:SCNFloat?=nil, z:SCNFloat?=nil) {
        if let xValue = x { self.x = xValue }
        if let yValue = y { self.y = yValue }
        if let zValue = z { self.z = zValue }
    }
    public func replacing(x:SCNFloat?=nil, y:SCNFloat?=nil, z:SCNFloat?=nil) -> SCNVector3 {
        return SCNVector3(
            x ?? self.x,
            y ?? self.y,
            z ?? self.z
        )
    }
    
    // MARK: Subtract
    
    public static func - (a:SCNVector3, b:SCNVector3) -> SCNVector3 { return a.subtracted(by: b) }
    public func subtracted(by other:SCNVector3) -> SCNVector3 {
        return (self.toSimd() - other.toSimd()).toSCN()
    }
    public static func -= (v:inout SCNVector3, o:SCNVector3) { v.subtract(o) }
    public mutating func subtract(_ other:SCNVector3) {
        self = self.subtracted(by: other)
    }
}


extension SCNVector3 : Equatable
{
    public static func == (a:SCNVector3, b:SCNVector3) -> Bool {
        return SCNVector3EqualToVector3(a, b)
    }
}



// MARK: SCNQuaternion Extensions

// NOTE: Methods below are ordered alphabetically (by base operation name).
//     Decided that this is better than grouping by category because those groupings are somewhat subjective, change with each Swift version (if based on protocols), and this just seemed simpler.  Maybe I'll reorg this in the future though.
extension SCNQuaternion
{
    public static let identity:SCNQuaternion = GLKQuaternionIdentity.toSCN()
    public static let identityFacingVector:SCNVector3 = SCNVector3(0, 0, -1)
    public static let identityUpVector:SCNVector3 = SCNVector3(0, 1, 0)
    
    
    public init(from a:SCNVector3, to b:SCNVector3, opposing180Axis:SCNVector3=identityUpVector) {
        let aNormal = a.normalized(), bNormal = b.normalized()
        let dotProduct = aNormal.dotProduct(bNormal)
        if dotProduct >= 1.0 {
            self = GLKQuaternionIdentity.toSCN()
        }
        else if dotProduct < (-1.0 + SCNFloat.leastNormalMagnitude) {
            self = GLKQuaternionMakeWithAngleAndVector3Axis(Float.pi, opposing180Axis.toGLK()).toSCN()
        }
        else {
            // from: https://bitbucket.org/sinbad/ogre/src/9db75e3ba05c/OgreMain/include/OgreVector3.h?fileviewer=file-view-default#OgreVector3.h-651
            // looks to be explained at: http://lolengine.net/blog/2013/09/18/beautiful-maths-quaternion-from-vectors
            let s = sqrt((1.0 + dotProduct) * 2.0)
            let xyz = aNormal.crossProduct(bNormal) / s
            self = SCNQuaternion(xyz.x, xyz.y, xyz.z, (s * 0.5))
        }
    }
    
    
    public init(angle angle_rad:SCNFloat, axis axisVector:SCNVector3) {
        self = GLKQuaternionMakeWithAngleAndVector3Axis(Float(angle_rad), axisVector.toGLK()).toSCN()
    }
    
    
    // MARK: Angle-Axis
    
    public func angleAxis() -> (SCNFloat, SCNVector3) {
        let self_glk = self.toGLK()
        let angle = SCNFloat(GLKQuaternionAngle(self_glk))
        let axis = GLKQuaternionAxis(self_glk).toSCN()
        return (angle, axis)
    }
    
    // MARK: Delta
    
    public func delta(_ other:SCNQuaternion) -> SCNQuaternion {
        return -self * other
    }
    
    // MARK: Invert
    
    public static prefix func - (q:SCNQuaternion) -> SCNQuaternion { return q.inverted() }
    public func inverted() -> SCNQuaternion {
        return GLKQuaternionInvert(self.toGLK()).toSCN()
    }
    public mutating func invert() {
        self = self.inverted()
    }
    
    // MARK: Multiply
    
    public static func * (a:SCNQuaternion, b:SCNQuaternion) -> SCNQuaternion { return a.multiplied(by: b) }
    public func multiplied(by other:SCNQuaternion) -> SCNQuaternion {
        return GLKQuaternionMultiply(self.toGLK(), other.toGLK()).toSCN()
    }
    public static func *= (q:inout SCNQuaternion, o:SCNQuaternion) { q.multiply(by: o) }
    public mutating func multiply(by other:SCNQuaternion) {
        self = self.multiplied(by: other)
    }
    
    // MARK: Normalize
    
    public mutating func normalize() {
        self = GLKQuaternionNormalize(self.toGLK()).toSCN()
    }
    
    // MARK: Rotate
    
    public static func * (q:SCNQuaternion, v:SCNVector3) -> SCNVector3 { return q.rotate(vector: v) }
    public func rotate(vector:SCNVector3) -> SCNVector3 {
        return GLKQuaternionRotateVector3(self.toGLK(), vector.toGLK()).toSCN()
    }
}



// MARK: SCNMatrix4 Extensions

// NOTE: Methods below are ordered alphabetically (by base operation name).
//     Decided that this is better than grouping by category because those groupings are somewhat subjective, change with each Swift version (if based on protocols), and this just seemed simpler.  Maybe I'll reorg this in the future though.
extension SCNMatrix4
{
    public static let identity:SCNMatrix4 = SCNMatrix4Identity
    
    
    public init(_ m:SCNMatrix4) {
        self = m
    }
    
    public init(translation:SCNVector3) {
        self = SCNMatrix4MakeTranslation(translation.x, translation.y, translation.z)
    }
    
    public init(rotationAngle angle:SCNFloat, axis:SCNVector3) {
        self = SCNMatrix4MakeRotation(angle, axis.x, axis.y, axis.z)
    }
    
    public init(scale:SCNVector3) {
        self = SCNMatrix4MakeScale(scale.x, scale.y, scale.z)
    }
    
    
    // MARK: Invert
    
    public static prefix func - (m:SCNMatrix4) -> SCNMatrix4 { return m.inverted() }
    public func inverted() -> SCNMatrix4 {
        return SCNMatrix4Invert(self)
    }
    public mutating func invert() {
        self = self.inverted()
    }
    
    // MARK: Is… Flags
    
    public var isIdentity:Bool {
        return SCNMatrix4IsIdentity(self)
    }
    
    // MARK: Multiply
    
    public static func * (a:SCNMatrix4, b:SCNMatrix4) -> SCNMatrix4 { return a.multiplied(by: b) }
    public func multiplied(by other:SCNMatrix4) -> SCNMatrix4 {
        return SCNMatrix4Mult(self, other)
    }
    public static func *= (m:inout SCNMatrix4, o:SCNMatrix4) { m.multiply(by: o) }
    public mutating func multiply(by other:SCNMatrix4) {
        self = self.multiplied(by: other)
    }
    
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
    
    // MARK: Rotate
    
    public func rotated(angle:SCNFloat, axis:SCNVector3) -> SCNMatrix4 {
        return SCNMatrix4Rotate(self, angle, axis.x, axis.y, axis.z)
    }
    public mutating func rotate(angle:SCNFloat, axis:SCNVector3) {
        self = self.rotated(angle: angle, axis: axis)
    }
}


extension SCNMatrix4 : Equatable
{
    public static func == (a:SCNMatrix4, b:SCNMatrix4) -> Bool {
        return SCNMatrix4EqualToMatrix4(a, b)
    }
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
