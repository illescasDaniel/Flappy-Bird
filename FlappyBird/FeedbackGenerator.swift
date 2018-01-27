//
//  FeedbackGenerator.swift
//  FlappyBird
//
//  Created by Daniel Illescas Romero on 27/01/2018.
//  Copyright © 2018 Daniel Illescas Romero. All rights reserved.
//

import UIKit

struct FeedbackGenerator {
	
	static func impactOcurredWith(style: UIImpactFeedbackStyle) {
		if #available(iOS 10.0, *) {
			FeedbackGeneratorHelper.shared.impactOcurredWith(style: style)
		}
	}
	
	static func notificationOcurredOf(type: UINotificationFeedbackType) {
		if #available(iOS 10.0, *) {
			FeedbackGeneratorHelper.shared.notificationOcurredOf(type: type)
		}
	}
	
	static func selectionChanged() {
		if #available(iOS 10.0, *) {
			FeedbackGeneratorHelper.shared.selectionChanged()
		}
	}
}

@available(iOS 10.0, *)
fileprivate struct FeedbackGeneratorHelper {
	
	fileprivate static let shared = FeedbackGeneratorHelper()
	
	private let lightImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light).prepared()
	private let mediumImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium).prepared()
	private let heavyImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .heavy).prepared()
	private let notificationFeedbackGenerator = UINotificationFeedbackGenerator.prepared()
	private let selectionFeedbackGenerator = UISelectionFeedbackGenerator.prepared()
	
	fileprivate init() { }
	
	fileprivate func impactOcurredWith(style: UIImpactFeedbackStyle) {
		switch(style) {
		case .light: self.lightImpactFeedbackGenerator.prepare(); self.lightImpactFeedbackGenerator.impactOccurred()
		case .medium: self.mediumImpactFeedbackGenerator.impactOccurred()//self.mediumImpactFeedbackGenerator.prepare(); self.mediumImpactFeedbackGenerator.impactOccurred()
		case .heavy: self.heavyImpactFeedbackGenerator.prepare(); self.heavyImpactFeedbackGenerator.impactOccurred()
		}
	}
	
	fileprivate func notificationOcurredOf(type: UINotificationFeedbackType) {
		self.notificationFeedbackGenerator.prepare()
		self.notificationFeedbackGenerator.notificationOccurred(type)
	}
	
	fileprivate func selectionChanged() {
		self.selectionFeedbackGenerator.prepare()
		self.selectionFeedbackGenerator.selectionChanged()
	}
}

@available (iOS 10.0, *)
fileprivate extension UIFeedbackGenerator {
	fileprivate static func prepared() -> Self {
		let feedbackGenerator = self.init()
		feedbackGenerator.prepare()
		return feedbackGenerator
	}
	fileprivate func prepared() -> Self {
		self.prepare()
		return self
	}
}

