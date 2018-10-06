//
//  MainMenuScene.swift
//  ZombieConga
//
//  Created by Francis Breidenbach on 10/5/18.
//  Copyright © 2018 Francis Breidenbach. All rights reserved.
//

import Foundation
import SpriteKit

class MainMenuScene: SKScene {
  
  // MARK: - Overrides
  override func didMove(to view: SKView) {
    let background = SKSpriteNode(imageNamed: "MainMenu")
    background.position = CGPoint(x: size.width / 2, y: size.height / 2)
    
    self.addChild(background)
  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    sceneTapped()
  }
  
  // MARK: - Methods
  func sceneTapped() {
    let gameScene = GameScene(size: size)
    gameScene.scaleMode = scaleMode
    
    let transition = SKTransition.doorway(withDuration: 1.5)
    
    view?.presentScene(gameScene, transition: transition)
  }
}
