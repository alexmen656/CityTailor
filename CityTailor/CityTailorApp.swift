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
        print("DEBUG: Synchronizing language settings on app start")
        
        if UserDefaults.standard.string(forKey: "language") == nil {
            print("DEBUG: No language in AppSettings, using LanguageManager's language: \(languageManager.currentLanguage.rawValue)")
            appSettings.language = languageManager.currentLanguage.rawValue
        } 
        else {
            print("DEBUG: Using saved language from AppSettings: \(appSettings.language)")
            languageManager.setLanguage(LanguageManager.LanguageCode.from(displayName: appSettings.language))
        }
    }
}
