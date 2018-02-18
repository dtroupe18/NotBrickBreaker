//
//  Waiting.swift
//  NotBrickBreaker
//
//  Created by Dave on 2/18/18.
//  Copyright © 2018 High Tree Development. All rights reserved.
//

import SpriteKit
import GameplayKit

class Waiting: GKState {
    // This state represents the game before the user has started playing
    //
    unowned let scene: GameScene 
    
    init(scene: SKScene) {
        self.scene = scene as! GameScene
        super.init()
    }
    
    override func didEnter(from previousState: GKState?) {
        let scale = SKAction.scale(to: 1.0, duration: 0.25)
        scene.childNode(withName: tapLabelCategoryName)?.run(scale)
    }
    
    override func willExit(to nextState: GKState) {
        if nextState is Playing {
            let scale = SKAction.scale(to: 0, duration: 0.4)
            scene.childNode(withName: tapLabelCategoryName)?.run(scale)
        }
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is Playing.Type
    }

}
