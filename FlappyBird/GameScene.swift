import SpriteKit
import AVFoundation

class GameScene: SKScene, SKPhysicsContactDelegate {

	var pajaro = SKSpriteNode()
	var colorCierlo = SKColor()
	var texturaTuboAbajo = SKTexture()
	var texturaTuboArriba = SKTexture()
	var separacionTubos = Double()
	var velocidadTubo: Float = 0.008
	var controlTubo = SKAction()

	let categoriaPajaro: UInt32 = 1 << 0
	let categoriaSuelo: UInt32 = 1 << 1
	let categoriaTubos: UInt32 = 1 << 2
	let categoriaAvance: UInt32 = 1 << 3

	var movimiento = SKNode()
	var reset = false
	var muerto = false
	var musicaReproduciendose = false
	var adminTubos = SKNode()

	var puntuacion = Int()
	var puntuacionLabel = SKLabelNode()

	var musicaFondo: AVAudioPlayer?
	var audioPasaTubo: AVAudioPlayer?

	// ENTORNO
	override func didMove(to view: SKView) {

		// Música
		if let musicaFondo = self.setupAudioPlayerWithFile(file: "bensound-littleidea", type: "mp3") {
			self.musicaFondo = musicaFondo
		}
		musicaFondo?.volume = 0.06
		musicaFondo?.play()

		self.addChild(movimiento)
		movimiento.addChild(adminTubos)

		// Físicas mundo
		
		self.physicsWorld.gravity = CGVector(dx: 0.0, dy: -5.0) //CGVectorMake(0.0, -5.0) // gravedad
		self.physicsWorld.contactDelegate = self // colisión

		// COLOR CIELO

		let colorCielo = SKColor(red: 113 / 255, green: 197 / 255, blue: 207 / 255, alpha: 1)
		self.backgroundColor = colorCielo

		// PÁJARO

		let texturaPajaro1 = SKTexture(imageNamed: "Bird1")
		texturaPajaro1.filteringMode = SKTextureFilteringMode.nearest
		let texturaPajaro2 = SKTexture(imageNamed: "Bird2")
		texturaPajaro2.filteringMode = SKTextureFilteringMode.nearest

		let animacionAleteo = SKAction.animate(with: [texturaPajaro1, texturaPajaro2], timePerFrame: 0.2)
		let vuelo = SKAction.repeatForever(animacionAleteo)

		pajaro = SKSpriteNode(texture: texturaPajaro1)
		pajaro.position = CGPoint(x: self.frame.size.width / 2.8, y: self.frame.size.height)

		pajaro.run(vuelo)

		// Físicas
		pajaro.physicsBody = SKPhysicsBody(circleOfRadius: pajaro.size.width / 2)
		pajaro.physicsBody?.isDynamic = true
		pajaro.physicsBody?.allowsRotation = false

		pajaro.physicsBody?.categoryBitMask = categoriaPajaro
		pajaro.physicsBody?.collisionBitMask = categoriaSuelo | categoriaTubos
		pajaro.physicsBody?.contactTestBitMask = categoriaSuelo | categoriaTubos

		self.addChild(pajaro)

		// SUELO

		let texturaSuelo = SKTexture(imageNamed: "Ground")
		texturaSuelo.filteringMode = SKTextureFilteringMode.nearest

		// Animación
		let movimientoSuelo = SKAction.moveBy(x: -texturaSuelo.size().width, y: 0, duration: TimeInterval(0.01 * texturaSuelo.size().width))
		let resetSuelo = SKAction.moveBy(x: texturaSuelo.size().width, y: 0, duration: 0.0)
		let movimientoSueloCte = SKAction.repeatForever(SKAction.sequence([movimientoSuelo, resetSuelo]))

		for j in 0..<(2 + Int(self.size.width / (texturaSuelo.size().width))) {

			let fraccion = SKSpriteNode(texture: texturaSuelo)
			fraccion.zPosition = -97
			fraccion.position = CGPoint(x: CGFloat(j) * fraccion.size.width, y: fraccion.size.height / 2)
			fraccion.run(movimientoSueloCte)

			movimiento.addChild(fraccion)
		}

		let topeSuelo = SKNode()
		topeSuelo.position = CGPoint(x: 0, y: texturaSuelo.size().height / 2)
		topeSuelo.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: self.frame.size.width, height: texturaSuelo.size().height))
		topeSuelo.physicsBody?.isDynamic = false

		topeSuelo.physicsBody?.categoryBitMask = categoriaSuelo

		movimiento.addChild(topeSuelo)

		// CIELO

		let texturaCielo = SKTexture(imageNamed: "Sky")
		texturaCielo.filteringMode = SKTextureFilteringMode.nearest

		// Animación
		let movimientoCielo = SKAction.moveBy(x: -texturaCielo.size().width, y: 0, duration: TimeInterval(0.05 * texturaCielo.size().width))
		let resetCielo = SKAction.moveBy(x: texturaCielo.size().width, y: 0, duration: 0.0)
		let movimientoCieloCte = SKAction.repeatForever(SKAction.sequence([movimientoCielo, resetCielo]))

		for j in 0..<(2 + Int(self.size.width / (texturaCielo.size().width))) {

			let fraccion = SKSpriteNode(texture: texturaCielo)
			fraccion.zPosition = -99
			fraccion.position = CGPoint(x: CGFloat(j) * fraccion.size.width, y: fraccion.size.height - 100)
			fraccion.run(movimientoCieloCte)

			self.addChild(fraccion)
		}

		// TUBOS
		separacionTubos = Double(self.frame.size.height / 5)

		texturaTuboAbajo = SKTexture(imageNamed: "pipe1")
		texturaTuboAbajo.filteringMode = SKTextureFilteringMode.nearest

		texturaTuboArriba = SKTexture(imageNamed: "pipe2")
		texturaTuboArriba.filteringMode = SKTextureFilteringMode.nearest

		let distanciaMovimiento = CGFloat(self.frame.size.width + (texturaTuboAbajo.size().width * 2))
		let movimientoTubo = SKAction.moveBy(x: -distanciaMovimiento, y: 0, duration: TimeInterval(CGFloat(velocidadTubo) * distanciaMovimiento))
		let eliminarTubo = SKAction.removeFromParent()
		controlTubo = SKAction.sequence([movimientoTubo, eliminarTubo])

		let crearTubo = SKAction.run({ () in self.gestionTubos() })
		let retardo = SKAction.wait(forDuration: 2.0) //
		let crearTuboSig = SKAction.sequence([crearTubo, retardo])
		let crearTuboSigForever = SKAction.repeatForever(crearTuboSig)

		self.run(crearTuboSigForever)

		puntuacion = 0
		puntuacionLabel.fontName = "Arial"
		puntuacionLabel.fontSize = 90
		puntuacionLabel.alpha = 0.4
		puntuacionLabel.position = CGPoint(x: self.frame.midX, y: self.frame.midY * 1.7) // 220?
		puntuacionLabel.zPosition = 0
		puntuacionLabel.text = "\(puntuacion)"

		self.addChild(puntuacionLabel)
	}

	func gestionTubos() {

		let conjuntoTubo = SKNode()
		conjuntoTubo.position = CGPoint(x: self.frame.size.width + texturaTuboAbajo.size().width * 2, y: 0)
		conjuntoTubo.zPosition = -98

		let altura = UInt(self.frame.size.height / 3)
		let y = UInt(arc4random()) % altura

		// Tubo abajo
		let tuboAbajo = SKSpriteNode(texture: texturaTuboAbajo)
		tuboAbajo.position = CGPoint(x: 0.0, y: CGFloat(y))
		tuboAbajo.physicsBody = SKPhysicsBody(rectangleOf: tuboAbajo.size)
		tuboAbajo.physicsBody!.isDynamic = false
		tuboAbajo.physicsBody?.categoryBitMask = categoriaTubos
		tuboAbajo.physicsBody?.contactTestBitMask = categoriaPajaro // Revisa si hay contacto con pájaro

		conjuntoTubo.addChild(tuboAbajo)

		// Tubo arriba

		let tuboArriba = SKSpriteNode(texture: texturaTuboArriba)
		tuboArriba.position = CGPoint(x: 0.0, y: CGFloat(y) + tuboAbajo.size.height + CGFloat(separacionTubos))
		tuboArriba.physicsBody = SKPhysicsBody(rectangleOf: tuboArriba.size)
		tuboArriba.physicsBody!.isDynamic = false
		tuboArriba.physicsBody?.categoryBitMask = categoriaTubos
		tuboArriba.physicsBody?.contactTestBitMask = categoriaPajaro

		conjuntoTubo.addChild(tuboArriba)

		let avance = SKNode()
		avance.position = CGPoint(x: tuboAbajo.size.width, y: self.frame.midY)
		avance.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: tuboAbajo.size.width, height: self.frame.size.height))
		avance.physicsBody?.isDynamic = false
		avance.physicsBody?.categoryBitMask = categoriaAvance
		avance.physicsBody?.contactTestBitMask = categoriaPajaro

		conjuntoTubo.addChild(avance)

		conjuntoTubo.run(controlTubo)

		adminTubos.addChild(conjuntoTubo)
	}

	// TOQUES DE PANTALLA
	func reiniciarEscena() {
		
		pajaro.position = CGPoint(x: self.frame.size.width / 2.8, y: self.frame.midY * 1.5)
		pajaro.physicsBody?.velocity = CGVector.zero //CGVectorMake(0, 0)
		pajaro.speed = 0
		pajaro.zRotation = 0

		reset = false
		movimiento.speed = 1

		self.backgroundColor = SKColor(red: 113 / 255, green: 197 / 255, blue: 207 / 255, alpha: 1)

		adminTubos.removeAllChildren()

		// Reinicia puntuación
		puntuacion = 0
		puntuacionLabel.text = "\(puntuacion)"
		separacionTubos = Double(self.frame.size.height / 5)
		velocidadTubo = 0.008
		muerto = false
	}
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		
		if muerto && musicaReproduciendose {
			musicaFondo?.play()
		}
		
		if movimiento.speed > 0 {
			pajaro.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
			pajaro.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 12))
		}
		else if reset {
			self.reiniciarEscena()
		}
	}

	// ACTUALIZACIONES
	func rotacion (min: CGFloat, max: CGFloat, valor: CGFloat) -> CGFloat {

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
		// Rotación del pájaro
		pajaro.zRotation = self.rotacion(min: -1, max: 0.5, valor: (pajaro.physicsBody?.velocity.dy)! * ((pajaro.physicsBody?.velocity.dy)! < 0 ? 0.003 : 0.001))
	}
	
	// CONTACTOS
	func didBegin(_ contact: SKPhysicsContact) {
		
		if movimiento.speed > 0 {
			
			if ((contact.bodyA.categoryBitMask & categoriaAvance) == categoriaAvance || (contact.bodyB.categoryBitMask & categoriaAvance) == categoriaAvance) {
				puntuacion += 1
				puntuacionLabel.text = "\(puntuacion)"
				
				// Aumenta dificultad
				
				if separacionTubos > Double(pajaro.size.height) * 4.52 {
					separacionTubos -= Double(pajaro.size.height) * 0.15
				}
				
				velocidadTubo -= 0.00015
				
				let distanciaMovimiento = CGFloat(self.frame.size.width + (texturaTuboAbajo.size().width * 2))
				let movimientoTubo = SKAction.moveBy(x: -distanciaMovimiento, y: 0, duration: TimeInterval(CGFloat(velocidadTubo) * distanciaMovimiento))
				controlTubo = SKAction.sequence([movimientoTubo, SKAction.removeFromParent()])
				
				// Sonido al pasar por tubería
				
				if let audioPasaTubo = self.setupAudioPlayerWithFile(file: "collectcoin", type: "wav") {
					self.audioPasaTubo = audioPasaTubo
				}
				audioPasaTubo?.volume = 0.2
				audioPasaTubo?.play()
			}
			else {
				
				FeedbackGenerator.notificationOcurredOf(type: .error)
				
				musicaReproduciendose = (musicaFondo?.isPlaying)!
				muerto = true
				musicaFondo?.stop()
				
				movimiento.speed = 0
				let resetJuego = SKAction.run({ () in self.resetGame() })
				let cambiarCieloRojo = SKAction.run({ self.backgroundColor = UIColor.red })
				
				let conjuntoGameOver = SKAction.group([cambiarCieloRojo, resetJuego])
				self.run(conjuntoGameOver)
			}
		}
	}

	func resetGame() {
		reset = true
	}

	func setupAudioPlayerWithFile(file: String, type: String) -> AVAudioPlayer? {

		let path = Bundle.main.path(forResource: file, ofType: type)
		
		let url = URL(fileURLWithPath: path!)

		var audioPlayer: AVAudioPlayer?

		do {
			try audioPlayer = AVAudioPlayer(contentsOf: url)
		} catch {
			print("Player not available")
		}

		return audioPlayer
	}
}
