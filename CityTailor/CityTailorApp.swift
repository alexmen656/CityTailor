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
    @StateObject private var appSettings = AppSettings()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(storeManager)
                .environmentObject(appSettings)
        }
    }
}
