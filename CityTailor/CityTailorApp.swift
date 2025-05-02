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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
