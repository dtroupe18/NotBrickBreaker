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
let easyLabelCategoryName = "easyLabel"
let mediumLabelCategoryName = "mediumLabel"
let hardLabelCategoryName = "hardLabel"

let maxVelocity: CGFloat = 300.0

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    let ball = SKSpriteNode(imageNamed: "Ball")
    let paddle = SKSpriteNode(imageNamed: "Paddle")
    let playButton = SKSpriteNode(imageNamed: "PlayButton")
    
    let easyLabel = SKLabelNode(fontNamed: "ChalkboardSE-Light")
    let mediumLabel = SKLabelNode(fontNamed: "ChalkboardSE-Light")
    let hardLabel = SKLabelNode(fontNamed: "ChalkboardSE-Light")
    
    var isHardGame: Bool = false
    
    // Only used in a Hard game
    //
    var initialDx: CGFloat = 0.0
    var initialDy: CGFloat = 0.0
    
    let motionManager = CMMotionManager()
    var newX: CGFloat?
    
    // Game Timer (score)
    //
    var timeLabel = SKLabelNode(fontNamed: "ArialMT")
    var timeValue: Int = 0 {
        didSet {
            timeLabel.text = "\(timeValue)"
        }
    }
    
    static var score: Int = 0
    
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
        
        // Marker: Easy, Medium, Hard
        //
        easyLabel.fontSize = 30
        easyLabel.position = CGPoint(x: self.frame.midX, y: self.frame.midY + 50)
        easyLabel.text = "Easy"
        easyLabel.name = easyLabelCategoryName
        self.addChild(easyLabel)
        
        mediumLabel.fontSize = 30
        mediumLabel.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
        mediumLabel.text = "Medium"
        mediumLabel.name = mediumLabelCategoryName
        self.addChild(mediumLabel)
        
        hardLabel.fontSize = 30
        hardLabel.position = CGPoint(x: self.frame.midX, y: self.frame.midY - 50)
        hardLabel.text = "hard"
        hardLabel.name = hardLabelCategoryName
        self.addChild(hardLabel)
        
        gameState.enter(Waiting.self)
        
        // Marker: Ball
        //
        ball.size = CGSize(width: 25, height: 25)
        ball.name = ballCategoryName
        ball.position = CGPoint(x: self.frame.midX, y: self.frame.midY + 100)
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
        paddle.size = CGSize(width: 150, height: 15)
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
    }
    
    // Marker: Game Timer
    //
    func startTimer() {
        let wait = SKAction.wait(forDuration: 1.0)
        let block = SKAction.run({
            self.timeValue += 1
        })
        let sequence = SKAction.sequence([wait, block])
        run(SKAction.repeatForever(sequence), withKey: "Timer")
    }
    
    // Marker: Bricks
    //
    func addRandomBricks() {
        // This function randomly places brick around the game scene to make the game for difficult
        //
        let wait = SKAction.wait(forDuration: 1.5)
        let block = SKAction.run({
            let randomX = self.randomFloat(from: 20, to: self.frame.size.width - 20)
            let randomY = self.randomFloat(from: self.paddle.frame.height + 80, to: self.frame.size.height - 20)
            let brick = SKSpriteNode(imageNamed: "Brick")
            
            let timeLabelFrame = CGRect(x: self.frame.width - 75, y: self.frame.height - 75, width: 75, height: 75)
            
            if !timeLabelFrame.contains(CGPoint(x: randomX, y: randomY)) {
                brick.position = CGPoint(x: randomX, y: randomY)
            } else {
                brick.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
            }
            brick.size = CGSize(width: 20, height: 20)
            brick.physicsBody = SKPhysicsBody(rectangleOf: brick.frame.size)
            brick.physicsBody?.linearDamping = 0
            brick.physicsBody?.allowsRotation = false
            brick.physicsBody?.isDynamic = false // Prevents the ball from slowing down when it hits a brick
            brick.physicsBody?.affectedByGravity = false
            brick.physicsBody?.friction = 0.0
            brick.physicsBody?.categoryBitMask = self.brickCategoryBitMask
            brick.name = brickCategoryName
            self.addChild(brick)
        })
        let sequence = SKAction.sequence([wait, block])
        run(SKAction.repeatForever(sequence), withKey: "addBlock")
    }
    
    // Marker: Update
    //
    override func update(_ currentTime: TimeInterval) {
        // Fires before every frame
        //
        gameState.update(deltaTime: currentTime)
        
        if let xValue = newX {
            let moveAction = SKAction.move(to: CGPoint(x: xValue, y: paddle.position.y), duration: 0.0625)
            paddle.run(moveAction)
        }
        
        if let physicsBody = ball.physicsBody {
            initialDx = abs(physicsBody.velocity.dx)
            initialDy = abs(physicsBody.velocity.dy)
        }
    }
    
    // Marker: Increase ball speed every second until max velocity is reached (Hard Game only)
    //
    override func didSimulatePhysics() {
        if isHardGame {
            guard let physicsBody = ball.physicsBody else { return }
            
            let increaseAmount: CGFloat = 1.0
            if abs(physicsBody.velocity.dx) < abs(initialDx) && abs(physicsBody.velocity.dx) < maxVelocity {
                physicsBody.velocity.dx = physicsBody.velocity.dx < 0 ? -initialDx - increaseAmount : initialDx + increaseAmount
            }
            
            if abs(physicsBody.velocity.dy) < abs(initialDy) && abs(physicsBody.velocity.dy) < maxVelocity {
                physicsBody.velocity.dy = physicsBody.velocity.dy < 0 ? -initialDy - increaseAmount : initialDy + increaseAmount
            }
            
            // print("new velocityDx: \(String(describing: ball.physicsBody?.velocity.dx))")
            // print("new velocityDy: \(String(describing: ball.physicsBody?.velocity.dy))")
        }
    }
    
    // Marker: Adjusting paddle size over time
    //
    func shrinkPaddle() {
        let wait = SKAction.wait(forDuration: 5)
        let block = SKAction.run({
            let resizeAction = SKAction.resize(toWidth: self.paddle.size.width - 5, duration: 0.1)
            self.paddle.run(resizeAction)
            self.adjustPaddlePhysicsBody()
            // print("paddle.size.with: \(self.paddle.size.width)")
        })
        let sequence = SKAction.sequence([wait, block])
        run(SKAction.repeat((sequence), count: 10))
    }
    
    // Marker: Adjust Paddle PhysicsBody
    //
    func adjustPaddlePhysicsBody() {
        // You cannot adjust the size of a phyiscsBody so we create a new one
        // every time the size of the paddle is decreased
        //
        paddle.physicsBody = SKPhysicsBody(rectangleOf: paddle.frame.size)
        paddle.physicsBody?.categoryBitMask = paddleCategoryBitMask
        paddle.physicsBody?.friction = 0.4
        paddle.physicsBody?.linearDamping = 0
        paddle.physicsBody?.restitution = 0.1 // Not sure
        paddle.physicsBody?.isDynamic = false
    }
    
    // Marker: Paddle Movement
    //
    func manageDeviceMotion() {
        // Move the paddle by tilting the screen
        // Since this game is played in landscape we are concerned with acceleration in the y direction
        //
        if motionManager.isAccelerometerAvailable {
            motionManager.startAccelerometerUpdates(to: OperationQueue.current!, withHandler: { data, error in
                if let data = data {
                    let currentX = self.paddle.position.x
                    if UIDevice.current.orientation == .landscapeLeft {
                        self.newX = currentX - CGFloat((data.acceleration.y) * 700)
                    } else {
                        self.newX = currentX + CGFloat((data.acceleration.y) * 700)
                    }
                    
                    self.newX = max(self.newX!, self.paddle.size.width / 2) // Left most position
                    self.newX = min(self.newX!, self.size.width - self.paddle.size.width / 2) // Right most position
                }
            })
        }
    }
    
    // Marker: Touches began
    //
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if gameState.currentState is Waiting {
            print("In waiting state")
            if let touch = touches.first {
                if easyLabel.contains(touch.location(in: self)) {
                    // Start an easy game
                    //
                    gameState.enter(Playing.self)
                    manageDeviceMotion()
                    addRandomBricks()
                    // No shrinking paddle
                    //
                    startTimer()
                }
                else if mediumLabel.contains(touch.location(in: self)) {
                    // Start an medium game
                    //
                    gameState.enter(Playing.self)
                    manageDeviceMotion()
                    addRandomBricks()
                    shrinkPaddle()
                    startTimer()
                }
                else if hardLabel.contains(touch.location(in: self)) {
                    // Start a hard game
                    //
                    gameState.enter(Playing.self)
                    manageDeviceMotion()
                    addRandomBricks()
                    shrinkPaddle()
                    startTimer()
                    // Speed the ball up over time
                    //
                    isHardGame = true
                }
            }
        }
        else if gameState.currentState is Playing {
            // Pause the game
            //
            if let view = view {
                if view.isPaused {
                    if let touch = touches.first {
                        if playButton.contains(touch.location(in: self)) {
                            // Resume the game and remove play button
                            //
                            view.isPaused = false
                            playButton.removeFromParent()
                        }
                    }
                } else {
                    // Pause the game and put the play button on the screen
                    //
                    musicPlayer.pause()
                    playButton.size = CGSize(width: 100, height: 100)
                    playButton.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
                    playButton.zPosition = 999
                    self.addChild(playButton)
                    
                    let pauseAction = SKAction.run {
                        view.isPaused = true
                    }
                    self.run(pauseAction)
                }
            }
        }
    }
    
    // Marker: Collision / SKPhysicsContactDelegate
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
            // print("Game Over")
            GameScene.score = timeValue
            musicPlayer.stop()
            let gameOverScene = GameOverScene(size: self.frame.size)
            self.view?.presentScene(gameOverScene)
        }
        
        if firstBody.categoryBitMask == ballCategoryBitMask && secondBody.categoryBitMask == brickCategoryBitMask {
            // Ball hit a brick
            //
            // print("ball hit a brick")
            run(brickHitSound)
            secondBody.node?.removeFromParent()
        }
        
        if firstBody.categoryBitMask == ballCategoryBitMask && secondBody.categoryBitMask == paddleCategoryBitMask ||
            secondBody.categoryBitMask == borderCategoryBitMask {
            // Ball hit paddle or border
            //
            run(paddleHitSound)
        }
    }
    
    // Marker: Random number generation
    //
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
