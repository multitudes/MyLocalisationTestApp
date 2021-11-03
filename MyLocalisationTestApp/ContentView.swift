//
//  ContentView.swift
//  MyLocalisationTestApp
//
//  Created by Laurent B on 02/11/2021.
//

import SwiftUI

struct ContentView: View {
	private var localisationManager = RMLocalizationManager.shared

	var myTitle: LocalizedStringKey = "Hello"
	var dynamicLocalisedText: LocalizedStringKey = "TitleKey"
    var body: some View {
		VStack {
			Text(myTitle) //This is localised in main bundle

			// I need the table name - otherwise it defaults to Localised!
			DynamicLocalisedText(key: dynamicLocalisedText)
				.font(.title)
				.padding()

			Button(action: {
				UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
			}, label: {

				Text("change")
					.foregroundColor(Color.primary)
					.padding()
					.background(
						RoundedRectangle(cornerRadius: 24)
							.fill(Color(UIColor.secondarySystemBackground))
					)
			})
			Button(action: {
				try? RMLocalizationManager.shared.clean()
			}, label: {
				Text("clean")
			})
		}
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
