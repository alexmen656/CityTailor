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
                "date_format": "Datumsformat",
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
                "unlimited_plans": "Unbegrenzte Reisepläne",
                "custom_plans": "Benutzerdefinierte Reisepläne",
                "enhanced_ai": "Verbesserte KI-Vorschläge",
                "offline_access": "Offline-Zugriff",
                "no_ads": "Keine Werbung",
                "monthly_subscription": "Monatliches Premium-Abonnement",
                "yearly_subscription": "Jährliches Premium-Abonnement (Spare 20%)",
                "per_month": "pro Monat",
                "per_year": "pro Jahr",
                "search_city": "Stadt suchen...",
                "about_message": "Eine KI-gestützte App zum Erstellen personalisierter Reisepläne.\n\n© 2025 Alex Polan",
                "destination": "Reiseziel",
                "location": "Ort",
                "travel_period": "Reisezeitraum",
                "arrival_date": "Anreisedatum",
                "departure_date": "Abreisedatum",
                "duration": "Aufenthaltsdauer",
                "days": "Tage",
                "day_singular": "Tag",
                "generate_plan": "Reiseplan erstellen",
                "free_account": "Kostenloses Konto",
                "remaining_free_plans": "Verbleibende kostenlose Pläne",
                "of": "von",
                "limit_reached": "Limit erreicht",
                "limit_reached_message": "Sie haben das Maximum von {0} Reiseplänen für die kostenlose Version erreicht. Upgrade auf Premium für unbegrenzte Reisepläne.",
                "cancel": "Abbrechen",
                "ok": "OK",
                "preparing_generation": "Bereite die Generierung vor...",
                "generating_day": "Generiere Tag {0} von {1}...",
                "finalizing_plan": "Finalisiere Reiseplan...",
                "backend_notification": "Backend-Benachrichtigung",
                "invalid_url": "Ungültige URL",
                "server_error": "Server-Fehler: Status {0}",
                "invalid_server_response": "Ungültige Serverantwort",
                "data_processing_error": "Fehler beim Verarbeiten der Daten: {0}",
                "json_error": "Fehler beim Erstellen der JSON-Daten: {0}",
                "travel_plan_saved": "Reiseplan gespeichert",
                "travel_plan_saved_message": "Ihr Reiseplan wurde erfolgreich gespeichert.",
                "no_plans_saved": "Noch keine Reisepläne gespeichert",
                "plans_appear_here": "Ihre gespeicherten Reisepläne erscheinen hier",
                "my_travel_plans": "Meine Reisepläne",
                "photo": "Foto",
                "activity": "Aktivität",
                "recommendations": "Empfehlungen für diesen Tag",
                "food_drinks": "Essen & Trinken",
                "transport": "Transport",
                "useful_tips": "Nützliche Tipps",
                "no_activities_found": "Keine Aktivitäten für diesen Tag gefunden",
                "no_plan_data": "Keine Reiseplan-Daten verfügbar",
                "art": "Kunst",
                "history": "Geschichte",
                "architecture": "Architektur",
                "gastronomy": "Gastronomie",
                "shopping": "Shopping",
                "nightlife": "Nachtleben",
                "culture": "Kultur",
                "sightseeing": "Sightseeing",
                "plan_load_error": "Reiseplan konnte nicht geladen werden",
                "back": "Zurück",
                
                // Onboarding
                "welcome_to_citytailor": "Willkommen bei CityTailor",
                "personalize_travel_plans": "Personalisieren Sie Ihre Reisepläne, indem Sie uns mitteilen, woran Sie interessiert sind",
                "set_interests": "Interessen festlegen",
                "skip": "Überspringen",
                
                // Premium Feature
                "support_future_development": "Unterstütze zukünftige Entwicklung"
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
                "date_format": "Date Format",
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
                "unlimited_plans": "Unlimited Travel Plans",
                "custom_plans": "Custom Travel Plans",
                "enhanced_ai": "Enhanced AI Suggestions",
                "offline_access": "Offline Access",
                "no_ads": "No Advertisements",
                "monthly_subscription": "Monthly Premium Subscription",
                "yearly_subscription": "Yearly Premium Subscription (Save 20%)",
                "per_month": "per month",
                "per_year": "per year",
                "search_city": "Search city...",
                "about_message": "An AI-powered app for creating personalized travel plans.\n\n© 2025 Alex Polan",
                "destination": "Destination",
                "location": "Location",
                "travel_period": "Travel Period",
                "arrival_date": "Arrival Date",
                "departure_date": "Departure Date",
                "duration": "Duration",
                "days": "Days",
                "day_singular": "Day",
                "generate_plan": "Generate Travel Plan",
                "free_account": "Free Account",
                "remaining_free_plans": "Remaining Free Plans",
                "of": "of",
                "limit_reached": "Limit Reached",
                "limit_reached_message": "You have reached the maximum of {0} travel plans for the free version. Upgrade to Premium for unlimited plans.",
                "cancel": "Cancel",
                "ok": "OK",
                "preparing_generation": "Preparing generation...",
                "generating_day": "Generating day {0} of {1}...",
                "finalizing_plan": "Finalizing travel plan...",
                "backend_notification": "Backend Notification",
                "invalid_url": "Invalid URL",
                "server_error": "Server error: Status {0}",
                "invalid_server_response": "Invalid server response",
                "data_processing_error": "Error processing data: {0}",
                "json_error": "Error creating JSON data: {0}",
                "travel_plan_saved": "Travel Plan Saved",
                "travel_plan_saved_message": "Your travel plan has been successfully saved.",
                "no_plans_saved": "No travel plans saved yet",
                "plans_appear_here": "Your saved travel plans will appear here",
                "my_travel_plans": "My Travel Plans",
                "photo": "Photo",
                "activity": "Activity",
                "recommendations": "Recommendations for This Day",
                "food_drinks": "Food & Drinks",
                "transport": "Transport",
                "useful_tips": "Useful Tips",
                "no_activities_found": "No activities found for this day",
                "no_plan_data": "No travel plan data available",
                "art": "Art",
                "history": "History",
                "architecture": "Architecture",
                "gastronomy": "Gastronomy",
                "shopping": "Shopping",
                "nightlife": "Nightlife",
                "culture": "Culture",
                "sightseeing": "Sightseeing",
                "plan_load_error": "Travel plan could not be loaded",
                "back": "Back",
                
                // Onboarding
                "welcome_to_citytailor": "Welcome to CityTailor",
                "personalize_travel_plans": "Personalize your travel plans by telling us what you're interested in",
                "set_interests": "Set Interests",
                "skip": "Skip",
                
                // Premium Feature
                "support_future_development": "Support future development"
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
                "date_format": "Format de Date",
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
                "unlimited_plans": "Plans de voyage illimités",
                "custom_plans": "Plans de voyage personnalisés",
                "enhanced_ai": "Suggestions IA améliorées",
                "offline_access": "Accès hors ligne",
                "no_ads": "Sans publicités",
                "monthly_subscription": "Abonnement Premium mensuel",
                "yearly_subscription": "Abonnement Premium annuel (Économisez 20%)",
                "per_month": "par mois",
                "per_year": "par an",
                "search_city": "Rechercher une ville...",
                "about_message": "Une application basée sur l'IA pour créer des plans de voyage personnalisés.\n\n© 2025 Alex Polan",
                "destination": "Destination",
                "location": "Lieu",
                "travel_period": "Période de Voyage",
                "arrival_date": "Date d'Arrivée",
                "departure_date": "Date de Départ",
                "duration": "Durée",
                "days": "Jours",
                "day_singular": "Jour",
                "generate_plan": "Générer un Plan de Voyage",
                "free_account": "Compte Gratuit",
                "remaining_free_plans": "Plans Gratuits Restants",
                "of": "sur",
                "limit_reached": "Limite Atteinte",
                "limit_reached_message": "Vous avez atteint le maximum de {0} plans de voyage pour la version gratuite. Passez à Premium pour des plans illimités.",
                "cancel": "Annuler",
                "ok": "OK",
                "preparing_generation": "Préparation de la génération...",
                "generating_day": "Génération du jour {0} sur {1}...",
                "finalizing_plan": "Finalisation du plan de voyage...",
                "backend_notification": "Notification du Backend",
                "invalid_url": "URL Invalide",
                "server_error": "Erreur du serveur : Statut {0}",
                "invalid_server_response": "Réponse du serveur invalide",
                "data_processing_error": "Erreur lors du traitement des données : {0}",
                "json_error": "Erreur lors de la création des données JSON : {0}",
                "travel_plan_saved": "Plan de Voyage Enregistré",
                "travel_plan_saved_message": "Votre plan de voyage a été enregistré avec succès.",
                "no_plans_saved": "Aucun plan de voyage enregistré",
                "plans_appear_here": "Vos plans de voyage enregistrés apparaîtront ici",
                "my_travel_plans": "Mes Plans de Voyage",
                "photo": "Photo",
                "activity": "Activité",
                "recommendations": "Recommandations pour cette Journée",
                "food_drinks": "Nourriture & Boissons",
                "transport": "Transport",
                "useful_tips": "Conseils Utiles",
                "no_activities_found": "Aucune activité trouvée pour cette journée",
                "no_plan_data": "Aucune donnée de plan de voyage disponible",
                "art": "Art",
                "history": "Histoire",
                "architecture": "Architecture",
                "gastronomy": "Gastronomie",
                "shopping": "Shopping",
                "nightlife": "Vie Nocturne",
                "culture": "Culture",
                "sightseeing": "Visites Touristiques",
                "plan_load_error": "Le plan de voyage n'a pas pu être chargé",
                "back": "Retour",
                
                // Onboarding
                "welcome_to_citytailor": "Bienvenue sur CityTailor",
                "personalize_travel_plans": "Personnalisez vos plans de voyage en nous indiquant ce qui vous intéresse",
                "set_interests": "Définir les Intérêts",
                "skip": "Passer",
                
                // Premium Feature
                "support_future_development": "Soutien au développement futur"
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
                "date_format": "Formato de Fecha",
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
                "unlimited_plans": "Planes de viaje ilimitados",
                "custom_plans": "Planes de viaje personalizados",
                "enhanced_ai": "Sugerencias mejoradas de IA",
                "offline_access": "Acceso sin conexión",
                "no_ads": "Sin publicidad",
                "monthly_subscription": "Suscripción Premium mensual",
                "yearly_subscription": "Suscripción Premium anual (Ahorre 20%)",
                "per_month": "por mes",
                "per_year": "por año",
                "search_city": "Buscar ciudad...",
                "about_message": "Una aplicación impulsada por IA para crear planes de viaje personalizados.\n\n© 2025 Alex Polan",
                "destination": "Destino",
                "location": "Ubicación",
                "travel_period": "Período de Viaje",
                "arrival_date": "Fecha de Llegada",
                "departure_date": "Fecha de Salida",
                "duration": "Duración",
                "days": "Días",
                "day_singular": "Día",
                "generate_plan": "Generar Plan de Viaje",
                "free_account": "Cuenta Gratuita",
                "remaining_free_plans": "Planes Gratuitos Restantes",
                "of": "de",
                "limit_reached": "Límite Alcanzado",
                "limit_reached_message": "Has alcanzado el máximo de {0} planes de viaje para la versión gratuita. Actualiza a Premium para planes ilimitados.",
                "cancel": "Cancelar",
                "ok": "Aceptar",
                "preparing_generation": "Preparando generación...",
                "generating_day": "Generando día {0} de {1}...",
                "finalizing_plan": "Finalizando plan de viaje...",
                "backend_notification": "Notificación del Backend",
                "invalid_url": "URL inválida",
                "server_error": "Error del servidor: Estado {0}",
                "invalid_server_response": "Respuesta del servidor inválida",
                "data_processing_error": "Error al procesar los datos: {0}",
                "json_error": "Error al crear datos JSON: {0}",
                "travel_plan_saved": "Plan de Viaje Guardado",
                "travel_plan_saved_message": "Tu plan de viaje ha sido guardado exitosamente.",
                "no_plans_saved": "No hay planes de viaje guardados aún",
                "plans_appear_here": "Tus planes de viaje guardados aparecerán aquí",
                "my_travel_plans": "Mis Planes de Viaje",
                "photo": "Foto",
                "activity": "Actividad",
                "recommendations": "Recomendaciones para Este Día",
                "food_drinks": "Comida y Bebida",
                "transport": "Transporte",
                "useful_tips": "Consejos Útiles",
                "no_activities_found": "No se encontraron actividades para este día",
                "no_plan_data": "No hay datos de plan de viaje disponibles",
                "art": "Arte",
                "history": "Historia",
                "architecture": "Arquitectura",
                "gastronomy": "Gastronomía",
                "shopping": "Shopping",
                "nightlife": "Vida Nocturna",
                "culture": "Cultura",
                "sightseeing": "Turismo",
                "plan_load_error": "No se pudo cargar el plan de viaje",
                "back": "Volver",
                
                // Onboarding
                "welcome_to_citytailor": "Bienvenido a CityTailor",
                "personalize_travel_plans": "Personalice sus planes de viaje diciéndonos qué le interesa",
                "set_interests": "Establecer Intereses",
                "skip": "Omitir",
                
                // Premium Feature
                "support_future_development": "Apoyo al desarrollo futuro"
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
                "date_format": "Formato Data",
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
                "unlimited_plans": "Piani di viaggio illimitati",
                "custom_plans": "Piani di viaggio personalizzati",
                "enhanced_ai": "Suggerimenti AI migliorati",
                "offline_access": "Accesso offline",
                "no_ads": "Nessuna pubblicità",
                "monthly_subscription": "Abbonamento Premium mensile",
                "yearly_subscription": "Abbonamento Premium annuale (Risparmia 20%)",
                "per_month": "al mese",
                "per_year": "all'anno",
                "search_city": "Cerca città...",
                "about_message": "Un'app basata sull'intelligenza artificiale per creare piani di viaggio personalizzati.\n\n© 2025 Alex Polan",
                "destination": "Destinazione",
                "location": "Località",
                "travel_period": "Periodo di Viaggio",
                "arrival_date": "Data di Arrivo",
                "departure_date": "Data di Partenza",
                "duration": "Durata",
                "days": "Giorni",
                "day_singular": "Giorno",
                "generate_plan": "Genera Piano di Viaggio",
                "free_account": "Account Gratuito",
                "remaining_free_plans": "Piani Gratuiti Rimanenti",
                "of": "di",
                "limit_reached": "Limite Raggiunto",
                "limit_reached_message": "Hai raggiunto il massimo di {0} piani di viaggio per la versione gratuita. Passa a Premium per piani illimitati.",
                "cancel": "Annulla",
                "ok": "OK",
                "preparing_generation": "Preparazione della generazione...",
                "generating_day": "Generazione del giorno {0} di {1}...",
                "finalizing_plan": "Finalizzazione del piano di viaggio...",
                "backend_notification": "Notifica del Backend",
                "invalid_url": "URL non valido",
                "server_error": "Errore del server: Stato {0}",
                "invalid_server_response": "Risposta del server non valida",
                "data_processing_error": "Errore durante l'elaborazione dei dati: {0}",
                "json_error": "Errore durante la creazione dei dati JSON: {0}",
                "travel_plan_saved": "Piano di Viaggio Salvato",
                "travel_plan_saved_message": "Il tuo piano di viaggio è stato salvato con successo.",
                "no_plans_saved": "Nessun piano di viaggio salvato ancora",
                "plans_appear_here": "I tuoi piani di viaggio salvati appariranno qui",
                "my_travel_plans": "I Miei Piani di Viaggio",
                "photo": "Foto",
                "activity": "Attività",
                "recommendations": "Raccomandazioni per Questa Giornata",
                "food_drinks": "Cibo e Bevande",
                "transport": "Trasporti",
                "useful_tips": "Consigli Utili",
                "no_activities_found": "Nessuna attività trovata per questa giornata",
                "no_plan_data": "Nessun dato del piano di viaggio disponibile",
                "art": "Arte",
                "history": "Storia",
                "architecture": "Architettura",
                "gastronomy": "Gastronomia",
                "shopping": "Shopping",
                "nightlife": "Vita Notturna",
                "culture": "Cultura",
                "sightseeing": "Visite Turistiche",
                "plan_load_error": "Impossibile caricare il piano di viaggio",
                "back": "Indietro",
                
                // Onboarding
                "welcome_to_citytailor": "Benvenuto su CityTailor",
                "personalize_travel_plans": "Personalizza i tuoi piani di viaggio indicandoci ciò che ti interessa",
                "set_interests": "Imposta Interessi",
                "skip": "Salta",
                
                // Premium Feature
                "support_future_development": "Supporto allo sviluppo futuro"
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