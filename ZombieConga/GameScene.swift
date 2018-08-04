//
//  GameScene.swift
//  ZombieConga
//
//  Created by Francis Breidenbach on 8/3/18.
//  Copyright © 2018 Francis Breidenbach. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
  override func didMove(to view: SKView) {
    backgroundColor = SKColor.black
    
    let background = SKSpriteNode(imageNamed: "background1")
    
    addChild(background)
  }
}
