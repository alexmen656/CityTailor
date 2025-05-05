import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var storeManager: StoreManager
    @State private var showInterestsView = false
    @State private var notificationsEnabled = true
    @State private var darkModeEnabled = false
    @State private var language = "Deutsch"
    @State private var showPremiumView = false
    @State private var showAbout = false
    
    let languages = ["Deutsch", "English", "Français", "Español", "Italiano"]
    
    var body: some View {
        NavigationView {
            Form {
                // Premium section
                Section(header: Text("Premium")) {
                    Button(action: {
                        showPremiumView = true
                    }) {
                        HStack {
                            if storeManager.isPremium() {
                                Label("Premium aktiviert", systemImage: "checkmark.seal.fill")
                                    .foregroundColor(.green)
                            } else {
                                Label("Upgrade auf Premium", systemImage: "crown.fill")
                                    .foregroundColor(.yellow)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                // Karteneinstellungen
                Section(header: Text("Karteneinstellungen")) {
                    Toggle("Verkehr anzeigen", isOn: .constant(false))
                    Toggle("Points of Interest anzeigen", isOn: .constant(true))
                }
                
                // Erscheinungsbild
                Section(header: Text("Erscheinungsbild")) {
                    Picker("Kartenstil", selection: .constant(0)) {
                        Text("Standard").tag(0)
                        Text("Satellit").tag(1)
                        Text("Hybrid").tag(2)
                    }
                    
                    Toggle("Nachtmodus", isOn: .constant(false))
                }
                
                // Persönliche Einstellungen
                Section(header: Text("Persönliche Einstellungen")) {
                    Button(action: {
                        showInterestsView = true
                    }) {
                        HStack {
                            Text("Interessen")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                // Allgemeine Einstellungen
                Section(header: Text("Allgemein")) {
                    Toggle(isOn: $notificationsEnabled) {
                        Label("Benachrichtigungen", systemImage: "bell.fill")
                    }
                    
                    Toggle(isOn: $darkModeEnabled) {
                        Label("Dark Mode", systemImage: "moon.fill")
                    }
                    
                    Picker(selection: $language, label: Label("Sprache", systemImage: "globe")) {
                        ForEach(languages, id: \.self) {
                            Text($0)
                        }
                    }
                    
                    Toggle("Standort verwenden", isOn: .constant(true))
                    Toggle("Automatische Updates", isOn: .constant(true))
                }
                
                // App-Informationen
                Section(header: Text("App-Informationen")) {
                    Button(action: {
                        showAbout = true
                    }) {
                        Label("Über die App", systemImage: "info.circle")
                    }
                    
                    Link(destination: URL(string: "https://citytailor.com/privacy")!) {
                        Label("Datenschutzerklärung", systemImage: "lock.shield")
                    }
                    
                    Link(destination: URL(string: "https://citytailor.com/terms")!) {
                        Label("Nutzungsbedingungen", systemImage: "doc.text")
                    }
                }
                
                // Version information
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                }
                
                Section {
                    Button(action: {
                        // Hier könnte ein Reset aller Einstellungen erfolgen
                    }) {
                        Text("Auf Standardwerte zurücksetzen")
                            .foregroundColor(.red)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Einstellungen")
            .navigationBarItems(trailing: Button("Fertig") {
                presentationMode.wrappedValue.dismiss()
            })
            .sheet(isPresented: $showInterestsView) {
                InterestsView()
            }
            .sheet(isPresented: $showPremiumView) {
                PremiumView()
                    .environmentObject(storeManager)
            }
            .alert(isPresented: $showAbout) {
                Alert(
                    title: Text("CityTailor"),
                    message: Text("Eine KI-gestützte App zum Erstellen personalisierter Reisepläne.\n\n© 2025 CityTailor GmbH"),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(StoreManager())
}