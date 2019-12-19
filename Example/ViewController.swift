//
//  ViewController.swift
//  VRMExample
//
//  Created by Tatsuya Tanaka on 20180911.
//  Copyright © 2018年 tattn. All rights reserved.
//

import UIKit
import SceneKit
import VRMKit
import VRMSceneKit

class ViewController: UIViewController {

    @IBOutlet private weak var scnView: SCNView! {
        didSet {
            scnView.autoenablesDefaultLighting = true
            scnView.allowsCameraControl = true
            scnView.showsStatistics = true
            scnView.backgroundColor = UIColor.black
        }
    }
    
    var bs: [VRMSpringBone] = []
    override func viewDidLoad() {
        super.viewDidLoad()

        do {
            let loader = try VRMSceneLoader(named: "AliciaSolid.vrm")
            let scene = try loader.loadScene()
            setupScene(scene)
            scnView.scene = scene
            scnView.delegate = self
            let node = scene.vrmNode
//            node.setBlendShape(value: 1.0, for: .custom("><"))
//            node.humanoid.node(for: .neck)?.eulerAngles = SCNVector3(0, 0, 20 * CGFloat.pi / 180)
//            node.humanoid.node(for: .leftShoulder)?.eulerAngles = SCNVector3(0, 0, 40 * CGFloat.pi / 180)
//            node.humanoid.node(for: .rightShoulder)?.eulerAngles = SCNVector3(0, 0, 40 * CGFloat.pi / 180)
            
            var nodes: [SCNNode] = []
            for boneGroup in node.vrm.secondaryAnimation.boneGroups {
                
                let springBone: VRMSpringBone = VRMSpringBone()
                for index in boneGroup.bones {
                    let node = try! loader.node(withNodeIndex: index)
                    nodes.append(node)
                }
                springBone.rootBones = nodes.map(Transform.init)
                //boneGroup.center-1は無指定でroot選ぶ
                springBone.center = Transform(try! loader.node(withNodeIndex: boneGroup.bones[0]))
                springBone.dragForce = SCNFloat(boneGroup.dragForce)
                springBone.gravityDir = SCNVector3(boneGroup.gravityDir.x, boneGroup.gravityDir.y, boneGroup.gravityDir.z)
                springBone.gravityPower = SCNFloat(boneGroup.gravityPower)
                springBone.stiffnessForce = SCNFloat(boneGroup.stiffiness)
                springBone.awake()
                bs.append(springBone)
            }
            
            node.runAction(SCNAction.repeatForever(SCNAction.sequence([
                SCNAction.move(by: SCNVector3(0, 1, 0), duration: 1.0),
                SCNAction.move(by: SCNVector3(0, -1, 0), duration: 1.0),
            ])))
        } catch {
            print(error)
        }
    }

    private func setupScene(_ scene: SCNScene) {
//        let enviromentLightNode = SCNNode()
//        let enviromentLight = SCNLight()
//        enviromentLightNode.light = enviromentLight
//        enviromentLight.type = .ambient
//        enviromentLight.color = UIColor.white
//        scene.rootNode.addChildNode(enviromentLightNode)
//
//        let pointLightNode = SCNNode()
//        let pointLight = SCNLight()
//        pointLightNode.light = pointLight
//        pointLight.type = .spot
//        pointLight.color = UIColor.white
//        enviromentLight.intensity = 1000
//        enviromentLightNode.position = SCNVector3(x: 0, y: 0, z: -2)
//        scene.rootNode.addChildNode(pointLightNode)

        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)

        cameraNode.position = SCNVector3(0, 0.8, -1.6)
        cameraNode.rotation = SCNVector4(0, 1, 0, Float.pi)
    }
}

extension ViewController: SCNSceneRendererDelegate {
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        Time.shared.update(at: time)
        print(Time.shared.deltaTime)
        bs.forEach({ $0.lateUpdate() })
//        print(bs.first?.center.node.worldPosition)
    }
}
