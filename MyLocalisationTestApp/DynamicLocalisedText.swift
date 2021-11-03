//
//  DynamicLocalisedText.swift
//  MyLocalisationTestApp
//
//  Created by Laurent B on 03/11/2021.
//

import SwiftUI


struct DynamicLocalisedText: View {
	var key: LocalizedStringKey
	var tableName = RMLocalizationManager.shared.tableName
	var bundle = RMLocalizationManager.shared.currentBundle

	var body: some View {
		Text(key, tableName: tableName, bundle: bundle)
	}
}


//struct DynamicLocalisedText_Previews: PreviewProvider {
//    static var previews: some View {
//        DynamicLocalisedText()
//    }
//}
