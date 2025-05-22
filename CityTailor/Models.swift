import SwiftUI
import CoreLocation
import MapKit  

enum BudgetLevel: String, CaseIterable, Codable {
    case low = "budget_level_low"
    case medium = "budget_level_medium"
    case high = "budget_level_high"
    case luxury = "budget_level_luxury"
    
    func localizedName(languageManager: LanguageManager) -> String {
        return languageManager.localize(self.rawValue)
    }
    
    /*var icon: String {
        switch self {
        case .low: return "banknote"
        case .medium: return "creditcard"
        case .high: return "dollarsign.circle"
        case .luxury: return "dollarsign.circle.fill"
        }
    }*/
    
    var symbol: String {
        switch self {
        case .low: return "$"
        case .medium: return "$$"
        case .high: return "$$$"
        case .luxury: return "$$$$"
        }
    }
}

enum TransportationType: String, CaseIterable, Codable {
    case walking = "transport_type_walking"
    case publicTransport = "transport_type_public"
    case bicycle = "transport_type_bicycle"
    case car = "transport_type_car"
    case mixed = "transport_type_mix"
    
    func localizedName(languageManager: LanguageManager) -> String {
        return languageManager.localize(self.rawValue)
    }
    
    var icon: String {
        switch self {
        case .walking: return "figure.walk"
        case .publicTransport: return "bus"
        case .bicycle: return "bicycle"
        case .car: return "car"
        case .mixed: return "arrow.triangle.swap"
        }
    }
}

enum TravelMode: String, CaseIterable, Codable {
    case relaxing = "travel_mode_relaxing"
    case moderate = "travel_mode_moderate"
    case active = "travel_mode_active"
    
    func localizedName(languageManager: LanguageManager) -> String {
        return languageManager.localize(self.rawValue)
    }
    
    var icon: String {
        switch self {
        case .relaxing: return "leaf"
        case .moderate: return "figure.walk"
        case .active: return "figure.hiking"
        }
    }
}

enum TravelType: String, CaseIterable, Codable {
    case solo = "travel_type_solo"
    case couple = "travel_type_couple"
    case family = "travel_type_family"
    case friends = "travel_type_friends"
    case business = "travel_type_business"
    
    func localizedName(languageManager: LanguageManager) -> String {
        return languageManager.localize(self.rawValue)
    }
    
    var icon: String {
        switch self {
        case .solo: return "person"
        case .couple: return "heart"
        case .family: return "person.3"
        case .friends: return "person.2"
        case .business: return "briefcase"
        }
    }
}

struct BackendResponse: Codable {
    let success: Bool
    let message: String
    let data: TravelPlan
}

struct TravelPlan: Codable, Identifiable {
    var id: String { location }
    let location: String
    let period: TravelPeriod
    let dailyPlans: [DailyPlan]?
    let recommendations: Recommendations?
    let info: String?
    let image: ImageInfo?
    
    enum CodingKeys: String, CodingKey {
        case location
        case period
        case dailyPlans
        case recommendations
        case info
        case image
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        location = try container.decode(String.self, forKey: .location)
        period = try container.decode(TravelPeriod.self, forKey: .period)
        
        dailyPlans = try container.decodeIfPresent([DailyPlan].self, forKey: .dailyPlans)
        recommendations = try container.decodeIfPresent(Recommendations.self, forKey: .recommendations)
        info = try container.decodeIfPresent(String.self, forKey: .info)
        
        image = try? container.decodeIfPresent(ImageInfo.self, forKey: .image)
    }
}

struct ImageInfo: Codable {
    let url: String
    let description: String
    let photographer: String
    let photographerLink: String
}

struct TravelPeriod: Codable {
    let startDate: String
    let endDate: String
    let durationInDays: Int
}

struct DailyPlan: Codable, Identifiable {
    var id: String { date }
    let date: String
    let dayNumber: Int
    let activities: [Activity]
}

struct Activity: Codable, Identifiable {
    var id = UUID()
    let time: String
    let title: String
    let description: String
    let mapAddress: String
    let displayAddress: String
    let category: String
    let imageUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case time, title, description, mapAddress, displayAddress, category, location, imageUrl
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        time = try container.decode(String.self, forKey: .time)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        
        let mapAddr = try? container.decodeIfPresent(String.self, forKey: .mapAddress)
        let displayAddr = try? container.decodeIfPresent(String.self, forKey: .displayAddress)
        
        if let map = mapAddr, let display = displayAddr {
            mapAddress = map
            displayAddress = display
        } else {
            let location = try container.decode(String.self, forKey: .location)
            mapAddress = location
            displayAddress = location
        }
        
        category = try container.decode(String.self, forKey: .category)
        imageUrl = try? container.decodeIfPresent(String.self, forKey: .imageUrl)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(time, forKey: .time)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(mapAddress, forKey: .mapAddress)
        try container.encode(displayAddress, forKey: .displayAddress)
        try container.encode(category, forKey: .category)
        try container.encodeIfPresent(imageUrl, forKey: .imageUrl)
    }
    
    init(time: String, title: String, description: String, mapAddress: String, displayAddress: String, category: String, imageUrl: String? = nil) {
        self.time = time
        self.title = title
        self.imageUrl = imageUrl
        self.description = description
        self.mapAddress = mapAddress
        self.displayAddress = displayAddress
        self.category = category
    }
}

extension Activity {
    var isTicketable: Bool {
        
        let ticketableCategories = [
            "museum", "museum", "musée", "museo",
            "attraction", "attraktion", "atracción", "attrazione",
            "tour", "führung", "visita",
            "exhibit", "ausstellung", "exposition", "exposición", "mostra",
            "art", "kunst", "arte",
            "theater", "théâtre", "teatro",
            "concert", "konzert", "concierto", "concerto",
            "show", "aufführung", "spectacle", "espectáculo", "spettacolo",
            "park", "parque", "parco",
            "garden", "garten", "jardin", "jardín", "giardino",
            "palace", "palast", "palacio", "palazzo",
            "castle", "schloss", "château", "castillo", "castello",
            "monument", "denkmal", "monumento"
        ]
        
        let lowercasedTitle = title.lowercased()
        let lowercasedCategory = category.lowercased()
        
        return ticketableCategories.contains { keyword in
            lowercasedCategory.contains(keyword) || lowercasedTitle.contains(keyword)
        }
    }
    
    var getYourGuideURL: URL? {
        let baseURL = "https://www.getyourguide.com"
        let locationComponents = displayAddress.components(separatedBy: ",")
        let locationName = locationComponents.count > 1 ? locationComponents.last?.trimmingCharacters(in: .whitespacesAndNewlines) : title
        var searchQuery = locationName ?? ""
        let titleWords = title.components(separatedBy: " ")
        let significantTitleWords = titleWords.filter { word in
            let lowercasedWord = word.lowercased()
            
            return word.count > 3 && !["the", "and", "oder", "oder", "oder", "des", "los", "las", "les", "il", "lo", "la"].contains(lowercasedWord)
        }
        
        if !significantTitleWords.isEmpty {
            searchQuery += " " + significantTitleWords.joined(separator: " ")
        }
        
        if let encodedQuery = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            return URL(string: "\(baseURL)/s/?q=\(encodedQuery)&partner_id=EAULFPM&cmp=share_to_earn")
        }
        
        return URL(string: baseURL)
    }
}

struct Recommendations: Codable {
    let food: [String]
    let transport: [String]
    let tips: [String]
}

struct Interest: Identifiable {
    var id = UUID()
    var name: String
    var rating: Double
}

struct MapAnnotation: Identifiable {
    var id = UUID()
    let title: String
    let subtitle: String?
    let coordinate: CLLocationCoordinate2D
    let activityInfo: Activity?
    let useAppleMapsStyle: Bool
    let mapItem: MKMapItem?
    let imageURL: URL?
    
    init(title: String, subtitle: String? = nil, coordinate: CLLocationCoordinate2D, activityInfo: Activity? = nil, useAppleMapsStyle: Bool = false, mapItem: MKMapItem? = nil, imageURL: URL? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
        self.activityInfo = activityInfo
        self.useAppleMapsStyle = useAppleMapsStyle
        self.mapItem = mapItem
        self.imageURL = imageURL
    }
}

struct DayButton: View {
    let dayNumber: Int
    let date: String
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject private var languageManager: LanguageManager
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text("\(languageManager.localize("day")) \(dayNumber)")
                    .font(.caption)
                    .fontWeight(isSelected ? .bold : .medium)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(date)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
            }
            .frame(width: 70)
            .padding(.vertical, 5)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue : Color(.systemGray5))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
