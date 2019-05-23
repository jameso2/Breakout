//
//  GameScene.swift
//  Breakout
//
//  Created by James Ortiz on 5/11/19.
//  Copyright © 2019 James Ortiz. All rights reserved.
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    private var paddle: SKSpriteNode!
    private var ball: SKSpriteNode!
    private var bottomOfScreen: SKShapeNode!
    private let tileTypes = ["redTile", "blueTile", "greenTile", "yellowTile", "purpleTile"]
    private var tiles = [SKSpriteNode]() // An array of tiles displayed on screen
    private var lives = [SKSpriteNode]() // An array of SpriteNodes displayed on screen to represent the user's remaining lives
    
    // Message that tells the user to tap to play (at the start of the game) and notifies the user of whether they won/lost (at the end of the game)
    private var messageLabel: SKLabelNode?
    private var gameEnded = false

    // MARK: Configuring the screen boundaries
    
    override func didMove(to view: SKView) {
        configurePhysics()
        layoutScene()
    }
    
    private func configurePhysics() {
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        configureScreenBoundary()
        configureBottomOfScreen()
        
    }
    
    // Converts the left, top, and right edges of the screen into a boundary for the ball
    private func configureScreenBoundary() {
        let boundary = CGMutablePath()
        boundary.move(to: CGPoint.zero)
        boundary.addLine(to: CGPoint(x: 0, y: size.height))
        boundary.addLine(to: CGPoint(x: size.width, y: size.height))
        boundary.addLine(to: CGPoint(x: size.width, y: 0))
        physicsBody = SKPhysicsBody(edgeChainFrom: boundary)
        physicsBody?.categoryBitMask = PhysicsCategories.boundary
        physicsBody?.friction = 0
    }
    
    // Allows the bottom of the screen to detect when the ball makes contact
    private func configureBottomOfScreen() {
        let bottomOfScreenPath = CGMutablePath()
        bottomOfScreenPath.move(to: CGPoint.zero)
        bottomOfScreenPath.addLine(to: CGPoint(x: size.width, y: 0))
        bottomOfScreen = SKShapeNode(path: bottomOfScreenPath)
        bottomOfScreen.physicsBody = SKPhysicsBody(edgeFrom: CGPoint.zero, to: CGPoint(x: size.width, y: 0))
        bottomOfScreen.physicsBody?.categoryBitMask = PhysicsCategories.bottom
        addChild(bottomOfScreen)
    }
    
    // MARK: Laying out the scene
    
    private func layoutScene() {
        createPaddle()
        createBall()
        layoutTiles()
        displayMessage("Tap to Play!")
    }
    
    private func createPaddle() {
        paddle = SKSpriteNode(imageNamed: "paddle")
        paddle.size = CGSize(width: Constants.paddleWidth, height: Constants.paddleHeight)
        paddle.position = CGPoint(x: size.width/2, y: size.height/6)
        paddle.physicsBody = SKPhysicsBody(rectangleOf: paddle.size)
        paddle.physicsBody?.categoryBitMask = PhysicsCategories.paddle
        paddle.physicsBody?.friction = 0
        paddle.physicsBody?.isDynamic = false
        addChild(paddle)
    }
    
    private func createBall() {
        ball = SKSpriteNode(imageNamed: "ball")
        ball.size = CGSize(width: 2 * Constants.ballRadius, height: 2 * Constants.ballRadius)
        ball.position = CGPoint(x: size.width/2, y: size.height/6 + Constants.ballOffset)
        ball.physicsBody = SKPhysicsBody(circleOfRadius: Constants.ballRadius)
        ball.physicsBody?.categoryBitMask = PhysicsCategories.ball
        ball.physicsBody?.contactTestBitMask = PhysicsCategories.paddle | PhysicsCategories.tile | PhysicsCategories.bottom
        ball.physicsBody?.collisionBitMask = PhysicsCategories.paddle | PhysicsCategories.tile | PhysicsCategories.boundary
        ball.physicsBody?.restitution = 1.0
        ball.physicsBody?.friction = 0
        ball.physicsBody?.linearDamping = 0
        addChild(ball)
    }
    
    private func layoutTiles() {
        if size.width >= Constants.tileWidth {
            let numTilesPerRow = 1 + Int((size.width - Constants.tileWidth)/(Constants.tileWidth + Constants.tileSpacing))
            let tileHorizontalOffset = (size.width - Constants.tileWidth - CGFloat(numTilesPerRow - 1) * (Constants.tileWidth + Constants.tileSpacing)) / 2
            displayNumLives(at: CGPoint(x: tileHorizontalOffset, y: Constants.lifeVerticalOffset))
            var tileX = tileHorizontalOffset + Constants.tileWidth/2 // The x-ccordinate of the center of the tile
            var tileY = size.height - Constants.tileVerticalOffset - Constants.tileHeight/2 // The y-coordinate of the center of the tile
            var tileTypeIndex = 0
            while tileY > 2 * size.height/3 {
                let tileType = tileTypes[tileTypeIndex]
                for _ in 0..<Constants.numRowsPerTileType {
                    for _ in 0..<numTilesPerRow {
                        createTileOfType(tileType, at: CGPoint(x: tileX, y: tileY))
                        tileX += Constants.tileWidth + Constants.tileSpacing
                    }
                    tileX = tileHorizontalOffset + Constants.tileWidth/2
                    tileY -= (Constants.tileHeight + Constants.tileSpacing)
                }
                tileTypeIndex += 1
            }
        }
    }
    
    private func displayNumLives(at point: CGPoint) {
        let lifeSize = CGSize(width: 2 * Constants.ballRadius, height: 2 * Constants.ballRadius)
        for i in 0..<Constants.numLivesAtStart {
            let life = SKSpriteNode(imageNamed: "ball")
            life.size = lifeSize
            life.position = CGPoint(x: point.x + CGFloat(i) * (lifeSize.width + Constants.lifeSpacing),
                                    y: point.y)
            addChild(life)
            lives.append(life)
        }
    }
    
    private func createTileOfType(_ type: String, at location: CGPoint) {
        let tile = SKSpriteNode(imageNamed: type)
        tile.size = CGSize(width: Constants.tileWidth, height: Constants.tileHeight)
        tile.position = CGPoint(x: location.x, y: location.y)
        tile.physicsBody = SKPhysicsBody(rectangleOf: tile.size)
        tile.physicsBody?.categoryBitMask = PhysicsCategories.tile
        tile.physicsBody?.friction = 0
        tile.physicsBody?.isDynamic = false
        addChild(tile)
        tiles.append(tile)
    }
    
    private func displayMessage(_ message: String) {
        messageLabel = SKLabelNode(text: message)
        messageLabel!.fontName = "AvenirNext-Bold"
        messageLabel!.fontSize = 50.0
        messageLabel!.fontColor = UIColor.white
        messageLabel!.position = CGPoint(x: size.width/2, y: size.height/2)
        addChild(messageLabel!)
        animateLabel(messageLabel!)
    }
    
    private func animateLabel(_ label: SKLabelNode) {
        let scaleUp = SKAction.scale(to: 1.1, duration: 0.7)
        let scaleDown = SKAction.scale(to: 0.9, duration: 0.7)
        let sequence = SKAction.sequence([scaleUp, scaleDown])
        label.run(SKAction.repeatForever(sequence))
    }
    
    // MARK: Movement of ball and paddle
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if gameEnded { // If the user taps the screen once the game has ended, a new game will commence
            removeCurrentlyDisplayedLives()
            createBall()
            layoutTiles()
            gameEnded = false
        }
        if let label = messageLabel { // Any label being displayed is removed once the user taps the screen
            label.removeFromParent()
        }
        setInitialVelocityOfBall()
    }
    
    // Called when the game ends. Removes the lives currently displayed on screen (if any)
    private func removeCurrentlyDisplayedLives() {
        for life in lives {
            life.removeFromParent()
        }
        lives.removeAll()
    }
    
    // If the ball is not moving when the user taps the screen, the ball is given an initial velocity
    private func setInitialVelocityOfBall() {
        if let ballVelocity = ball.physicsBody?.velocity, ballVelocity == CGVector.zero {
            ball.physicsBody?.velocity = CGVector(dx: (Bool.random() ? -1 : 1) * Constants.ballHorizontalVelocityUpperBound.arc4random(), dy: Constants.ballVerticalVelocity)
        }
    }
    
    // The user moves the paddle by dragging their finger along the screen
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            updatePaddlePosition(to: t.location(in: self))
        }
    }
    
    private func updatePaddlePosition(to location: CGPoint) {
        if location.x - paddle.size.width/2 < 0 {
            paddle.position.x = paddle.size.width/2
        } else if location.x + paddle.size.width/2 <= size.width {
            paddle.position.x = location.x
        } else {
            paddle.position.x = size.width - paddle.size.width/2
        }
    }
    
    // MARK: SKPhysicsContactDelegate
    
    func didBegin(_ contact: SKPhysicsContact) {
        let contactMask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        switch contactMask {
        case PhysicsCategories.ball | PhysicsCategories.bottom: regenerateBall()
        case PhysicsCategories.ball | PhysicsCategories.paddle:
            let paddleSound = SKAction.playSoundFileNamed("paddleSound", waitForCompletion: false)
            run(paddleSound)
        case PhysicsCategories.ball | PhysicsCategories.tile :
            let tilePhysicsBody = (contact.bodyA.categoryBitMask == PhysicsCategories.tile) ? contact.bodyA : contact.bodyB
            if let tile = tilePhysicsBody.node as? SKSpriteNode {
                breakTile(tile)
            }
        default: break
        }
    }
    
    // This method is called when the ball falls off the bottom of the screen. First, the current ball is removed.
    // Then, if the user has at least one remaining life, a new ball is spawned; otherwise, the game ends.
    private func regenerateBall() {
        ball.removeFromParent()
        if lives.count > 0 {
            let life = lives.remove(at: lives.count - 1)
            life.removeFromParent()
            createBall()
        } else {
            displayMessage("Game Over")
            gameEnded = true
        }
    }
    
    private func breakTile(_ tile: SKSpriteNode) {
        let tileSound = SKAction.playSoundFileNamed("tileSound", waitForCompletion: false)
        let fadeOut = SKAction.fadeOut(withDuration: Constants.tileFadeoutTime)
        let sequence = SKAction.sequence([tileSound, fadeOut])
        tile.run(sequence, completion: {
            if let tileIndex = self.tiles.firstIndex(of: tile) {
                self.tiles.remove(at: tileIndex)
                if self.tiles.isEmpty {
                    self.ball.removeFromParent()
                    self.displayMessage("You Won!")
                    self.gameEnded = true
                }
            }
            tile.removeFromParent()
        })
    }
    
    private struct Constants {
        static let paddleWidth: CGFloat = 110
        static let paddleHeight: CGFloat = 30
        static let ballRadius: CGFloat = 15
        static let ballOffset: CGFloat = 100 // The ball's initial vertical offset from the paddle
        static let ballVerticalVelocity: CGFloat = 350 // The vertical component of the ball's initial velocity
        static let ballHorizontalVelocityUpperBound: CGFloat = 100 // The upper bound of the horizontal component of the ball's initial velocity
        static let tileWidth: CGFloat = 110
        static let tileHeight: CGFloat = 30
        static let tileVerticalOffset: CGFloat = 50 // The vertical offset of the first row of tiles from the top of the screen
        static let tileSpacing: CGFloat = 5 // The amount of space between the tiles
        static let numRowsPerTileType = 2
        static let tileFadeoutTime = 0.5 // The duration of the fadeout animation that occurs when a tile is hit
        static let numLivesAtStart = 3 // The number of lives that the user starts with
        static let lifeSpacing: CGFloat = 20 // The amount of horizontal spacing between the SpriteNodes representing the user's remaining lives
        static let lifeVerticalOffset: CGFloat = 50 // The vertical offset of the row of lives from the bottom of the screen
    }
}

extension CGFloat {
    func arc4random() -> CGFloat {
        let result = CGFloat(arc4random_uniform(UInt32(abs(self))))
        return self < 0 ? -1 * result : result
    }
}
