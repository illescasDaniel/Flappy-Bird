import UIKit
import SpriteKit

class GameViewController: UIViewController {

	@IBOutlet weak var mySwitch: UISwitch!

	let scene = GameScene(fileNamed: "GameScene")
	var skView = SKView()
	var paused = false

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

	override func prefersStatusBarHidden() -> Bool {
		return true
	}

	@IBAction func Pause(sender: UIButton) {

		if paused {
			skView.paused = false
			scene?.musicaFondo!.play()
		}
		else {
			skView.paused = true
			scene?.musicaFondo!.pause()
		}

		paused = paused ? false : true
	}

	@IBAction func restart(sender: UIButton) {
		scene?.reiniciarEscena()
	}

	@IBAction func mute(sender: AnyObject) {

		if mySwitch.on {
			scene?.musicaFondo!.play()
		}
		else {
			scene?.musicaFondo!.stop()
		}
	}
}
