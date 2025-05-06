import Foundation
import SwiftUI
import Combine

class LanguageManager: ObservableObject {
    enum LanguageCode: String {
        case de = "Deutsch"
        case en = "English"
        case fr = "Français" 
        case es = "Español"
        case it = "Italiano"
        
        var code: String {
            switch self {
            case .de: return "de"
            case .en: return "en"
            case .fr: return "fr"
            case .es: return "es"
            case .it: return "it"
            }
        }
        
        static var allCases: [LanguageCode] {
            return [.de, .en, .fr, .es, .it]
        }
        
        static func from(displayName: String) -> LanguageCode {
            return LanguageCode.allCases.first { $0.rawValue == displayName } ?? .en
        }
        
        static func fromSystemLanguage() -> LanguageCode {
            let preferredLanguages = Locale.preferredLanguages
            let preferredLanguage = preferredLanguages.first?.prefix(2).lowercased() ?? "en"
            
            print("DEBUG: System preferred languages: \(preferredLanguages)")
            print("DEBUG: Using language code: \(preferredLanguage)")
            
            switch preferredLanguage {
            case "de":
                print("DEBUG: Selected German")
                return .de
            case "en":
                print("DEBUG: Selected English")
                return .en
            case "fr":
                print("DEBUG: Selected French")
                return .fr
            case "es":
                print("DEBUG: Selected Spanish")
                return .es
            case "it":
                print("DEBUG: Selected Italian")
                return .it
            default:
                print("DEBUG: No match, fallback to English")
                return .en
            }
        }
    }
    
    @Published var currentLanguage: LanguageCode {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "app_language")
            print("DEBUG: Language changed to: \(currentLanguage.rawValue)")
            loadTranslations()
        }
    }
    
    @Published var translations: [String: String] = [:]
    
    init() {
        print("DEBUG: LanguageManager init")
        print("DEBUG: UserDefaults app_language: \(UserDefaults.standard.string(forKey: "app_language") ?? "nil")")
        
        if let savedLanguage = UserDefaults.standard.string(forKey: "app_language") {
            print("DEBUG: Using saved language: \(savedLanguage)")
            self.currentLanguage = LanguageCode.from(displayName: savedLanguage)
        } else {
            self.currentLanguage = LanguageCode.fromSystemLanguage()
            print("DEBUG: Using system language, saving as: \(currentLanguage.rawValue)")
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "app_language")
        }
        
        loadTranslations()
    }
    
    private func loadTranslations() {
        print("DEBUG: Loading translations for: \(currentLanguage.rawValue)")
        self.translations = getTranslationsFor(language: currentLanguage)
    }
    
    func localize(_ key: String) -> String {
        return translations[key] ?? key
    }
    
    func setLanguage(_ language: LanguageCode) {
        print("DEBUG: Setting language to: \(language.rawValue)")
        currentLanguage = language
    }
    
    private func getTranslationsFor(language: LanguageCode) -> [String: String] {
        switch language {
        case .de:
            return [
                "map": "Karte",
                "plans": "Pläne",
                "favorites": "Favoriten",
                "settings": "Einstellungen",
                "search": "Suchen",
                "day": "Tag",
                "premium": "Premium",
                "upgrade_to_premium": "Upgrade auf Premium",
                "premium_activated": "Premium aktiviert",
                "map_settings": "Karteneinstellungen",
                "show_traffic": "Verkehr anzeigen",
                "show_pois": "Points of Interest anzeigen",
                "appearance": "Erscheinungsbild",
                "map_style": "Kartenstil",
                "standard": "Standard",
                "satellite": "Satellit",
                "night_mode": "Nachtmodus",
                "personal_settings": "Persönliche Einstellungen",
                "interests": "Interessen",
                "general": "Allgemein",
                "notifications": "Benachrichtigungen",
                "dark_mode": "Dark Mode",
                "language": "Sprache",
                "use_location": "Standort verwenden",
                "auto_updates": "Automatische Updates",
                "app_info": "App-Informationen",
                "about": "Über die App",
                "privacy_policy": "Datenschutzerklärung",
                "terms": "Nutzungsbedingungen",
                "version": "Version",
                "reset_defaults": "Auf Standardwerte zurücksetzen",
                "done": "Fertig",
                "travel_plan_for": "Reiseplan für",
                
                // Premium View
                "citytailor_premium": "CityTailor Premium",
                "experience_best": "Erleben Sie das Beste von CityTailor",
                "no_subscriptions": "Keine Abonnements verfügbar",
                "buy_subscription": "Abonnement kaufen",
                "restore_purchases": "Käufe wiederherstellen",
                "purchase_through_apple": "Der Kauf wird über Ihren Apple Account abgewickelt.",
                "auto_renewal": "Ihr Abonnement verlängert sich automatisch, bis es gekündigt wird.",
                "close": "Schließen",
                "information": "Information",
                "thank_you": "Vielen Dank für den Kauf! Sie haben jetzt Zugang zu allen Premium-Funktionen.",
                "purchases_restored": "Ihre Käufe wurden wiederhergestellt.",
                "no_purchases": "Keine Käufe zum Wiederherstellen gefunden.",
                
                // Premium Features
                "unlimited_plans": "Unbegrenzte Reisepläne",
                "custom_plans": "Benutzerdefinierte Reisepläne",
                "enhanced_ai": "Verbesserte KI-Vorschläge",
                "offline_access": "Offline-Zugriff",
                "no_ads": "Keine Werbung",
                
                // Subscription
                "monthly_subscription": "Monatliches Premium-Abonnement",
                "yearly_subscription": "Jährliches Premium-Abonnement (Spare 20%)",
                "per_month": "pro Monat",
                "per_year": "pro Jahr",
                
                // Additional Translation
                "search_city": "Stadt suchen..."
            ]
        case .en:
            return [
                "map": "Map",
                "plans": "Plans",
                "favorites": "Favorites",
                "settings": "Settings",
                "search": "Search",
                "day": "Day",
                "premium": "Premium",
                "upgrade_to_premium": "Upgrade to Premium",
                "premium_activated": "Premium Activated",
                "map_settings": "Map Settings",
                "show_traffic": "Show Traffic",
                "show_pois": "Show Points of Interest",
                "appearance": "Appearance",
                "map_style": "Map Style",
                "standard": "Standard",
                "satellite": "Satellite",
                "night_mode": "Night Mode",
                "personal_settings": "Personal Settings",
                "interests": "Interests",
                "general": "General",
                "notifications": "Notifications",
                "dark_mode": "Dark Mode",
                "language": "Language",
                "use_location": "Use Location",
                "auto_updates": "Automatic Updates",
                "app_info": "App Information",
                "about": "About",
                "privacy_policy": "Privacy Policy",
                "terms": "Terms of Use",
                "version": "Version",
                "reset_defaults": "Reset to Defaults",
                "done": "Done",
                "travel_plan_for": "Travel Plan for",
                
                // Premium View
                "citytailor_premium": "CityTailor Premium",
                "experience_best": "Experience the best of CityTailor",
                "no_subscriptions": "No subscriptions available",
                "buy_subscription": "Purchase Subscription",
                "restore_purchases": "Restore Purchases",
                "purchase_through_apple": "Purchases will be charged to your Apple account.",
                "auto_renewal": "Your subscription will automatically renew until cancelled.",
                "close": "Close",
                "information": "Information",
                "thank_you": "Thank you for your purchase! You now have access to all premium features.",
                "purchases_restored": "Your purchases have been restored.",
                "no_purchases": "No purchases found to restore.",
                
                // Premium Features
                "unlimited_plans": "Unlimited Travel Plans",
                "custom_plans": "Custom Travel Plans",
                "enhanced_ai": "Enhanced AI Suggestions",
                "offline_access": "Offline Access",
                "no_ads": "No Advertisements",
                
                // Subscription
                "monthly_subscription": "Monthly Premium Subscription",
                "yearly_subscription": "Yearly Premium Subscription (Save 20%)",
                "per_month": "per month",
                "per_year": "per year",
                
                // Additional Translation
                "search_city": "Search city..."
            ]
        case .fr:
            return [
                "map": "Carte",
                "plans": "Plans",
                "favorites": "Favoris",
                "settings": "Paramètres",
                "search": "Rechercher",
                "day": "Jour",
                "premium": "Premium",
                "upgrade_to_premium": "Passer à Premium",
                "premium_activated": "Premium Activé",
                "map_settings": "Paramètres de la Carte",
                "show_traffic": "Afficher le Trafic",
                "show_pois": "Afficher les Points d'Intérêt",
                "appearance": "Apparence",
                "map_style": "Style de Carte",
                "standard": "Standard",
                "satellite": "Satellite",
                "night_mode": "Mode Nuit",
                "personal_settings": "Paramètres Personnels",
                "interests": "Intérêts",
                "general": "Général",
                "notifications": "Notifications",
                "dark_mode": "Mode Sombre",
                "language": "Langue",
                "use_location": "Utiliser la Localisation",
                "auto_updates": "Mises à Jour Automatiques",
                "app_info": "Informations de l'App",
                "about": "À Propos",
                "privacy_policy": "Politique de Confidentialité",
                "terms": "Conditions d'Utilisation",
                "version": "Version",
                "reset_defaults": "Réinitialiser les Paramètres",
                "done": "Terminé",
                "travel_plan_for": "Plan de Voyage pour",
                
                // Premium View
                "citytailor_premium": "CityTailor Premium",
                "experience_best": "Découvrez le meilleur de CityTailor",
                "no_subscriptions": "Aucun abonnement disponible",
                "buy_subscription": "Acheter l'abonnement",
                "restore_purchases": "Restaurer les achats",
                "purchase_through_apple": "Les achats seront facturés sur votre compte Apple.",
                "auto_renewal": "Votre abonnement se renouvelle automatiquement jusqu'à annulation.",
                "close": "Fermer",
                "information": "Information",
                "thank_you": "Merci pour votre achat ! Vous avez maintenant accès à toutes les fonctionnalités premium.",
                "purchases_restored": "Vos achats ont été restaurés.",
                "no_purchases": "Aucun achat à restaurer trouvé.",
                
                // Premium Features
                "unlimited_plans": "Plans de voyage illimités",
                "custom_plans": "Plans de voyage personnalisés",
                "enhanced_ai": "Suggestions IA améliorées",
                "offline_access": "Accès hors ligne",
                "no_ads": "Sans publicités",
                
                // Subscription
                "monthly_subscription": "Abonnement Premium mensuel",
                "yearly_subscription": "Abonnement Premium annuel (Économisez 20%)",
                "per_month": "par mois",
                "per_year": "par an",
                
                // Additional Translation
                "search_city": "Rechercher une ville..."
            ]
        case .es:
            return [
                "map": "Mapa",
                "plans": "Planes",
                "favorites": "Favoritos",
                "settings": "Ajustes",
                "search": "Buscar",
                "day": "Día",
                "premium": "Premium",
                "upgrade_to_premium": "Actualizar a Premium",
                "premium_activated": "Premium Activado",
                "map_settings": "Ajustes del Mapa",
                "show_traffic": "Mostrar Tráfico",
                "show_pois": "Mostrar Puntos de Interés",
                "appearance": "Apariencia",
                "map_style": "Estilo de Mapa",
                "standard": "Estándar",
                "satellite": "Satélite",
                "night_mode": "Modo Nocturno",
                "personal_settings": "Ajustes Personales",
                "interests": "Intereses",
                "general": "General",
                "notifications": "Notificaciones",
                "dark_mode": "Modo Oscuro",
                "language": "Idioma",
                "use_location": "Usar Ubicación",
                "auto_updates": "Actualizaciones Automáticas",
                "app_info": "Información de la App",
                "about": "Acerca de",
                "privacy_policy": "Política de Privacidad",
                "terms": "Términos de Uso",
                "version": "Versión",
                "reset_defaults": "Restablecer Valores Predeterminados",
                "done": "Hecho",
                "travel_plan_for": "Plan de Viaje para",
                
                // Premium View
                "citytailor_premium": "CityTailor Premium",
                "experience_best": "Experimente lo mejor de CityTailor",
                "no_subscriptions": "No hay suscripciones disponibles",
                "buy_subscription": "Comprar suscripción",
                "restore_purchases": "Restaurar compras",
                "purchase_through_apple": "Las compras se cargarán a tu cuenta de Apple.",
                "auto_renewal": "Tu suscripción se renovará automáticamente hasta que la canceles.",
                "close": "Cerrar",
                "information": "Información",
                "thank_you": "¡Gracias por tu compra! Ahora tienes acceso a todas las funciones premium.",
                "purchases_restored": "Tus compras han sido restauradas.",
                "no_purchases": "No se encontraron compras para restaurar.",
                
                // Premium Features
                "unlimited_plans": "Planes de viaje ilimitados",
                "custom_plans": "Planes de viaje personalizados",
                "enhanced_ai": "Sugerencias mejoradas de IA",
                "offline_access": "Acceso sin conexión",
                "no_ads": "Sin publicidad",
                
                // Subscription
                "monthly_subscription": "Suscripción Premium mensual",
                "yearly_subscription": "Suscripción Premium anual (Ahorre 20%)",
                "per_month": "por mes",
                "per_year": "por año",
                
                // Additional Translation
                "search_city": "Buscar ciudad..."
            ]
        case .it:
            return [
                "map": "Mappa",
                "plans": "Piani",
                "favorites": "Preferiti",
                "settings": "Impostazioni",
                "search": "Cerca",
                "day": "Giorno",
                "premium": "Premium",
                "upgrade_to_premium": "Aggiorna a Premium",
                "premium_activated": "Premium Attivato",
                "map_settings": "Impostazioni Mappa",
                "show_traffic": "Mostra Traffico",
                "show_pois": "Mostra Punti di Interesse",
                "appearance": "Aspetto",
                "map_style": "Stile Mappa",
                "standard": "Standard",
                "satellite": "Satellite",
                "night_mode": "Modalità Notte",
                "personal_settings": "Impostazioni Personali",
                "interests": "Interessi",
                "general": "Generale",
                "notifications": "Notifiche",
                "dark_mode": "Modalità Scura",
                "language": "Lingua",
                "use_location": "Usa Posizione",
                "auto_updates": "Aggiornamenti Automatici",
                "app_info": "Informazioni App",
                "about": "Informazioni",
                "privacy_policy": "Informativa sulla Privacy",
                "terms": "Termini d'Uso",
                "version": "Versione",
                "reset_defaults": "Ripristina Impostazioni",
                "done": "Fine",
                "travel_plan_for": "Piano di Viaggio per",
                
                // Premium View
                "citytailor_premium": "CityTailor Premium",
                "experience_best": "Scopri il meglio di CityTailor",
                "no_subscriptions": "Nessun abbonamento disponibile",
                "buy_subscription": "Acquista abbonamento",
                "restore_purchases": "Ripristina acquisti",
                "purchase_through_apple": "Gli acquisti verranno addebitati sul tuo account Apple.",
                "auto_renewal": "Il tuo abbonamento si rinnoverà automaticamente fino alla cancellazione.",
                "close": "Chiudi",
                "information": "Informazione",
                "thank_you": "Grazie per il tuo acquisto! Ora hai accesso a tutte le funzionalità premium.",
                "purchases_restored": "I tuoi acquisti sono stati ripristinati.",
                "no_purchases": "Nessun acquisto trovato da ripristinare.",
                
                // Premium Features
                "unlimited_plans": "Piani di viaggio illimitati",
                "custom_plans": "Piani di viaggio personalizzati",
                "enhanced_ai": "Suggerimenti AI migliorati",
                "offline_access": "Accesso offline",
                "no_ads": "Nessuna pubblicità",
                
                // Subscription
                "monthly_subscription": "Abbonamento Premium mensile",
                "yearly_subscription": "Abbonamento Premium annuale (Risparmia 20%)",
                "per_month": "al mese",
                "per_year": "all'anno",
                
                // Additional Translation
                "search_city": "Cerca città..."
            ]
        }
    }
}

extension View {
    func localizedText(_ key: String) -> some View {
        ViewThatAppliesLanguage(key: key) {
            self
        }
    }
}

struct ViewThatAppliesLanguage<Content: View>: View {
    @EnvironmentObject var languageManager: LanguageManager
    let key: String
    let content: Content
    
    init(key: String, @ViewBuilder content: () -> Content) {
        self.key = key
        self.content = content()
    }
    
    var body: some View {
        content
            .overlay(Text(languageManager.localize(key)).opacity(0))
    }
}

extension Text {
    static func localized(_ key: String) -> Text {
        return Text(LocalizedStringKey(key))
    }
}