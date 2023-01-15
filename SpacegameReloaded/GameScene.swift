//
//  GameScene.swift
//  SpacegameReloaded
//
//  Created by Dhanush Arun on 8/6/21.
//

import SpriteKit
import GameplayKit
import CoreMotion

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var starField:SKEmitterNode!
    var player:SKSpriteNode!
    
    var scoreLabel: SKLabelNode!
    var score:Int! = 0 {
        didSet {
            scoreLabel.text = "Score: \(score ?? 1)"
            
        }
        
    }
    var gameTimer:Timer!
    var possibleAliens = ["alien", "alien2", "alien3"]
    
    let alienCategory: UInt32 = 0x1 << 1
    let photonTorpedoCategory:UInt32 = 0x1 << 0
    
    let motionManager = CMMotionManager()
    var xAcceleraton: CGFloat = 0
    
    override func didMove(to view: SKView) {
        starField = SKEmitterNode(fileNamed: "Starfield.sks")
        starField.position = CGPoint(x: 0, y: 1472)
        starField.advanceSimulationTime(10)
        starField.zPosition = -1
        
        self.addChild(starField)
        
        player = SKSpriteNode(imageNamed: "shuttle")
        player.position = CGPoint(x: 0, y: -500)
        player.scale(to: CGSize(width: 100, height: 100))
        self.addChild(player)
        
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        self.physicsWorld.contactDelegate = self
        
        scoreLabel = SKLabelNode(text: "")
        scoreLabel.position = CGPoint(x: -230, y: 430)
        scoreLabel.fontName = "AmericanTypewriter-Bold"
        scoreLabel.fontSize = 50
        scoreLabel.fontColor = UIColor.white
        score = 0
        
        self.addChild(scoreLabel)
        
        gameTimer = Timer.scheduledTimer(timeInterval: 0.75, target: self, selector: #selector(addAlien), userInfo: nil, repeats: true)
        
        motionManager.accelerometerUpdateInterval = 0.2
        motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { (data: CMAccelerometerData?, erorr: Error?)  in
            if let accelerometerData = data {
                let acceleration = accelerometerData.acceleration
                self.xAcceleraton = CGFloat(acceleration.x) * 0.75 + self.xAcceleraton * 0.25
                
            }
        }
        
        
    }
    
    @objc func addAlien(){
        possibleAliens = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: possibleAliens) as! [String]
        
        let alien = SKSpriteNode(imageNamed: possibleAliens[0])
        alien.scale(to: CGSize(width: 50, height: 50))
        
        let randomAlienPositionX = GKRandomDistribution(lowestValue: -500, highestValue: 500)
        let randomAlienPositionY = GKRandomDistribution(lowestValue: -500, highestValue: 500)
        let positionX = CGFloat(randomAlienPositionX.nextInt())
        let positionY = CGFloat(randomAlienPositionX.nextInt())
        
        alien.position = CGPoint(x: positionX, y: positionY)
        
        alien.physicsBody = SKPhysicsBody(rectangleOf: alien.size)
        alien.physicsBody?.isDynamic = true
        
        alien.physicsBody?.categoryBitMask = alienCategory
        alien.physicsBody?.contactTestBitMask = photonTorpedoCategory
        alien.physicsBody?.collisionBitMask = 0
        
        self.addChild(alien)
        
        let animationDuration:TimeInterval = 6
        
        var actionArray = [SKAction]()
        actionArray.append(SKAction.move(to: CGPoint(x: positionX, y: -400), duration: animationDuration))
        actionArray.append(SKAction.removeFromParent())
        
        alien.run(SKAction.sequence(actionArray))
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        fireTorpedo()
        
    }
    
    func fireTorpedo(){
        self.run(SKAction.playSoundFileNamed("torpedo.mp3", waitForCompletion: false))
        
        let torpedoNode = SKSpriteNode(imageNamed: "torpedo")
        torpedoNode.position = player.position
        torpedoNode.position.y += 5
        
        torpedoNode.physicsBody = SKPhysicsBody(circleOfRadius: torpedoNode.size.width / 2)
        torpedoNode.physicsBody?.isDynamic = true
        
        torpedoNode.physicsBody?.categoryBitMask = photonTorpedoCategory
        torpedoNode.physicsBody?.contactTestBitMask = alienCategory
        torpedoNode.physicsBody?.collisionBitMask = 0
        torpedoNode.physicsBody?.usesPreciseCollisionDetection = true
        
        self.addChild(torpedoNode)
        
        let animationDuration: TimeInterval = 0.3
        
        var actionArray = [SKAction]()
        actionArray.append(SKAction.move(to: CGPoint(x: player.position.x, y: self.frame.size.height + 10), duration: animationDuration))
        actionArray.append(SKAction.removeFromParent())
        
        torpedoNode.run(SKAction.sequence(actionArray))
        
    }
    
    override func update(_ currentTime: TimeInterval) {
        
        
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
            
        }
        
        else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
            
        }
        
        if (firstBody.categoryBitMask & photonTorpedoCategory) != 0 && (secondBody.categoryBitMask & alienCategory) != 0{
            torpedoDidCollideWithAlien(torpedoNode: firstBody.node as! SKSpriteNode, alienNode: secondBody.node as! SKSpriteNode)
            
        }
        
    }
    
    func torpedoDidCollideWithAlien(torpedoNode: SKSpriteNode, alienNode: SKSpriteNode){
        let explosion = SKEmitterNode(fileNamed: "Explosion")
        explosion?.position = alienNode.position
        self.addChild(explosion!)
        
        self.run(SKAction.playSoundFileNamed("explosion", waitForCompletion: false))
        
        torpedoNode.removeFromParent()
        alienNode.removeFromParent()
        
        self.run(SKAction.wait(forDuration: 2), completion: {
            explosion?.removeFromParent()
            
        })
        
        score += 5
        
    }
    
    override func didSimulatePhysics() {
        player.position.x += xAcceleraton * 50
        
        //check if the ship is too much to the left or right
        //and change accordingly
        if player.position.x < -250{
            player.position = CGPoint(x: self.size.width + 20, y: -400)
            
        }
        
        else if player.position.x > self.size.width + 20{
            player.position = CGPoint(x: -20, y: -400)
            
        }
        
    }
    
}
