//
//  GameScene.swift
//  ZombieConga
//
//  Created by Francis Breidenbach on 8/3/18.
//  Copyright © 2018 Francis Breidenbach. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
  
  // MARK: - Properties
  
  let playableRect: CGRect
  
  let zombie: SKSpriteNode = SKSpriteNode(imageNamed: "zombie1")
  let zombieAnimation: SKAction
  
  let zombieMovePointsPerSec: CGFloat = 480.0
  let zombieRotateRadiansPerSec: CGFloat = 4.0 * π
  var velocity = CGPoint.zero
  
  var lastUpdateTime: TimeInterval = 0
  var dt: TimeInterval = 0
  
  let catCollisionSound: SKAction = SKAction.playSoundFileNamed("hitCat.wav", waitForCompletion: false)
  let enemyCollisionSound: SKAction = SKAction.playSoundFileNamed("hitCatLady.wav", waitForCompletion: false)
  
  var invincible = false
  
  let catMovePointsPerSec: CGFloat = 480.0
  
  var lives = 5
  var gameOver = false
  
  let cameraNode = SKCameraNode()
  let cameraMovePointsPerSec: CGFloat = 200.0
  
  // MARK: - Optional Properties
  
  var lastTouchLocation: CGPoint?
  
  // MARK: - Computed Properties
  var cameraRect: CGRect {
    let x = cameraNode.position.x - size.width / 2 + (size.width - playableRect.width) / 2
    let y = cameraNode.position.y - size.height / 2 + (size.height - playableRect.height) / 2
    
    return CGRect(
      x: x,
      y: y,
      width: playableRect.width,
      height: playableRect.height)
  }
  
  // MARK: - Overrides
  
  override init(size: CGSize) {
    let maxAspectRatio: CGFloat = 16.0 / 9.0
    let playableHeight = size.width / maxAspectRatio
    let playableMargin = (size.height - playableHeight) / 2.0
    
    playableRect = CGRect(x: 0, y: playableMargin, width: size.width, height: playableHeight)
    
    var textures: [SKTexture] = []
    
    for i in 1...4 {
      textures.append(SKTexture(imageNamed: "zombie\(i)"))
    }
    
    textures.append(textures[2])
    textures.append(textures[1])
    
    zombieAnimation = SKAction.animate(
      with: textures,
      timePerFrame: 0.1)
    
    super.init(size: size)
  }
  
  required init(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func didMove(to view: SKView) {
    backgroundColor = SKColor.black
    
    for i in 0...1 {
      let background = backgroundNode()
      background.anchorPoint = .zero
      background.position = CGPoint(x: CGFloat(i) * background.size.width, y: 0)
      background.name = "background"
      background.zPosition = -1
      addChild(background)
    }
    
    zombie.position = CGPoint(x: 400, y: 400)
    zombie.zPosition = 100
    addChild(zombie)
    
    run(SKAction.repeatForever(
      SKAction.sequence([SKAction.run { [weak self] in
        self?.spawnEnemy()
        }, SKAction.wait(forDuration: 2.0)])))
    
    run(SKAction.repeatForever(
      SKAction.sequence([SKAction.run { [weak self] in
        self?.spawnCat()
        }, SKAction.wait(forDuration: 1.0)])))
    
    //    debugDrawPLayableArea()
    
    playBackgroundMusic(filename: "backgroundMusic.mp3")
    
    addChild(cameraNode)
    camera = cameraNode
    cameraNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
  }
  
  override func update(_ currentTime: TimeInterval) {
    // Show time elapsed since last update
    if lastUpdateTime > 0 {
      dt = currentTime - lastUpdateTime
    } else {
      dt = 0
    }
    
    lastUpdateTime = currentTime
    
    if let lastTouchLocation = lastTouchLocation {
      let diff = lastTouchLocation - zombie.position
      
      if diff.length() <= zombieMovePointsPerSec * CGFloat(dt) {
        zombie.position = lastTouchLocation
        velocity = CGPoint.zero
        
        stopZombieAnimation()
      } else {
        move(sprite: zombie, velocity: velocity)
        rotate(sprite: zombie, direction: velocity, rotateRadiansPerSec: zombieRotateRadiansPerSec)
      }
    }
    
    boundsCheckZombie()
    
    moveTrain()
    
    moveCamera()
    
    if lives <= 0 && !gameOver {
      gameOver = true
      print("You Lose!")
      
      backgroundMusicPlayer.stop()
      
      let gameOverScene = GameOverScene(size: size, won: false)
      gameOverScene.scaleMode = scaleMode
      
      let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
      view?.presentScene(gameOverScene, transition: reveal)
    }
  }
  
  override func didEvaluateActions() {
    checkCollisions()
  }
  
  // MARK: - Touch Handling
  
  func sceneTouched(touchLocation: CGPoint) {
    lastTouchLocation = touchLocation
    moveZombieToward(location: touchLocation)
  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard let touch = touches.first else {
      return
    }
    
    let touchLocation = touch.location(in: self)
    sceneTouched(touchLocation: touchLocation)
  }
  
  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard let touch = touches.first else {
      return
    }
    
    let touchLocation = touch.location(in: self)
    sceneTouched(touchLocation: touchLocation)
  }
  
  // MARK: - Methods
  
  func spawnCat() {
    let cat = SKSpriteNode(imageNamed: "cat")
    
    cat.name = "cat"
    
    cat.position = CGPoint(
      x: CGFloat.random(min: playableRect.minX,
                        max: playableRect.maxX),
      y: CGFloat.random(min: playableRect.minY,
                        max: playableRect.maxY))
    
    cat.setScale(0)
    
    addChild(cat)
    
    let appear = SKAction.scale(to: 1.0, duration: 0.5)
    
    cat.zRotation = -π / 16.0
    let leftWiggle = SKAction.rotate(byAngle: π / 8.0, duration: 0.5)
    let rightWiggle = leftWiggle.reversed()
    let fullWiggle = SKAction.sequence([leftWiggle, rightWiggle])
    
    let scaleUp = SKAction.scale(by: 1.2, duration: 0.25)
    let scaleDown = scaleUp.reversed()
    let fullScale = SKAction.sequence([scaleUp,scaleDown, scaleUp, scaleDown ])
    let group = SKAction.group([fullScale, fullWiggle])
    let groupWait = SKAction.repeat(group, count: 10)
    
    let disappear = SKAction.scale(to: 0, duration: 0.5)
    let removeFromParent = SKAction.removeFromParent()
    let actions = [appear, groupWait, disappear, removeFromParent]
    
    cat.run(SKAction.sequence(actions))
  }
  
  func spawnEnemy() {
    let enemy = SKSpriteNode(imageNamed: "enemy")
    
    enemy.name = "enemy"
    
    enemy.position = CGPoint(
      x: size.width + enemy.size.width / 2,
      y: CGFloat.random(
        min: playableRect.minY + enemy.size.height / 2,
        max: playableRect.maxY - enemy.size.height / 2))
    
    addChild(enemy)
    
    let actionMove = SKAction.moveTo(
      x: -enemy.size.width / 2,
      duration: 2.0)
    
    let actionRemove = SKAction.removeFromParent()
    
    enemy.run(SKAction.sequence([actionMove, actionRemove]))
  }
  
  func startZombieAnimation() {
    if zombie.action(forKey: "animation") == nil {
      zombie.run(
        SKAction.repeatForever(zombieAnimation),
        withKey: "animation")
    }
  }
  
  func stopZombieAnimation() {
    zombie.removeAction(forKey: "animation")
  }
  
  func move(sprite: SKSpriteNode, velocity: CGPoint) {
    let amountToMove = velocity * CGFloat(dt)
    
    sprite.position += amountToMove
  }
  
  func moveZombieToward(location: CGPoint) {
    startZombieAnimation()
    
    let offset = location - zombie.position
    
    let direction = offset.normalized()
    
    velocity = direction * zombieMovePointsPerSec
  }
  
  func boundsCheckZombie() {
    let bottomLeft = CGPoint(x: 0, y: playableRect.minY)
    let topRight = CGPoint(x: size.width, y: playableRect.maxY)
    
    if zombie.position.x <= bottomLeft.x {
      zombie.position.x = bottomLeft.x
      velocity.x = -velocity.x
    }
    if zombie.position.x >= topRight.x {
      zombie.position.x = topRight.x
      velocity.x = -velocity.x
    }
    if zombie.position.y <= bottomLeft.y {
      zombie.position.y = bottomLeft.y
      velocity.y = -velocity.y
    }
    if zombie.position.y >= topRight.y {
      zombie.position.y = topRight.y
      velocity.y = -velocity.y
    }
  }
  
  func rotate(sprite: SKSpriteNode, direction: CGPoint, rotateRadiansPerSec: CGFloat) {
    let shortest = shortestAngleBetween(angle1: sprite.zRotation, angle2: velocity.angle)
    let amountToRotate = min(rotateRadiansPerSec * CGFloat(dt), abs(shortest))
    
    sprite.zRotation += shortest.sign() * amountToRotate
  }
  
  func zombieHit(cat: SKSpriteNode) {
    cat.name = "train"
    
    cat.removeAllActions()
    
    cat.setScale(1.0)
    cat.zRotation = 0
    
    let turnGreen = SKAction.colorize(with: SKColor.green, colorBlendFactor: 1.0, duration: 0.2)
    
    cat.run(turnGreen)
    
    run(catCollisionSound)
  }
  
  func zombieHit(enemy: SKSpriteNode) {
    invincible = true
    
    let blinkTimes = 10.0
    let duration = 3.0
    
    let blinkAction = SKAction.customAction(withDuration: duration) { node, elapsedTime in
      let slice = duration / blinkTimes
      let remainder = Double(elapsedTime).truncatingRemainder(dividingBy: slice)
      node.isHidden = remainder > slice / 2
    }
    
    let setHidden = SKAction.run() { [weak self] in
      self?.zombie.isHidden = false
      self?.invincible = false
    }
    
    zombie.run(SKAction.sequence([blinkAction, setHidden]))
    
    run(enemyCollisionSound)
    
    loseCats()
    lives -= 1
  }
  
  func checkCollisions() {
    var hitCats: [SKSpriteNode] = []
    
    enumerateChildNodes(withName: "cat") { node, _ in
      let cat = node as! SKSpriteNode
      if cat.frame.intersects(self.zombie.frame) {
        hitCats.append(cat)
      }
    }
    
    for cat in hitCats {
      zombieHit(cat: cat)
    }
    
    if invincible {
      return
    }
    
    var hitEnemies: [SKSpriteNode] = []
    enumerateChildNodes(withName: "enemy") { node, _ in
      let enemy = node as! SKSpriteNode
      if node.frame.insetBy(dx: 20, dy: 20).intersects(self.zombie.frame) {
        hitEnemies.append(enemy)
      }
    }
    
    for enemy in hitEnemies {
      zombieHit(enemy: enemy)
    }
  }
  
  func moveTrain() {
    var trainCount = 0
    var targetPosition = zombie.position
    
    enumerateChildNodes(withName: "train") { node, stop in
      trainCount += 1
      
      if !node.hasActions() {
        let actionDuration = 0.3
        let offset = targetPosition - node.position
        let direction = offset.normalized()
        let amountToMovePerSec = direction * self.catMovePointsPerSec
        let amountToMove = amountToMovePerSec * CGFloat(actionDuration)
        let moveAction = SKAction.moveBy(x: amountToMove.x, y: amountToMove.y, duration: actionDuration)
        
        node.run(moveAction)
      }
      
      targetPosition = node.position
    }
    
    if trainCount >= 15 && !gameOver {
      gameOver = true
      print("You Win!")
      
      backgroundMusicPlayer.stop()
      
      let gameOverScene = GameOverScene(size: size, won: true)
      gameOverScene.scaleMode = scaleMode
      
      let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
      view?.presentScene(gameOverScene, transition: reveal)
    }
  }
  
  func loseCats() {
    var loseCount = 0
    
    enumerateChildNodes(withName: "train") { node, stop in
      var randomSpot = node.position
      randomSpot.x += CGFloat.random(min: -100, max: 100)
      randomSpot.y += CGFloat.random(min: -100, max: 100)
      
      node.name = ""
      
      node.run(SKAction.sequence([
        SKAction.group([
          SKAction.rotate(byAngle: π * 4, duration: 1.0),
          SKAction.move(to: randomSpot, duration: 1.0),
          SKAction.scale(to: 0, duration: 1.0)
          ]),
        SKAction.removeFromParent()
        ]))
      
      loseCount += 1
      if loseCount >= 2 {
        stop[0] = true
      }
    }
  }
  
  func backgroundNode() -> SKSpriteNode {
    
    let backgroundNode = SKSpriteNode()
    backgroundNode.anchorPoint = CGPoint.zero
    backgroundNode.name = "background"
    
    let background1 = SKSpriteNode(imageNamed: "background1")
    background1.anchorPoint = CGPoint.zero
    background1.position = CGPoint(x: 0, y: 0)
    backgroundNode.addChild(background1)
    
    let background2 = SKSpriteNode(imageNamed: "background2")
    background2.anchorPoint = CGPoint.zero
    background2.position = CGPoint(x: background1.size.width, y: 0)
    backgroundNode.addChild(background2)
    
    backgroundNode.size = CGSize(
      width: background1.size.width + background2.size.width,
      height: background1.size.height)
    
    return backgroundNode
  }
  
  func moveCamera() {
    let velocity = CGPoint(x: cameraMovePointsPerSec, y: 0)
    let amount = velocity * CGFloat(dt)
    
    cameraNode.position += amount
    
    enumerateChildNodes(withName: "background") { node, _ in
      let background = node as! SKSpriteNode
      
      if background.position.x + background.size.width < self.cameraRect.origin.x {
        background.position = CGPoint(
          x: background.position.x + background.size.width*2,
          y: background.position.y)
      }
    }
  }
  
  // MARK: - Debug Methods
  
  func debugDrawPLayableArea() {
    let shape = SKShapeNode(rect: playableRect)
    shape.strokeColor = SKColor.red
    shape.lineWidth = 4.0
    addChild(shape)
  }
}

















