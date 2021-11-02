//
//  LocalisationModel.swift
//  DynamicLocalisation
//
//  Created by Laurent B on 27/10/2021.
//

import Foundation


public enum Language: String, Codable {
	case de = "de-DE"
	case en = "en-US"
}

public class TourLocalization: Codable {

	public let jsonVersion: String
	public let fallbackFromServer: String
	public var fallbackComputed: Language { Language(rawValue: fallbackFromServer) ?? .de }
	public let entries : [Entry]

	enum CodingKeys: String, CodingKey {
		case jsonVersion = "jsonVersion"
		case fallbackFromServer = "fallback"
		case entries = "entries"
	}

	// MARK: - Init.
	public init(jsonVersion: String,
				fallbackFromServer: String,
				entries: [Entry]) {
		self.jsonVersion = jsonVersion
		self.fallbackFromServer = fallbackFromServer
		self.entries = entries
	}

}

public struct Entry: Codable {

	public let key: String // like "Tour1Name"
	public let values : [String: String]  //The key here is  "de-DE" and the value is the translation

	enum CodingKeys: String, CodingKey {
		case key = "key"
		case values = "values"
	}

	// MARK: - Init.
	public init(key: String,
				values: [String : String]) {
		self.key = key
		self.values = values
	}
}
