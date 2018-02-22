//
//  GameOver.swift
//  NotBrickBreaker
//
//  Created by Dave on 2/18/18.
//  Copyright © 2018 High Tree Development. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameOver: GKState {
    
    unowned let scene: GameScene

    init(scene: SKScene) {
        self.scene = scene as! GameScene
        super.init()
    }
    
    override func didEnter(from previousState: GKState?) {
        //
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is Waiting.Type
    }

}
