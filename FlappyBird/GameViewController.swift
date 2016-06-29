//
//  GameViewController.swift
//  FlappyBird
//
//  Created by Daniel Illescas Romero on 29/06/16.
//  Copyright (c) 2016 Daniel Illescas Romero. All rights reserved.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {
	
	
	@IBOutlet weak var mySwitch: UISwitch!
	
	let scene = GameScene(fileNamed:"GameScene")
	var skView = SKView()

    override func viewDidLoad() {
        super.viewDidLoad()

            // Configure the view.
			skView = self.view as! SKView
            skView.showsFPS = false
            skView.showsNodeCount = false
            
            /* Sprite Kit applies additional optimizations to improve rendering performance */
            skView.ignoresSiblingOrder = true
            
            /* Set the scale mode to scale to fit the window */
            scene!.scaleMode = .AspectFill
            
            skView.presentScene(scene)
    }
	

    override func shouldAutorotate() -> Bool {
        return true
    }

    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return .AllButUpsideDown
        } else {
            return .All
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
	
	@IBAction func play(sender: UIButton) {
		skView.paused = false
		scene?.musicaFondo!.play()
	}
	
	@IBAction func Pause(sender: UIButton) {
		skView.paused = true
		scene?.musicaFondo!.stop()
	}
	
	@IBAction func restart(sender: UIButton) {
		scene?.reiniciarEscena()
	}
	
	@IBAction func mute(sender: AnyObject) {
		
		if mySwitch.on {
			scene?.musicaFondo!.play()
		}
		else{
			scene?.musicaFondo!.stop()
		}
	}
	
}