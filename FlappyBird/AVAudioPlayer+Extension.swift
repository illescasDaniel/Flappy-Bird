//
//  AVAudioPlayer+Extension.swift
//  FlappyBird
//
//  Created by Daniel Illescas Romero on 27/01/2018.
//  Copyright © 2018 Daniel Illescas Romero. All rights reserved.
//

import AVFoundation

extension AVAudioPlayer {
	
	enum AudioType: String {
		case mp3
		case wav
		// ...
	}
	
	convenience init?(file: String, type: AudioType) {
		
		guard let path = Bundle.main.path(forResource: file, ofType: type.rawValue) else {
			print("Incorrect Audio Path")
			return nil
		}

		try? self.init(contentsOf: URL(fileURLWithPath: path))
	}
}
