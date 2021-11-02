//
//  LocalisationManager.swift
//  DynamicLocalisation
//
//  Created by Laurent B on 26/10/2021.
//

import SwiftUI

extension Bundle {
  var developerLanguage: String {
	return object(forInfoDictionaryKey: "CFBundleDevelopmentRegion") as? String ?? ""
  }
}
public final class RMLocalizationManager : ObservableObject {
	// create a singleton
	public static var shared = RMLocalizationManager()

	//private static var privateSharedInstance: RMLocalizationManager?

//	static var shared = RMLocalizationManager() {
//		if privateSharedInstance == nil {
//			privateSharedInstance = RMLocalizationManager()
//		}
//		return privateSharedInstance!
//	}

	init(){
		print("developerLanguage: ", Bundle.main.developerLanguage)
	}
	
	// this is the name of the bundle I will create on the doc folder on the device
	private let bundleNameForLocalisation = "RMDynamicLocalisation.bundle"
	
	// properties used to transforming the json to data
	private var fallbackLanguage: String = "" // will be updated in init
	private var translations: Dictionary<String, [String:String]> = [:]

	
	// default is the main bundle
	public var currentBundle = Bundle.main
	// I need to set the table name for different areas of the app
	// it will be used in the Text initialiser together with the Bundle name
	public var tableName: String = "myStrings"

	// convenience variable
	private let manager = FileManager.default
	private static let documentsDirectoryURL = try! FileManager().url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)


	// This is the dynamic custom bundle path I will use (eventually not yet created)
	private lazy var bundlePath: URL = {
		let bundlePath = Self.documentsDirectoryURL.appendingPathComponent(bundleNameForLocalisation, isDirectory: true)
		print("the localised bundlePath", bundlePath)
		return bundlePath
	}()
	
	/// called first thing in the app
	/// this will update our currentBundle property but also doing a check that the folder exists and that a string file is avail
	public func setCurrentBundle(forLanguage: String) {
		do {
			currentBundle = try returnCurrentBundleFor(language: forLanguage)
		} catch {
			print(#line, "=== Not custom - getPathForLocalLanguage 🤚🏻🤚🏻🤚🏻 =========")
			let currentLocale = Bundle.main.preferredLocalizations.first!
			currentBundle = Bundle(path: getPathForLocalLanguage(language: currentLocale))!
		}
	}


	// when I want to access a different table (.string file)
	public func setTableName(tablename: String) {
		self.tableName = tablename
	}


	/// I will add strings files to the custom bundle passing a json file to decode
	/// - Parameters:
	///   - json: The json containing my languages, keys and translations
	///   - table: the table will be the name of the .strings file
	public func createLocalizedFiles(from json: String, table: String) {
		self.tableName = table
		getTheLocalisedAssets(from: json)
		// after I get  the assets I write to disk
		do {
			try writeDataToBundle()
		} catch {
			print(error.localizedDescription)
		}
	}
	
	
	/// Called in `createLocalizedFiles()`
	/// - Parameter json: The json containing my languages, keys and translations
	private func getTheLocalisedAssets(from json: String) {
		
		// this could be coming from the server but for now it is on disk
		let tourLocalization: TourLocalization = load(json)
		self.fallbackLanguage = tourLocalization.fallbackFromServer
		
		// all my entries are in format -> Stringkey : [{languageKey : translation}, {languageKey : translation}] where the language key is "de-DE"
		self.translations = getTranslations(from: tourLocalization.entries, fallback: tourLocalization.fallbackFromServer )
		
		// debug parsing
		print("========= entries ======\n")
		dump(tourLocalization)
		/* an array of
		 DynamicLocalisation.Entry
		 - key: "Tour1Quiz1Question3Option1"
		 ▿ values: 1 key/value pair
		 ▿ (2 elements)
		 - key: "de-DE"
		 - value: "3.1-Pastry macaroon toffee jujubes carrot cake muffin apple pie."
		 */
		
		// preferredLocalizations returns an array of one language only
		print(Bundle.main.preferredLocalizations,  "preferredLocalizations!")  // "de"
		print(Bundle.main.localizations,  "localizations!") //["de", "en", "Base", "fr"]
	}


	private func getTranslations(from entries: [Entry], fallback: String = "de-DE") -> Dictionary<String, [String:String]> {
		print("My translations 🎠🎠🎠")
		dump(entries[0])
		
		// start with empty dict
		var translationsDictionary: Dictionary<String, [String:String]> = [:]
		// initialize dict with my languages ["en": [:], "fr": [:], "Base": [:], "de": [:]]
		// translationsDictionary starts empty like this ["fr": [:], "en": [:], "Base": [:], "de": [:]]
		
		print("translationsDictionary 📕📕 ", translationsDictionary)
		// each entry might not have values for every language - therefore there is a fallback
		for entry in entries {
			
			// for each entry I need to know which lang are avail and which are missing
			var poolOfLanguagesForEntry: [String] = Array(entry.values.keys)
			
			// debug only
			//poolOfLanguagesForEntry.append(contentsOf: ["de", "en"])
			// I will check the avail languages. If a language is avail on device but have no translation I will use the fallback value. PS I do not need "Base" I think
			for localisation in Bundle.main.localizations where localisation != "Base" {
				
				// here the value of the entry is actually itself a dict, so I iterate on it. if a language is missing I will add the fallback
				for (keyvalue, value) in entry.values {
					let langKey = keyvalue // no need to convert from en-US to like "en" to use in my translations folder names
					
					// in this case all is good. My avail lang is also avail in the json
					if localisation == keyvalue {
						// get the contents from my translationsDictionary if any already
						var existingDict = translationsDictionary[langKey, default: [:]]
						// add the new entry to the nested dict - the entry.key at root is my "keyword": like "tour1", the key in values is ex "en-US" and translated text is the value in the iterated values
						existingDict[entry.key] = value // existingDict["Tour1"] = "Tour 1"
						//and this updated dict will be put in the main dict which will be in the en.proj folder or de.proj folder depending
						translationsDictionary[localisation] = existingDict
					} else if localisation == Bundle.main.developerLanguage {
						var existingDict = translationsDictionary["en-US", default: [:]]
						existingDict[entry.key] = entry.values["en-US"]
						// again update the dict
						translationsDictionary[localisation] = existingDict
					} else if localisation == "de" {
						var existingDict = translationsDictionary["de-DE", default: [:]]
						existingDict[entry.key] = entry.values["de-DE"]
						// again update the dict
						translationsDictionary[localisation] = existingDict
					} else {
						// default will be the fallback but only if the language is not avail in the language pool for entry
						if poolOfLanguagesForEntry.contains(localisation) { continue }
						print("poolOfLanguagesForEntry -> ", poolOfLanguagesForEntry, "not contains", localisation)
						
						// If I am here it is because my localisation needs a default
						// again I get the contents from my translationsDictionary if any
						var existingDict = translationsDictionary[localisation, default: [:]]
						// add the new entry to the nested dict - the entry.key at root is still my "keyword": like "tour1", I will use the fallback lang to get the translated text in the value of the values dict
						existingDict[entry.key] = entry.values[fallback]
						// again update the dict
						translationsDictionary[localisation] = existingDict
					}
				}
			}
		}
		print("translationsDictionary 📕📕 ", translationsDictionary)
		return translationsDictionary
	}
	
	// ex ["de": ["ZudenEinstellungen":"Zu den Einstellungen"]]
	//	let translations: Dictionary<String, Dictionary<String, String>>
	
	// convenience variable for the class
	let fileManager = FileManager.default
	
	// the supported languages in the app
	let availableLocalisations = Bundle.main.localizations
	
	/// create my bundle if it does not exists - this would be done once
	func createLocalisedBundleDirectoryIfNeeded() throws  {
		if fileManager.fileExists(atPath: bundlePath.path) == false {
			do {
				try fileManager.createDirectory(at: bundlePath, withIntermediateDirectories: true, attributes: [FileAttributeKey.protectionKey : FileProtectionType.complete])
				print("created dir at ", bundlePath)
			} catch {
				print(error.localizedDescription)
			}
		}
	}
	
	
	public func writeDataToBundle() throws  {
		// I check and create my bundle if it does not exists
		do {
			try createLocalisedBundleDirectoryIfNeeded()
		} catch {
			print(error.localizedDescription)
		}
		
		// for every language localised in my app I create a corresponding folder in the bundle
		for localisation in availableLocalisations {
			let folderPath = bundlePath.appendingPathComponent("\(localisation).lproj", isDirectory: true)
			if fileManager.fileExists(atPath: folderPath.path) == false {
				do {
				try fileManager.createDirectory(at: folderPath, withIntermediateDirectories: true, attributes:  [FileAttributeKey.protectionKey : FileProtectionType.complete])
				} catch {
					print(#function, error.localizedDescription)
				}
			}
			print(folderPath.lastPathComponent," ---- > folder created ⭐️")
		}
		
		// create my strings files - reminder
		// translation is ex ["de": ["ZudenEinstellungen":"Zu den Einstellungen"]]
		// and for every de-DE or en-US there is a de and en folder
		for language in translations {
			let langKey = language.key //"de-DE"
			let langKeyShort = String(language.key.prefix(2)) //"de"
			// check that the language I get from web is supported! else return
			guard availableLocalisations.contains(langKey) || availableLocalisations.contains(langKeyShort)
			else { continue }
			
			// look for my folder.
			let langPath = bundlePath.appendingPathComponent("\(langKey).lproj", isDirectory: true)
			let langPathShort = bundlePath.appendingPathComponent("\(langKeyShort).lproj", isDirectory: true)
			let sentences = language.value
			let res = sentences.reduce("", { $0 + "\"\($1.key)\" = \"\($1.value)\";\n" })
			
			let filePath = langPath.appendingPathComponent("\(tableName).strings")
			let filePathShort = langPathShort.appendingPathComponent("\(tableName).strings")

			let data = res.data(using: .utf16)
			// this will put our strings file in both de-DE and de directories
			fileManager.createFile(atPath: filePath.path, contents: data, attributes: [FileAttributeKey.protectionKey : FileProtectionType.complete])
			// I will overwrite. so if we have en-US and then en-HK in the same entry the last will be the put in the en.proj folder - priority matters!
			// cant do differently otherwise if there is an update in languages the file will never be updated - better overwrite everytime. It will be seldom that both flavour of en will be present!
			fileManager.createFile(atPath: filePathShort.path, contents: data, attributes: [FileAttributeKey.protectionKey : FileProtectionType.complete])
		}
	}
	
	func clean() throws {
		// TODO: There can be multiple table names in the same Bundle. So only remove the bundle if there is no more string files.
		for _ in fileManager.enumerator(at: bundlePath, includingPropertiesForKeys: nil, options: [.skipsPackageDescendants])! {
			if fileManager.fileExists(atPath: bundlePath.path) {
				do {
				try fileManager.removeItem(at: bundlePath)
				} catch {
					print(#function," could not remove file! 💣💣💣")
				}
			}
		}
		
	}
}


// in the extension I have a bundle helper function
extension RMLocalizationManager {
	public func returnCurrentBundleFor(language: String) throws -> Bundle {
		// these lines just check if the app already has custom bundle already
		// if no custom bundle found it returns the local main bundle
		if manager.fileExists(atPath: bundlePath.path) == false {
			print(#line, "=== Not custom bundle found - using main bundle 🤚🏻🤚🏻🤚🏻 =========")
			return Bundle(path: getPathForLocalLanguage(language: language))!
		}
		// we are here if there is a custom bundle and we need to get the path to the proj folder so we will check if the language folder is in the custom bundle
		do {
			let resourceKeys : [URLResourceKey] = [.creationDateKey, .isDirectoryKey]
			_ = try manager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) // ?
			// get the enumerator to loop on the folders inside my bundle
			if let enumerator = FileManager.default.enumerator(
				at: bundlePath ,
				includingPropertiesForKeys: resourceKeys,
				options: [.skipsHiddenFiles], errorHandler: { (url, error) -> Bool in
					return true
												 }) {
				// with the enumerator I loop on the folders inside my bundle
				for case let folderURL as URL in enumerator {
					_ = try folderURL.resourceValues(forKeys: Set(resourceKeys))
					// if I get the folder for my selected language
					if folderURL.lastPathComponent == ("\(language).lproj"){
						// I create a second enumerator to loop on the strings files
						if let enumerator2 = FileManager.default.enumerator(
							at: folderURL,
							includingPropertiesForKeys: resourceKeys,
							options: [.skipsHiddenFiles],
							errorHandler: { (url, error) -> Bool in
								return true}) {
							for case let fileURL as URL in enumerator2 {
								_ = try fileURL.resourceValues(forKeys: Set(resourceKeys))
								// finally if I find a file matching language and table I create a new bundle with that url and return it
								if fileURL.lastPathComponent == tableName + ".strings" {
									return Bundle(url: folderURL)!
								}
							}
						}
					}
				}
			}
			// this catches any errors thrown by the file manager
		} catch {
			print(#line, "=== Not custom - getPathForLocalLanguage 🤚🏻🤚🏻🤚🏻 =========")
			return Bundle(path: getPathForLocalLanguage(language: language))!
		}
		// if there is no file matching language and table I return the main bundle
		print(#line, "=== Not custom - getPathForLocalLanguage 🤚🏻🤚🏻🤚🏻 =========")
		return Bundle(path: getPathForLocalLanguage(language: language))!
	}
	
	
	// in this case the custom bundle does not exist so we return our main bundle for the localisations
	private func getPathForLocalLanguage(language: String) -> String {
		// if our app is already localised we get this back
				if let mainBundle = Bundle.main.path(forResource: language, ofType: "lproj") {
					print(#line, "mainBundle")
					return mainBundle
				}
		// if our app had not been localised yet we return just the main bundle
		return Bundle.main.bundlePath
	}
}
