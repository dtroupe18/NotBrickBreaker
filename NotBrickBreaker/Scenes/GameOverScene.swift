//
//  GameOver.swift
//  NotBrickBreaker
//
//  Created by Dave on 2/18/18.
//  Copyright © 2018 High Tree Development. All rights reserved.
//

import SpriteKit

class GameOverScene: SKScene {
    
    let gameOverSound = SKAction.playSoundFileNamed("gameOverSound", waitForCompletion: false)
    
    override init(size: CGSize) {
        super.init(size: size)
        
        // You shouldn't really store values like this in UserDefaults, but it's
        // a waste to use coreData to store one int value
        //
        var bestScore = UserDefaults.standard.integer(forKey: "bestScore")
        if GameScene.score > bestScore {
            bestScore = GameScene.score
            // Save the new best score
            //
            UserDefaults.standard.set(bestScore, forKey: "bestScore")
        }
        
        // Marker: Background
        //
        let bg = SKSpriteNode(imageNamed: "Background")
        bg.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
        self.addChild(bg)
        
        // Game over Label
        //
        let gameOverLabel = SKLabelNode(fontNamed: "ChalkboardSE-Light")
        gameOverLabel.fontSize = 46
        gameOverLabel.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
        gameOverLabel.text = "GAME OVER"
        self.addChild(gameOverLabel)
        
        // Score Label
        //
        let scoreLabel = SKLabelNode(fontNamed: "ChalkboardSE-Light")
        scoreLabel.fontSize = 35
        scoreLabel.text = "Score: \(GameScene.score)"
        scoreLabel.fontColor = UIColor.init(red: 57/255, green: 255/255, blue: 20/255, alpha: 1.0)
        scoreLabel.position = CGPoint(x: self.frame.midX, y: self.frame.midY + gameOverLabel.frame.height + 20)
        self.addChild(scoreLabel)
        
        // Best Score label
        //
        let bestScoreLabel = SKLabelNode(fontNamed: "ChalkboardSE-Light")
        bestScoreLabel.fontSize = 35
        bestScoreLabel.text = "High Score: \(bestScore)"
        bestScoreLabel.fontColor = UIColor.init(red: 1.0, green: 0, blue: 0, alpha: 1.0)
        bestScoreLabel.position = CGPoint(x: self.frame.midX, y: self.frame.midY - gameOverLabel.frame.height - 20)
        self.addChild(bestScoreLabel)
    }
    
    override func didMove(to view: SKView) {
        run(gameOverSound)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Restart the game when the screen is touched
        //
        let gameScene = GameScene(size: self.size)
        self.view?.presentScene(gameScene)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
