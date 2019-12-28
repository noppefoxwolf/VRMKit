//
//  Timer.swift
//  VRMSceneKit
//
//  Created by Tomoya Hirano on 2019/12/29.
//  Copyright © 2019 tattn. All rights reserved.
//

import Foundation

public class Timer {
    private(set) var lastUpdateTime = TimeInterval()
    
    public init() {}
    
    public func deltaTime(updateAtTime time: TimeInterval) -> TimeInterval {
        if lastUpdateTime == 0 {
            lastUpdateTime = time
        }
        let deltaTime: TimeInterval = time - lastUpdateTime
        lastUpdateTime = time
        return deltaTime
    }
}
