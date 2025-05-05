import SwiftUI

class AppSettings: ObservableObject {
    private enum Keys {
        static let showTraffic = "showTraffic"
        static let showPOIs = "showPOIs"
        static let mapStyle = "mapStyle"
        static let nightMode = "nightMode"
        static let notifications = "notifications"
        static let darkMode = "darkMode"
        static let language = "language"
        static let useLocation = "useLocation"
        static let autoUpdates = "autoUpdates"
    }
    
    enum MapStyle: Int, CaseIterable {
        case standard = 0
        case satellite = 2
        
        var name: String {
            switch self {
            case .standard: return "Standard"
            case .satellite: return "Satellit"
            }
        }
    }
    
    @Published var showTraffic: Bool {
        didSet { UserDefaults.standard.set(showTraffic, forKey: Keys.showTraffic) }
    }
    
    @Published var showPOIs: Bool {
        didSet { UserDefaults.standard.set(showPOIs, forKey: Keys.showPOIs) }
    }
    
    @Published var mapStyle: Int {
        didSet { UserDefaults.standard.set(mapStyle, forKey: Keys.mapStyle) }
    }
    
    @Published var nightMode: Bool {
        didSet { UserDefaults.standard.set(nightMode, forKey: Keys.nightMode) }
    }
    
    @Published var notificationsEnabled: Bool {
        didSet { UserDefaults.standard.set(notificationsEnabled, forKey: Keys.notifications) }
    }
    
    @Published var darkModeEnabled: Bool {
        didSet { UserDefaults.standard.set(darkModeEnabled, forKey: Keys.darkMode) }
    }
    
    @Published var language: String {
        didSet { UserDefaults.standard.set(language, forKey: Keys.language) }
    }
    
    @Published var useLocation: Bool {
        didSet { UserDefaults.standard.set(useLocation, forKey: Keys.useLocation) }
    }
    
    @Published var autoUpdates: Bool {
        didSet { UserDefaults.standard.set(autoUpdates, forKey: Keys.autoUpdates) }
    }
    
    let languages = ["Deutsch", "English", "Français", "Español", "Italiano"]
    
    init() {
        self.showTraffic = UserDefaults.standard.bool(forKey: Keys.showTraffic)
        self.showPOIs = UserDefaults.standard.bool(forKey: Keys.showPOIs, defaultValue: true)
        self.mapStyle = UserDefaults.standard.integer(forKey: Keys.mapStyle)
        self.nightMode = UserDefaults.standard.bool(forKey: Keys.nightMode)
        self.notificationsEnabled = UserDefaults.standard.bool(forKey: Keys.notifications, defaultValue: true)
        self.darkModeEnabled = UserDefaults.standard.bool(forKey: Keys.darkMode)
        self.language = UserDefaults.standard.string(forKey: Keys.language) ?? "Deutsch"
        self.useLocation = UserDefaults.standard.bool(forKey: Keys.useLocation, defaultValue: true)
        self.autoUpdates = UserDefaults.standard.bool(forKey: Keys.autoUpdates, defaultValue: true)
    }
    
    func resetToDefaults() {
        showTraffic = false
        showPOIs = true
        mapStyle = 0
        nightMode = false
        notificationsEnabled = true
        darkModeEnabled = false
        language = "Deutsch"
        useLocation = true
        autoUpdates = true
    }
}

extension UserDefaults {
    func bool(forKey key: String, defaultValue: Bool = false) -> Bool {
        return object(forKey: key) as? Bool ?? defaultValue
    }
}

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var storeManager: StoreManager
    @EnvironmentObject private var settings: AppSettings
    
    @State private var showInterestsView = false
    @State private var showPremiumView = false
    @State private var showAbout = false
    
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
                    Toggle("Verkehr anzeigen", isOn: $settings.showTraffic)
                    Toggle("Points of Interest anzeigen", isOn: $settings.showPOIs)
                }
                
                // Erscheinungsbild
                Section(header: Text("Erscheinungsbild")) {
                    Picker("Kartenstil", selection: $settings.mapStyle) {
                        ForEach(AppSettings.MapStyle.allCases, id: \.rawValue) { style in
                            Text(style.name).tag(style.rawValue)
                        }
                    }
                    
                    Toggle("Nachtmodus", isOn: $settings.nightMode)
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
                    Toggle(isOn: $settings.notificationsEnabled) {
                        Label("Benachrichtigungen", systemImage: "bell.fill")
                    }
                    
                    Toggle(isOn: $settings.darkModeEnabled) {
                        Label("Dark Mode", systemImage: "moon.fill")
                    }
                    
                    Picker(selection: $settings.language, label: Label("Sprache", systemImage: "globe")) {
                        ForEach(settings.languages, id: \.self) {
                            Text($0)
                        }
                    }
                    
                    Toggle("Standort verwenden", isOn: $settings.useLocation)
                    Toggle("Automatische Updates", isOn: $settings.autoUpdates)
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
                        settings.resetToDefaults()
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
        .environmentObject(AppSettings())
}