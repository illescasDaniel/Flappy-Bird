import SpriteKit
import AVFoundation

class GameScene: SKScene, SKPhysicsContactDelegate {

	var bird = SKSpriteNode()
	var skyColor = SKColor()
	var bottomPipeTexture = SKTexture()
	var topPipeTexture = SKTexture()
	var pipesSeparation = Double()
	var pipesSpeed: Float = 0.008
	var pipeControl = SKAction()

	let birdCategory: UInt32 = 1 << 0
	let floorCategory: UInt32 = 1 << 1
	let pipeCategory: UInt32 = 1 << 2
	let progressCategory: UInt32 = 1 << 3

	var movement = SKNode()
	var reset = false
	var isBirdDead = false
	var isMusicPlaying = false // REMOVE?
	var tubesAdmin = SKNode()

	var score = Int()
	var scoreLabel = SKLabelNode()

	var backgroundMusic = AVAudioPlayer(file: "bensound-littleidea", type: .mp3)
	var increaseScoreSound = AVAudioPlayer(file: "collectcoin", type: .wav)

	// Environment
	override func didMove(to view: SKView) {

		// Music
		backgroundMusic?.volume = 0.06
		backgroundMusic?.play()
		increaseScoreSound?.volume = 0.2

		self.addChild(movement)
		movement.addChild(tubesAdmin)

		// World physics
		
		self.physicsWorld.gravity = CGVector(dx: 0.0, dy: -5.0)
		self.physicsWorld.contactDelegate = self // collision

		// Sky color

		skyColor = SKColor(red: 113 / 255, green: 197 / 255, blue: 207 / 255, alpha: 1)
		self.backgroundColor = skyColor

		// Bird

		let birdTexture1 = SKTexture(imageNamed: "Bird1")
		birdTexture1.filteringMode = SKTextureFilteringMode.nearest
		let birdTexture2 = SKTexture(imageNamed: "Bird2")
		birdTexture2.filteringMode = SKTextureFilteringMode.nearest

		let flapAnimation = SKAction.animate(with: [birdTexture1, birdTexture2], timePerFrame: 0.2)
		let flight = SKAction.repeatForever(flapAnimation)

		bird = SKSpriteNode(texture: birdTexture1)
		bird.position = CGPoint(x: self.frame.size.width / 2.8, y: self.frame.size.height)

		bird.run(flight)

		// Físicas
		bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.width / 2)
		bird.physicsBody?.isDynamic = true
		bird.physicsBody?.allowsRotation = false

		bird.physicsBody?.categoryBitMask = birdCategory
		bird.physicsBody?.collisionBitMask = floorCategory | pipeCategory
		bird.physicsBody?.contactTestBitMask = floorCategory | pipeCategory

		self.addChild(bird)

		// Floor

		let floorTexture = SKTexture(imageNamed: "Ground")
		floorTexture.filteringMode = SKTextureFilteringMode.nearest

		// Animation
		let floorMovement = SKAction.moveBy(x: -floorTexture.size().width, y: 0, duration: TimeInterval(0.01 * floorTexture.size().width))
		let resetFloor = SKAction.moveBy(x: floorTexture.size().width, y: 0, duration: 0.0)
		let constantFloorMovement = SKAction.repeatForever(SKAction.sequence([floorMovement, resetFloor]))

		for j in 0..<(2 + Int(self.size.width / (floorTexture.size().width))) {

			let fraction = SKSpriteNode(texture: floorTexture)
			fraction.zPosition = -97
			fraction.position = CGPoint(x: CGFloat(j) * fraction.size.width, y: fraction.size.height / 2)
			fraction.run(constantFloorMovement)

			movement.addChild(fraction)
		}

		let floorLimit = SKNode()
		floorLimit.position = CGPoint(x: 0, y: floorTexture.size().height / 2)
		floorLimit.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: self.frame.size.width, height: floorTexture.size().height))
		floorLimit.physicsBody?.isDynamic = false

		floorLimit.physicsBody?.categoryBitMask = floorCategory

		movement.addChild(floorLimit)

		// Sky

		let skyTexture = SKTexture(imageNamed: "Sky")
		skyTexture.filteringMode = SKTextureFilteringMode.nearest

		// Animación
		let skyMovement = SKAction.moveBy(x: -skyTexture.size().width, y: 0, duration: TimeInterval(0.05 * skyTexture.size().width))
		let restartSky = SKAction.moveBy(x: skyTexture.size().width, y: 0, duration: 0.0)
		let contantSkyMovement = SKAction.repeatForever(SKAction.sequence([skyMovement, restartSky]))

		for j in 0..<(2 + Int(self.size.width / (skyTexture.size().width))) {

			let fraction = SKSpriteNode(texture: skyTexture)
			fraction.zPosition = -99
			fraction.position = CGPoint(x: CGFloat(j) * fraction.size.width, y: fraction.size.height - 100)
			fraction.run(contantSkyMovement)

			self.addChild(fraction)
		}

		// Pipes
		pipesSeparation = Double(self.frame.size.height / 5)

		bottomPipeTexture = SKTexture(imageNamed: "pipe1")
		bottomPipeTexture.filteringMode = SKTextureFilteringMode.nearest

		topPipeTexture = SKTexture(imageNamed: "pipe2")
		topPipeTexture.filteringMode = SKTextureFilteringMode.nearest

		let movementDistance = CGFloat(self.frame.size.width + (bottomPipeTexture.size().width * 2))
		let pipeMovement = SKAction.moveBy(x: -movementDistance, y: 0, duration: TimeInterval(CGFloat(pipesSpeed) * movementDistance))
		let removePipe = SKAction.removeFromParent()
		pipeControl = SKAction.sequence([pipeMovement, removePipe])

		let createPipe = SKAction.run { self.managePipes() }
		let delay = SKAction.wait(forDuration: 2.0) //
		let createNextPipe = SKAction.sequence([createPipe, delay])
		let foreverCreateNextPipe = SKAction.repeatForever(createNextPipe)

		self.run(foreverCreateNextPipe)

		score = 0
		scoreLabel.fontName = "Arial"
		scoreLabel.fontSize = 90
		scoreLabel.alpha = 0.4
		scoreLabel.position = CGPoint(x: self.frame.midX, y: self.frame.midY * 1.7) // 220?
		scoreLabel.zPosition = 0
		scoreLabel.text = "\(score)"

		self.addChild(scoreLabel)
	}

	func managePipes() {

		let pipeGroup = SKNode()
		pipeGroup.position = CGPoint(x: self.frame.size.width + bottomPipeTexture.size().width * 2, y: 0)
		pipeGroup.zPosition = -98

		let height = UInt(self.frame.size.height / 3)
		let y = arc4random_uniform(UInt32(height)) //UInt(arc4random()) % height

		// Bottom pipe
		let bottomPipe = SKSpriteNode(texture: bottomPipeTexture)
		bottomPipe.position = CGPoint(x: 0.0, y: CGFloat(y))
		bottomPipe.physicsBody = SKPhysicsBody(rectangleOf: bottomPipe.size)
		bottomPipe.physicsBody?.isDynamic = false
		bottomPipe.physicsBody?.categoryBitMask = pipeCategory
		bottomPipe.physicsBody?.contactTestBitMask = birdCategory

		pipeGroup.addChild(bottomPipe)

		// Top pipe

		let topPipe = SKSpriteNode(texture: topPipeTexture)
		topPipe.position = CGPoint(x: 0.0, y: CGFloat(y) + bottomPipe.size.height + CGFloat(pipesSeparation))
		topPipe.physicsBody = SKPhysicsBody(rectangleOf: topPipe.size)
		topPipe.physicsBody?.isDynamic = false
		topPipe.physicsBody?.categoryBitMask = pipeCategory
		topPipe.physicsBody?.contactTestBitMask = birdCategory

		pipeGroup.addChild(topPipe)

		let progress = SKNode()
		progress.position = CGPoint(x: bottomPipe.size.width, y: self.frame.midY)
		progress.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: bottomPipe.size.width, height: self.frame.size.height))
		progress.physicsBody?.isDynamic = false
		progress.physicsBody?.categoryBitMask = progressCategory
		progress.physicsBody?.contactTestBitMask = birdCategory

		pipeGroup.addChild(progress)

		pipeGroup.run(pipeControl)

		tubesAdmin.addChild(pipeGroup)
	}

	func restartScene() {
		
		bird.position = CGPoint(x: self.frame.size.width / 2.8, y: self.frame.midY * 1.5)
		bird.physicsBody?.velocity = CGVector.zero
		bird.speed = 0
		bird.zRotation = 0

		reset = false
		movement.speed = 1

		self.backgroundColor = SKColor(red: 113 / 255, green: 197 / 255, blue: 207 / 255, alpha: 1)

		tubesAdmin.removeAllChildren()

		// Restart score
		score = 0
		scoreLabel.text = "\(score)"
		pipesSeparation = Double(self.frame.size.height / 5)
		pipesSpeed = 0.008
		isBirdDead = false
	}
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		
		if isBirdDead && isMusicPlaying {
			backgroundMusic?.play()
		}
		
		if movement.speed > 0 {
			bird.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
			bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 12))
		}
		else if reset {
			self.restartScene()
		}
	}

	func birdRotation(min: CGFloat, max: CGFloat, valor: CGFloat) -> CGFloat {
		if valor > max {
			return max
		}
		else if valor < min {
			return min
		}
		else {
			return valor
		}
	}

	override func update(_ currentTime: CFTimeInterval) {
		bird.zRotation = self.birdRotation(min: -1, max: 0.5, valor: (bird.physicsBody?.velocity.dy)! * ((bird.physicsBody?.velocity.dy)! < 0 ? 0.003 : 0.001))
	}
	
	func didBegin(_ contact: SKPhysicsContact) {
		
		DispatchQueue.main.async {
			
			self.increaseScoreSound?.prepareToPlay()
			
			if self.movement.speed > 0 {
				
				if ((contact.bodyA.categoryBitMask & self.progressCategory) == self.progressCategory || (contact.bodyB.categoryBitMask & self.progressCategory) == self.progressCategory) {
					self.score += 1
					self.scoreLabel.text = "\(self.score)"
					
					// Increase difficulty
					
					if self.pipesSeparation > Double(self.bird.size.height) * 4.52 {
						self.pipesSeparation -= Double(self.bird.size.height) * 0.15
					}
					
					self.pipesSpeed -= 0.00015
					
					let distanciaMovimiento = CGFloat(self.frame.size.width + (self.bottomPipeTexture.size().width * 2))
					let movimientoTubo = SKAction.moveBy(x: -distanciaMovimiento, y: 0, duration: TimeInterval(CGFloat(self.pipesSpeed) * distanciaMovimiento))
					self.pipeControl = SKAction.sequence([movimientoTubo, SKAction.removeFromParent()])
					
					// Sound when passing a pipe
					self.increaseScoreSound?.play()
				}
				else {
					
					FeedbackGenerator.notificationOcurredOf(type: .error)
					
					self.isMusicPlaying = (self.backgroundMusic?.isPlaying)!
					self.isBirdDead = true
					self.backgroundMusic?.stop()
					
					self.movement.speed = 0
					let resetGame = SKAction.run { self.resetGame() }
					let changeSkyColorToRed = SKAction.run { self.backgroundColor = UIColor.red }
					
					let gameOverGroup = SKAction.group([changeSkyColorToRed, resetGame])
					self.run(gameOverGroup)
				}
			}
		}
	}

	private func resetGame() {
		self.reset = true
	}
}
