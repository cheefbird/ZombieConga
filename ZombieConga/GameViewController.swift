//
//  GameViewController.swift
//  ZombieConga
//
//  Created by Francis Breidenbach on 8/3/18.
//  Copyright © 2018 Francis Breidenbach. All rights reserved.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let scene = GameScene(size: CGSize(width: 2048, height: 1536))
    let skView = self.view as! SKView
    
    skView.showsFPS = true
    skView.showsNodeCount = true
    skView.ignoresSiblingOrder = true
    
    scene.scaleMode = .aspectFill
    
    skView.presentScene(scene)
  }
}
