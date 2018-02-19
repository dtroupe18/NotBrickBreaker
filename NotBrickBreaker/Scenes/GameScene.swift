//
//  GameScene.swift
//  NotBrickBreaker
//
//  Created by Dave on 2/17/18.
//  Copyright © 2018 High Tree Development. All rights reserved.
//

import SpriteKit
import GameplayKit
import AVFoundation
import CoreMotion

let ballCategoryName = "ball"
let paddleCategoryName = "paddle"
let brickCategoryName = "brick"
let tapLabelCategoryName = "tapLabel"

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    let paddle = SKSpriteNode(imageNamed: "Paddle")
    
    let motionManager = CMMotionManager()
    var newX: CGFloat?
    
    // Game Timer
    //
    var timeLabel = SKLabelNode(fontNamed: "ArialMT")
    var timeValue: Int = 0 {
        didSet {
            timeLabel.text = "\(timeValue)"
        }
    }
    
    lazy var gameState: GKStateMachine = GKStateMachine(states: [
        Waiting(scene: self),
        Playing(scene: self),
        GameOver(scene: self) ])
    
    var musicPlayer = AVAudioPlayer()
    
    // Bit Maskes to identify objects in the game
    //
    let ballCategoryBitMask: UInt32 = 0x1 << 0     // 00000000000000000000000000000001
    let bottomCategoryBitMask: UInt32 = 0x1 << 1   // 00000000000000000000000000000010
    let brickCategoryBitMask: UInt32 = 0x1 << 2    // 00000000000000000000000000000100
    let paddleCategoryBitMask: UInt32 = 0x1 << 3   // 00000000000000000000000000001000
    let borderCategoryBitMask: UInt32 = 0x1 << 4   // 00000000000000000000000000010000
    
    // Pre-load sound effects
    //
    let brickHitSound = SKAction.playSoundFileNamed("brickHitSound", waitForCompletion: false)
    let paddleHitSound = SKAction.playSoundFileNamed("paddleHitSound", waitForCompletion: false)
    
    override init(size: CGSize) {
        super.init(size: size)
        
        // Assign contact delegate to this class
        //
        self.physicsWorld.contactDelegate = self
        
        // Marker: Music
        //
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
        
        // Marker: Background
        //
        let bgImage = SKSpriteNode(imageNamed: "Background")
        bgImage.position = CGPoint(x: self.frame.width / 2, y: self.frame.height / 2)
        self.addChild(bgImage)
        
        self.physicsWorld.gravity = CGVector(dx: 0.0, dy: 0.0)
        
        let worldBorder = SKPhysicsBody(edgeLoopFrom: self.frame)
        self.physicsBody = worldBorder
        self.physicsBody?.categoryBitMask = borderCategoryBitMask
        self.physicsBody?.friction = 0
        self.physicsBody?.restitution = 1
        
        // Marker: Time Label
        //
        timeLabel.fontColor = SKColor.white
        timeLabel.fontSize = 40
        timeLabel.position = CGPoint(x: self.frame.size.width - 50, y: self.frame.size.height - 50)
        timeLabel.text = "\(timeValue)"
        self.addChild(timeLabel)
        
        // Marker: Tap to Start
        //
        let tapLabel = SKLabelNode(fontNamed: "ChalkboardSE-Light")
        tapLabel.fontSize = 40
        tapLabel.position = CGPoint(x: self.frame.midX, y: self.frame.midY - 30)
        tapLabel.text = "Tap to start playing"
        tapLabel.name = tapLabelCategoryName
        self.addChild(tapLabel)
        
        gameState.enter(Waiting.self)
        
        // Marker: Ball
        //
        let ball = SKSpriteNode(imageNamed: "Ball")
        ball.size = CGSize(width: 25, height: 25)
        ball.name = ballCategoryName
        ball.position = CGPoint(x: self.frame.size.width / 3, y: self.frame.size.height / 3)
        self.addChild(ball)
    
        ball.physicsBody = SKPhysicsBody(circleOfRadius: ball.frame.width / 2) // (diameter / 2) = radius
        ball.physicsBody?.categoryBitMask = ballCategoryBitMask
        // Detect contact with the bottom of the screen or a brick
        //
        ball.physicsBody?.contactTestBitMask = bottomCategoryBitMask | brickCategoryBitMask | paddleCategoryBitMask | borderCategoryBitMask
        
        ball.physicsBody?.friction = 0
        ball.physicsBody?.allowsRotation = false
        ball.physicsBody?.linearDamping = 0
        ball.physicsBody?.restitution = 1
        // ball.physicsBody?.applyImpulse(CGVector(dx: 4, dy: -4))
        
        // Marker: Ball trail
        //
        let trailNode = SKNode()
        self.addChild(trailNode)

        let trail = SKEmitterNode(fileNamed: "Magic")
        if trail != nil {
            trail!.targetNode = trailNode
            ball.addChild(trail!)
        } 
        
        // Marker: Paddle
        //
        paddle.name = paddleCategoryName
        paddle.position = CGPoint(x: self.frame.midX, y: paddle.frame.height * 2)
        
        paddle.physicsBody = SKPhysicsBody(rectangleOf: paddle.frame.size)
        paddle.physicsBody?.categoryBitMask = paddleCategoryBitMask
        paddle.physicsBody?.friction = 0.4
        paddle.physicsBody?.linearDamping = 0
        paddle.physicsBody?.restitution = 0.1 // Not sure
        paddle.physicsBody?.isDynamic = false
        self.addChild(paddle)
        
        // Marker: Bottom
        //
        let bottomRect = CGRect(x: self.frame.origin.x, y: self.frame.origin.y, width: self.frame.size.width, height: 1.0)
        let bottom = SKNode()
        bottom.physicsBody = SKPhysicsBody(edgeLoopFrom: bottomRect)
        bottom.physicsBody?.categoryBitMask = bottomCategoryBitMask
        self.addChild(bottom)
        
        // Marker: Bricks
        //
        let numberOfRows = 2
        let numberOfBricks = 10
        let brickWidth = SKSpriteNode(imageNamed: "Brick").size.width // 20
        let padding: Float = 20.0
        let offset: Float = (Float(self.frame.size.width) - (Float(brickWidth) * Float(numberOfBricks) + padding * Float(numberOfBricks - 1))) / 2
        
        for row in 1...numberOfRows {
            var yOffset: CGFloat {
                switch row {
                case 1:
                    return self.frame.size.height * 0.8
                case 2:
                    return self.frame.size.height * 0.6
                case 3:
                    return self.frame.size.height * 0.4
                default:
                    return 0
                }
            }
            for col in 1...numberOfBricks {
                let brick = SKSpriteNode(imageNamed: "Brick")
                
                let calcOne: Float = Float(col) - 0.5
                let calcTwo: Float = Float(col) - 1.0
                
                brick.size = CGSize(width: 20, height: 20)
                brick.position = CGPoint(x: CGFloat(calcOne * Float(brick.frame.size.width) + calcTwo * padding + offset), y: yOffset)
                
                brick.physicsBody = SKPhysicsBody(rectangleOf: brick.frame.size)
                brick.physicsBody?.linearDamping = 0
                brick.physicsBody?.allowsRotation = false
                brick.physicsBody?.isDynamic = false // Prevents the ball from slowing down when it hits a brick
                brick.physicsBody?.affectedByGravity = false
                brick.physicsBody?.friction = 0.0
                brick.physicsBody?.categoryBitMask = brickCategoryBitMask
                brick.name = brickCategoryName
                self.addChild(brick)
            }
        }
    }
    
    func startTimer() {
        let wait = SKAction.wait(forDuration: 1.0)
        let block = SKAction.run({
            self.timeValue += 1
        })
        let sequence = SKAction.sequence([wait, block])
        run(SKAction.repeatForever(sequence), withKey: "Timer")
    }
    
    override func update(_ currentTime: TimeInterval) {
        gameState.update(deltaTime: currentTime)
        
        if let xValue = newX {
            let moveAction = SKAction.move(to: CGPoint(x: xValue, y: paddle.position.y), duration: 0.125)
            paddle.run(moveAction)
        }
    }
    
    func manageDeviceMotion() {
        // Move the paddle by tilting the screen
        // Since this game is played in landscape we are concerned with acceleration in the y direction
        //
        if motionManager.isAccelerometerAvailable {
            motionManager.startAccelerometerUpdates(to: OperationQueue.current!, withHandler: { data, error in
                if let data = data {
                    let currentX = self.paddle.position.x
                    self.newX = currentX + CGFloat((data.acceleration.y) * 700)
                    self.newX = max(self.newX!, self.paddle.size.width / 2) // Left most position
                    self.newX = min(self.newX!, self.size.width - self.paddle.size.width / 2) // Right most position
                }
            })
        }
    }
    
    // Marker: Game Starts here
    //
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if gameState.currentState is Waiting {
            print("In waiting state")
            gameState.enter(Playing.self)
            manageDeviceMotion()
            startTimer()
        }
    }
    
    // Marker: SKPhysicsContactDelegate
    //
    func didBegin(_ contact: SKPhysicsContact) {
        var firstBody = SKPhysicsBody()
        var secondBody = SKPhysicsBody()
        
        // BitMask for the ball is always smaller than the BitMask for the bottom
        //
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        if firstBody.categoryBitMask == ballCategoryBitMask && secondBody.categoryBitMask == bottomCategoryBitMask {
            // Game Over - the ball hit the bottom of the screen
            //
            print("Game Over")
            // let gameOverScene = GameOverScene(size: self.frame.size)
            // self.view?.presentScene(gameOverScene)
        }
        
        if firstBody.categoryBitMask == ballCategoryBitMask && secondBody.categoryBitMask == brickCategoryBitMask {
            // Ball hit a brick
            //
            print("ball hit a brick")
            run(brickHitSound)
            secondBody.node?.removeFromParent()
        }
        
        if firstBody.categoryBitMask == ballCategoryBitMask && secondBody.categoryBitMask == paddleCategoryBitMask ||
            secondBody.categoryBitMask == borderCategoryBitMask {
            run(paddleHitSound)
        }
    }
    
    func randomFloat(from: CGFloat, to: CGFloat) -> CGFloat {
        // Used to randomize the starting direction of the ball
        //
        let random: CGFloat = CGFloat(Float(arc4random()) / 0xFFFFFFFF)
        return random * (to - from) + from
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
