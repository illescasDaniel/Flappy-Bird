import UIKit
import SpriteKit

class GameViewController: UIViewController {

	@IBOutlet weak var mySwitch: UISwitch!

	let scene = GameScene(fileNamed: "GameScene")
	@IBOutlet var skView: SKView!
	

	override func viewDidLoad() {
		super.viewDidLoad()

		// Configure the view.
		skView.showsFPS = false
		skView.showsNodeCount = false

		/* Sprite Kit applies additional optimizations to improve rendering performance */
		skView.ignoresSiblingOrder = true

		/* Set the scale mode to scale to fit the window */
		scene?.scaleMode = .aspectFill

		skView.presentScene(scene)
	}

	override var prefersStatusBarHidden: Bool {
		return true
	}
	
	@IBAction func restart(_ sender: UIButton) {
		FeedbackGenerator.impactOcurredWith(style: .light)
		scene?.restartScene()
	}
	
	@IBAction func pause(_ sender: UIButton) {
		
		FeedbackGenerator.impactOcurredWith(style: .light)
		
		if skView.isPaused {
		
			skView.isPaused = false
			
			if mySwitch.isOn {
				scene?.backgroundMusic?.play()
			}
		}
		else {
			skView.isPaused = true
			scene?.backgroundMusic?.pause()
		}
	}
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		if self.skView.isPaused {
			self.skView.isPaused = false
			scene?.backgroundMusic?.play()
		}
	}
	
	@IBAction func mute(_ sender: UISwitch) {
		
		if mySwitch.isOn {
			if mySwitch.isOn {
				scene?.backgroundMusic?.play()
			}
		}
		else {
			scene?.backgroundMusic?.stop()
		}
	}
}
