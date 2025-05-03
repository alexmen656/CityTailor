import SwiftUI

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

struct DayButton: View {
    let dayNumber: Int
    let date: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Text("Tag \(dayNumber)")
                    .fontWeight(isSelected ? .bold : .regular)
                
                Text(date)
                    .font(.caption)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isSelected ? Color.blue : Color.clear)
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(10)
        }
    }
}