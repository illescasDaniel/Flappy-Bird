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

	var puntuacion = NSInteger()
	var puntuacionLabel = SKLabelNode()

	var musicaFondo: AVAudioPlayer?
	var audioPasaTubo: AVAudioPlayer?

	// ENTORNO
	override func didMoveToView(view: SKView) {

		// Música
		if let musicaFondo = self.setupAudioPlayerWithFile("bensound-littleidea", type: "mp3") {
			self.musicaFondo = musicaFondo
		}
		musicaFondo?.volume = 0.06
		musicaFondo?.play()

		self.addChild(movimiento)
		movimiento.addChild(adminTubos)

		// Físicas mundo
		self.physicsWorld.gravity = CGVectorMake(0.0, -5.0) // gravedad
		self.physicsWorld.contactDelegate = self // colisión

		// COLOR CIELO

		let colorCielo = SKColor(red: 113 / 255, green: 197 / 255, blue: 207 / 255, alpha: 1)
		self.backgroundColor = colorCielo

		// PÁJARO

		let texturaPajaro1 = SKTexture(imageNamed: "Bird1")
		texturaPajaro1.filteringMode = SKTextureFilteringMode.Nearest
		let texturaPajaro2 = SKTexture(imageNamed: "Bird2")
		texturaPajaro2.filteringMode = SKTextureFilteringMode.Nearest

		let animacionAleteo = SKAction.animateWithTextures([texturaPajaro1, texturaPajaro2], timePerFrame: 0.2)
		let vuelo = SKAction.repeatActionForever(animacionAleteo)

		pajaro = SKSpriteNode(texture: texturaPajaro1)
		pajaro.position = CGPoint(x: self.frame.size.width / 2.8, y: self.frame.size.height)

		pajaro.runAction(vuelo)

		// Físicas
		pajaro.physicsBody = SKPhysicsBody(circleOfRadius: pajaro.size.width / 2)
		pajaro.physicsBody?.dynamic = true
		pajaro.physicsBody?.allowsRotation = false

		pajaro.physicsBody?.categoryBitMask = categoriaPajaro
		pajaro.physicsBody?.collisionBitMask = categoriaSuelo | categoriaTubos
		pajaro.physicsBody?.contactTestBitMask = categoriaSuelo | categoriaTubos

		self.addChild(pajaro)

		// SUELO

		let texturaSuelo = SKTexture(imageNamed: "Ground")
		texturaSuelo.filteringMode = SKTextureFilteringMode.Nearest

		// Animación
		let movimientoSuelo = SKAction.moveByX(-texturaSuelo.size().width, y: 0, duration: NSTimeInterval(0.01 * texturaSuelo.size().width))
		let resetSuelo = SKAction.moveByX(texturaSuelo.size().width, y: 0, duration: 0.0)
		let movimientoSueloCte = SKAction.repeatActionForever(SKAction.sequence([movimientoSuelo, resetSuelo]))

		for j in 0..<(2 + Int(self.size.width / (texturaSuelo.size().width))) {

			let fraccion = SKSpriteNode(texture: texturaSuelo)
			fraccion.zPosition = -97
			fraccion.position = CGPointMake(CGFloat(j) * fraccion.size.width, fraccion.size.height / 2)
			fraccion.runAction(movimientoSueloCte)

			movimiento.addChild(fraccion)
		}

		let topeSuelo = SKNode()
		topeSuelo.position = CGPointMake(0, texturaSuelo.size().height / 2)
		topeSuelo.physicsBody = SKPhysicsBody(rectangleOfSize: CGSizeMake(self.frame.size.width, texturaSuelo.size().height))
		topeSuelo.physicsBody?.dynamic = false

		topeSuelo.physicsBody?.categoryBitMask = categoriaSuelo

		movimiento.addChild(topeSuelo)

		// CIELO

		let texturaCielo = SKTexture(imageNamed: "Sky")
		texturaCielo.filteringMode = SKTextureFilteringMode.Nearest

		// Animación
		let movimientoCielo = SKAction.moveByX(-texturaCielo.size().width, y: 0, duration: NSTimeInterval(0.05 * texturaCielo.size().width))
		let resetCielo = SKAction.moveByX(texturaCielo.size().width, y: 0, duration: 0.0)
		let movimientoCieloCte = SKAction.repeatActionForever(SKAction.sequence([movimientoCielo, resetCielo]))

		for j in 0..<(2 + Int(self.size.width / (texturaCielo.size().width))) {

			let fraccion = SKSpriteNode(texture: texturaCielo)
			fraccion.zPosition = -99
			fraccion.position = CGPointMake(CGFloat(j) * fraccion.size.width, fraccion.size.height - 100)
			fraccion.runAction(movimientoCieloCte)

			self.addChild(fraccion)
		}

		// TUBOS
		separacionTubos = Double(self.frame.size.height / 5)

		texturaTuboAbajo = SKTexture(imageNamed: "pipe1")
		texturaTuboAbajo.filteringMode = SKTextureFilteringMode.Nearest

		texturaTuboArriba = SKTexture(imageNamed: "pipe2")
		texturaTuboArriba.filteringMode = SKTextureFilteringMode.Nearest

		let distanciaMovimiento = CGFloat(self.frame.size.width + (texturaTuboAbajo.size().width * 2))
		let movimientoTubo = SKAction.moveByX(-distanciaMovimiento, y: 0, duration: NSTimeInterval(CGFloat(velocidadTubo) * distanciaMovimiento))
		let eliminarTubo = SKAction.removeFromParent()
		controlTubo = SKAction.sequence([movimientoTubo, eliminarTubo])

		let crearTubo = SKAction.runBlock({ () in self.gestionTubos() })
		let retardo = SKAction.waitForDuration(2.0) //
		let crearTuboSig = SKAction.sequence([crearTubo, retardo])
		let crearTuboSigForever = SKAction.repeatActionForever(crearTuboSig)

		self.runAction(crearTuboSigForever)

		puntuacion = 0
		puntuacionLabel.fontName = "Arial"
		puntuacionLabel.fontSize = 90
		puntuacionLabel.alpha = 0.4
		puntuacionLabel.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame) * 1.7) // 220?
		puntuacionLabel.zPosition = 0
		puntuacionLabel.text = "\(puntuacion)"

		self.addChild(puntuacionLabel)
	}

	func gestionTubos() {

		let conjuntoTubo = SKNode()
		conjuntoTubo.position = CGPointMake(self.frame.size.width + texturaTuboAbajo.size().width * 2, 0)
		conjuntoTubo.zPosition = -98

		let altura = UInt(self.frame.size.height / 3)
		let y = UInt(arc4random()) % altura

		// Tubo abajo
		let tuboAbajo = SKSpriteNode(texture: texturaTuboAbajo)
		tuboAbajo.position = CGPointMake(0.0, CGFloat(y))
		tuboAbajo.physicsBody = SKPhysicsBody(rectangleOfSize: tuboAbajo.size)
		tuboAbajo.physicsBody!.dynamic = false
		tuboAbajo.physicsBody?.categoryBitMask = categoriaTubos
		tuboAbajo.physicsBody?.contactTestBitMask = categoriaPajaro // Revisa si hay contacto con pájaro

		conjuntoTubo.addChild(tuboAbajo)

		// Tubo arriba

		let tuboArriba = SKSpriteNode(texture: texturaTuboArriba)
		tuboArriba.position = CGPointMake(0.0, CGFloat(y) + tuboAbajo.size.height + CGFloat(separacionTubos))
		tuboArriba.physicsBody = SKPhysicsBody(rectangleOfSize: tuboArriba.size)
		tuboArriba.physicsBody!.dynamic = false
		tuboArriba.physicsBody?.categoryBitMask = categoriaTubos
		tuboArriba.physicsBody?.contactTestBitMask = categoriaPajaro

		conjuntoTubo.addChild(tuboArriba)

		let avance = SKNode()
		avance.position = CGPointMake(tuboAbajo.size.width, CGRectGetMidY(self.frame))
		avance.physicsBody = SKPhysicsBody(rectangleOfSize: CGSizeMake(tuboAbajo.size.width, self.frame.size.height))
		avance.physicsBody?.dynamic = false
		avance.physicsBody?.categoryBitMask = categoriaAvance
		avance.physicsBody?.contactTestBitMask = categoriaPajaro

		conjuntoTubo.addChild(avance)

		conjuntoTubo.runAction(controlTubo)

		adminTubos.addChild(conjuntoTubo)
	}

	// TOQUES DE PANTALLA
	func reiniciarEscena() {
		pajaro.position = CGPoint(x: self.frame.size.width / 2.8, y: CGRectGetMidY(self.frame) * 1.5)
		pajaro.physicsBody?.velocity = CGVectorMake(0, 0)
		pajaro.speed = 0
		pajaro.zRotation = 0

		reset = false;
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

	override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {

		if muerto && musicaReproduciendose {
			musicaFondo?.play()
		}

		if movimiento.speed > 0 {
			pajaro.physicsBody?.velocity = CGVectorMake(0, 0)
			pajaro.physicsBody?.applyImpulse(CGVectorMake(0, 12))
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

	override func update(currentTime: CFTimeInterval) {

		// Rotación del pájaro
		pajaro.zRotation = self.rotacion(-1, max: 0.5, valor: (pajaro.physicsBody?.velocity.dy)! * ((pajaro.physicsBody?.velocity.dy)! < 0 ? 0.003 : 0.001))
	}

	// CONTACTOS
	func didBeginContact(contact: SKPhysicsContact) {

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
				let movimientoTubo = SKAction.moveByX(-distanciaMovimiento, y: 0, duration: NSTimeInterval(CGFloat(velocidadTubo) * distanciaMovimiento))
				controlTubo = SKAction.sequence([movimientoTubo, SKAction.removeFromParent()])

				// Sonido al pasar por tubería

				if let audioPasaTubo = self.setupAudioPlayerWithFile("collectcoin", type: "wav") {
					self.audioPasaTubo = audioPasaTubo
				}
				audioPasaTubo?.volume = 0.2
				audioPasaTubo?.play()
			}
			else {
				musicaReproduciendose = (musicaFondo?.playing)!
				muerto = true
				musicaFondo?.stop()

				movimiento.speed = 0
				let resetJuego = SKAction.runBlock({ () in self.resetGame() })
				let cambiarCieloRojo = SKAction.runBlock({ self.backgroundColor = UIColor.redColor() })

				let conjuntoGameOver = SKAction.group([cambiarCieloRojo, resetJuego])
				self.runAction(conjuntoGameOver)
			}

		}

	}

	func resetGame() {
		reset = true
	}

	func setupAudioPlayerWithFile(file: NSString, type: NSString) -> AVAudioPlayer? {

		let path = NSBundle.mainBundle().pathForResource(file as String, ofType: type as String)
		let url = NSURL.fileURLWithPath(path!)

		var audioPlayer: AVAudioPlayer?

		do {
			try audioPlayer = AVAudioPlayer(contentsOfURL: url)
		} catch {
			print("Player not available")
		}

		return audioPlayer
	}
}
