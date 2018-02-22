//
//  Playing.swift
//  NotBrickBreaker
//
//  Created by Dave on 2/18/18.
//  Copyright © 2018 High Tree Development. All rights reserved.
//

import SpriteKit
import GameplayKit

class Playing: GKState {
    
    unowned let scene: GameScene
    let speedFactor: CGFloat = 3.5
    
    init(scene: SKScene) {
        self.scene = scene as! GameScene
        super.init()
    }
    
    override func didEnter(from previousState: GKState?) {
        if let ball = scene.childNode(withName: ballCategoryName) as? SKSpriteNode {
            ball.physicsBody?.applyImpulse(CGVector(dx: randomStartingDirection(), dy: randomStartingDirection()))
        }
        
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        if let ball = scene.childNode(withName: ballCategoryName) as? SKSpriteNode {
            if ball.physicsBody != nil {
            
                let xSpeed = sqrt(ball.physicsBody!.velocity.dx * ball.physicsBody!.velocity.dx)
                let ySpeed = sqrt(ball.physicsBody!.velocity.dy * ball.physicsBody!.velocity.dy)
                
                let speed = sqrt(ball.physicsBody!.velocity.dx * ball.physicsBody!.velocity.dx +
                ball.physicsBody!.velocity.dy * ball.physicsBody!.velocity.dy)
                
                // Prevent the ball from getting trapped vertically or horizontally
                // Add a force in the x or y direction if needed
                //
                if xSpeed <= 10.0 {
                    ball.physicsBody?.applyImpulse(CGVector(dx: randomStartingDirection(), dy: 0.0))
                }
                if ySpeed <= 10.0 {
                    ball.physicsBody?.applyImpulse(CGVector(dx: 0.0, dy: randomStartingDirection()))
                }
                
                // print("Ball speed: \(speed)")
                
                if speed > maxVelocity {
                    ball.physicsBody?.linearDamping = 0.4
                } else {
                    ball.physicsBody?.linearDamping = 0.0
                }
            }
        }
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is GameOver.Type
    }
    
    
    func randomStartingDirection() -> CGFloat {
        if scene.randomFloat(from: 0.0, to: 100.0) >= 50 {
            return -speedFactor
        } else {
            return speedFactor
        }
    }
}
