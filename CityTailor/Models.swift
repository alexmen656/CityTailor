import SwiftUI
import CoreLocation

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
    
    // CodingKeys für die explizite Kontrolle der Decodierung
    enum CodingKeys: String, CodingKey {
        case location
        case period
        case dailyPlans
        case recommendations
        case info
        case image
    }
    
    // Benutzerdefinierter Initialisierer für die Decodierung
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        location = try container.decode(String.self, forKey: .location)
        period = try container.decode(TravelPeriod.self, forKey: .period)
        
        // Optionale Felder
        dailyPlans = try container.decodeIfPresent([DailyPlan].self, forKey: .dailyPlans)
        recommendations = try container.decodeIfPresent(Recommendations.self, forKey: .recommendations)
        info = try container.decodeIfPresent(String.self, forKey: .info)
        
        // ImageInfo ist neu, daher versuchen wir es zu dekodieren, aber es ist ok wenn es fehlt
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
    let location: String
    let category: String
    
    enum CodingKeys: String, CodingKey {
        case time, title, description, location, category
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        time = try container.decode(String.self, forKey: .time)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        location = try container.decode(String.self, forKey: .location)
        category = try container.decode(String.self, forKey: .category)
    }
    
    init(time: String, title: String, description: String, location: String, category: String) {
        self.time = time
        self.title = title
        self.description = description
        self.location = location
        self.category = category
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

// Modell für Kartenannotationen
struct MapAnnotation: Identifiable {
    var id = UUID()
    let title: String
    let subtitle: String?
    let coordinate: CLLocationCoordinate2D
    let activityInfo: Activity?
    
    init(title: String, subtitle: String? = nil, coordinate: CLLocationCoordinate2D, activityInfo: Activity? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
        self.activityInfo = activityInfo
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
            .frame(width: 70) // Feste Breite für 4 Buttons pro Reihe
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
