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
        language = "English"
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
    @EnvironmentObject private var languageManager: LanguageManager
    
    @State private var showInterestsView = false
    @State private var showPremiumView = false
    @State private var showAbout = false
    
    // Parameter zur Unterscheidung zwischen Modal und Tab
    var isModal: Bool = false
    
    var body: some View {
        NavigationView {
            Form {
                // Premium section
               /* Section(header: Text(languageManager.localize("premium"))) {*/
                    Button(action: {
                        showPremiumView = true
                    }) {
                        HStack {
                            if storeManager.isPremium() {
                                Label(languageManager.localize("premium_activated"), systemImage: "checkmark.seal.fill")
                                    .foregroundColor(.green)
                            } else {
                                Label(languageManager.localize("upgrade_to_premium"), systemImage: "crown.fill")
                                    .foregroundColor(.yellow)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
               /* }*/
                
                // Karteneinstellungen
                Section(header: Text(languageManager.localize("map_settings"))) {
                    Toggle(languageManager.localize("show_traffic"), isOn: $settings.showTraffic)
                    Toggle(languageManager.localize("show_pois"), isOn: $settings.showPOIs)
                }
                
                // Erscheinungsbild
                Section(header: Text(languageManager.localize("appearance"))) {
                    Picker(languageManager.localize("map_style"), selection: $settings.mapStyle) {
                        ForEach(AppSettings.MapStyle.allCases, id: \.rawValue) { style in
                            Text(languageManager.localize(style == .standard ? "standard" : "satellite")).tag(style.rawValue)
                        }
                    }
                    
                    Toggle(languageManager.localize("night_mode"), isOn: $settings.nightMode)
                }
                
                // Persönliche Einstellungen
                Section(header: Text(languageManager.localize("personal_settings"))) {
                    Button(action: {
                        showInterestsView = true
                    }) {
                        HStack {
                            Text(languageManager.localize("interests"))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                // Allgemeine Einstellungen
                Section(header: Text(languageManager.localize("general"))) {
                                        // Comming in v2
/*
                    Toggle(isOn: $settings.notificationsEnabled) {
                        Label(languageManager.localize("notifications"), systemImage: "bell.fill")
                    }
                    
                    Toggle(isOn: $settings.darkModeEnabled) {
                        Label(languageManager.localize("dark_mode"), systemImage: "moon.fill")
                    }
                    */
                    
                    Picker(selection: $settings.language, label: Label(languageManager.localize("language"), systemImage: "globe")) {
                        ForEach(LanguageManager.LanguageCode.allCases, id: \.rawValue) { language in
                            Text(language.rawValue).tag(language.rawValue)
                        }
                    }
                    .onChange(of: settings.language) { newLanguage in
                        print("DEBUG: Language changed to \(newLanguage) in settings")
                        languageManager.setLanguage(LanguageManager.LanguageCode.from(displayName: newLanguage))
                    }
                    
                    // Comming in v2
                  /*  Toggle(languageManager.localize("use_location"), isOn: $settings.useLocation)
                    Toggle(languageManager.localize("auto_updates"), isOn: $settings.autoUpdates) */
                }
                
                // App-Informationen
                Section(header: Text(languageManager.localize("app_info"))) {
                    Button(action: {
                        showAbout = true
                    }) {
                        Label(languageManager.localize("about"), systemImage: "info.circle")
                    }
                    
                    Link(destination: URL(string: "https://alex.polan.sk/privacy-policy.html")!) {
                        Label(languageManager.localize("privacy_policy"), systemImage: "lock.shield")
                    }
                    
                    Link(destination: URL(string: "https://alex.polan.sk/terms-of-use.html")!) {
                        Label(languageManager.localize("terms"), systemImage: "doc.text")
                    }
                }
                
                // Version information
                Section {
                    HStack {
                        Text(languageManager.localize("version"))
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                }
                
                Section {
                    Button(action: {
                        settings.resetToDefaults()
                        languageManager.setLanguage(.en)
                    }) {
                        Text(languageManager.localize("reset_defaults"))
                            .foregroundColor(.red)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle(languageManager.localize("settings"))
            .navigationBarItems(trailing: isModal ? Button(languageManager.localize("done")) {
                presentationMode.wrappedValue.dismiss()
            } : nil)
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
                    message: Text(languageManager.localize("about_message")),
                    dismissButton: .default(Text(languageManager.localize("done")))
                )
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(StoreManager())
        .environmentObject(AppSettings())
        .environmentObject(LanguageManager())
}