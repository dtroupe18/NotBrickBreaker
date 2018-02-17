//
//  GameScene.swift
//  NotBrickBreaker
//
//  Created by Dave on 2/17/18.
//  Copyright © 2018 High Tree Development. All rights reserved.
//

import SpriteKit
import AVFoundation

class GameScene: SKScene {
    
    let ballCategoryName = "yellowBall"
    let paddleCategoryName = "paddle"
    let brickCategoryName = "brick"
    
    var musicPlayer = AVAudioPlayer()
    
    override init(size: CGSize) {
        super.init(size: size)
        
        if let backgroundMusicURL = Bundle.main.url(forResource: "BackgroundMusic", withExtension: "wav") {
            do {
              try musicPlayer = AVAudioPlayer(contentsOf: backgroundMusicURL)
                musicPlayer.numberOfLoops = -1
                musicPlayer.prepareToPlay()
                musicPlayer.play()
            }
            catch {
                print("Error Playing Music")
            }
        }
        
        let bgImage = SKSpriteNode(imageNamed: "Background")
        bgImage.position = CGPoint(x: self.frame.width / 2, y: self.frame.height / 2)
        self.addChild(bgImage)
        
        self.physicsWorld.gravity = CGVector(dx: 0.0, dy: 0.0)
        
        let worldBorder = SKPhysicsBody(edgeLoopFrom: self.frame)
        self.physicsBody = worldBorder
        self.physicsBody?.friction = 0
        
        let ball = SKSpriteNode(imageNamed: "Ball")
        ball.size = CGSize(width: 25, height: 25)
        ball.name = ballCategoryName
        ball.position = CGPoint(x: self.frame.size.width / 4, y: self.frame.size.height / 4)
        self.addChild(ball)
        
        ball.physicsBody = SKPhysicsBody(circleOfRadius: ball.frame.width / 2) // (diameter / 2) = radius
        ball.physicsBody?.friction = 0
        ball.physicsBody?.allowsRotation = false
        ball.physicsBody?.linearDamping = 0
        ball.physicsBody?.restitution = 1
        ball.physicsBody?.applyImpulse(CGVector(dx: 10, dy: -10))
        
        let paddle = SKSpriteNode(imageNamed: "Paddle")
        paddle.name = paddleCategoryName
        paddle.position = CGPoint(x: self.frame.midX, y: paddle.frame.height * 2)
        
        self.addChild(paddle)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
