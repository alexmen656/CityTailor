//
//  Widget_1.swift
//  Widget 1
//
//  Created by Alex Polan on 5/13/25.
//

import WidgetKit
import SwiftUI
import CoreData

struct WidgetTravelPlan: Identifiable, Codable {
    let id: String
    let location: String
    let startDate: String
    let endDate: String
    
    static let samples = [
        WidgetTravelPlan(id: "1", location: "Paris", startDate: "2025-06-10", endDate: "2025-06-15"),
        WidgetTravelPlan(id: "2", location: "Tokyo", startDate: "2025-07-22", endDate: "2025-07-30"),
        WidgetTravelPlan(id: "3", location: "New York", startDate: "2025-08-05", endDate: "2025-08-12")
    ]
}

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent(), travelPlans: WidgetTravelPlan.samples)
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: configuration, travelPlans: getPlans())
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let currentDate = Date()
        let nextMidnight = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!)
        let entry = SimpleEntry(date: currentDate, configuration: configuration, travelPlans: getPlans())
        return Timeline(entries: [entry], policy: .after(nextMidnight))
    }
    
    private func getPlans() -> [WidgetTravelPlan] {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.app.CityTailor") else {
            print("Widget: Konnte keine shared UserDefaults finden")
            return WidgetTravelPlan.samples
        }
        
        if let planData = sharedDefaults.data(forKey: "widget_travel_plans") {
            do {
                let plans = try JSONDecoder().decode([WidgetTravelPlan].self, from: planData)
                print("Widget: \(plans.count) Pläne erfolgreich geladen")
                return plans.isEmpty ? WidgetTravelPlan.samples : plans
            } catch {
                print("Widget: Fehler beim Dekodieren der Reisepläne: \(error)")
                
                if let planDicts = sharedDefaults.array(forKey: "widget_travel_plans") as? [[String: String]] {
                    let plans = planDicts.compactMap { dict -> WidgetTravelPlan? in
                        guard let id = dict["id"],
                              let location = dict["location"],
                              let startDate = dict["startDate"],
                              let endDate = dict["endDate"] else {
                            return nil
                        }
                        return WidgetTravelPlan(id: id, location: location, startDate: startDate, endDate: endDate)
                    }
                    print("Widget: \(plans.count) Pläne aus Dictionary-Format gelesen")
                    return plans.isEmpty ? WidgetTravelPlan.samples : plans
                }
            }
        }
        
        print("Widget: Keine Daten gefunden, verwende Sample-Daten")
        return WidgetTravelPlan.samples
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let travelPlans: [WidgetTravelPlan]
}

struct Widget_1EntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

struct SmallWidgetView: View {
    var entry: Provider.Entry
    
    var body: some View {
        if let nextTrip = entry.travelPlans.first {
            VStack(alignment: .leading, spacing: 4) {
                Text("Next Trip")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(nextTrip.location)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                HStack {
                    Image(systemName: "calendar")
                        .font(.caption)
                    Text(formatDate(nextTrip.startDate))
                        .font(.subheadline)
                }
                
                Text("\(daysUntil(nextTrip.startDate)) days remaining")
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
            .padding()
        } else {
            VStack {
                Spacer()
                Text("No upcoming trips")
                    .font(.caption)
                Spacer()
            }
        }
    }
}

struct MediumWidgetView: View {
    var entry: Provider.Entry
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Upcoming Trips")
                .font(.headline)
                .padding(.bottom, 4)
            
            ForEach(entry.travelPlans.prefix(2)) { plan in
                HStack {
                    Image(systemName: "airplane.circle.fill")
                        .foregroundStyle(.blue)
                    
                    VStack(alignment: .leading) {
                        Text(plan.location)
                            .font(.subheadline)
                            .lineLimit(1)
                        
                        Text("\(formatDate(plan.startDate)) - \(formatDate(plan.endDate))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding()
    }
}

struct LargeWidgetView: View {
    var entry: Provider.Entry
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Your Travel Plans")
                .font(.headline)
                .padding(.bottom, 8)
            
            ForEach(entry.travelPlans) { plan in
                HStack {
                    Image(systemName: "airplane.circle.fill")
                        .foregroundStyle(.blue)
                        .font(.system(size: 24))
                    
                    VStack(alignment: .leading) {
                        Text(plan.location)
                            .font(.subheadline)
                            .fontWeight(.bold)
                        
                        Text("\(formatDate(plan.startDate)) - \(formatDate(plan.endDate))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("\(daysUntil(plan.startDate)) days")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
                .padding(.vertical, 4)
                
                if plan.id != entry.travelPlans.last?.id {
                    Divider()
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

func formatDate(_ dateString: String) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    
    if let date = dateFormatter.date(from: dateString) {
        dateFormatter.dateStyle = .medium
        return dateFormatter.string(from: date)
    }
    return dateString
}

func daysUntil(_ dateString: String) -> Int {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    
    guard let date = dateFormatter.date(from: dateString) else { return 0 }
    
    let calendar = Calendar.current
    let components = calendar.dateComponents([.day], from: Date(), to: date)
    return max(0, components.day ?? 0)
}

struct Widget_1: Widget {
    let kind: String = "com.app.CityTailor.Widget-1"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            Widget_1EntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Travel Plans")
        .description("View your upcoming travel plans")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

extension ConfigurationAppIntent {
    fileprivate static var smiley: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "✈️" 
        return intent
    }
    
    fileprivate static var starEyes: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "🧳"
        return intent
    }
}

#Preview(as: .systemSmall) {
    Widget_1()
} timeline: {
    SimpleEntry(date: .now, configuration: .smiley, travelPlans: WidgetTravelPlan.samples)
}

#Preview(as: .systemMedium) {
    Widget_1()
} timeline: {
    SimpleEntry(date: .now, configuration: .starEyes, travelPlans: WidgetTravelPlan.samples)
}

#Preview(as: .systemLarge) {
    Widget_1()
} timeline: {
    SimpleEntry(date: .now, configuration: .smiley, travelPlans: WidgetTravelPlan.samples)
}
