//
//  CityTailorApp.swift
//  CityTailor
//
//  Created by Alex Polan on 5/2/25.
//

import SwiftUI

@main
struct CityTailorApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var storeManager = StoreManager()
    @StateObject private var languageManager = LanguageManager()
    @StateObject private var appSettings = AppSettings()
    @State private var isFirstLaunch = !UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
    
    init() {
        TravelPlanStore.shared.updateWidgetData(context: persistenceController.container.viewContext)
    }

    var body: some Scene {
        WindowGroup {
            if isFirstLaunch {
                OnboardingView(isFirstLaunch: $isFirstLaunch)
                    .environmentObject(languageManager)
                    .environmentObject(appSettings)
            } else {
                ContentView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .environmentObject(storeManager)
                    .environmentObject(languageManager)
                    .environmentObject(appSettings)
                    .onAppear {
                        synchronizeLanguageSettings()
                    }
            }
        }
    }
    
    private func synchronizeLanguageSettings() {        
        if UserDefaults.standard.string(forKey: "language") == nil {
            appSettings.language = languageManager.currentLanguage.rawValue
        } 
        else {
            languageManager.setLanguage(LanguageManager.LanguageCode.from(displayName: appSettings.language))
        }
    }
}
