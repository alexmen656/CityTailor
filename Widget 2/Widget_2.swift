//
//  Widget_2.swift
//  Widget 2
//
//  Created by Alex Polan on 5/14/25.
//

import WidgetKit
import SwiftUI
import CoreData


struct PremiumTravelPlan: Identifiable, Codable {
    let id: String
    let location: String
    let startDate: String
    let endDate: String
    let activitiesCount: Int
    let isPremiumTrip: Bool
    
    
    static let samples = [
        PremiumTravelPlan(
            id: "1", 
            location: "Venedig", 
            startDate: "2025-06-10", 
            endDate: "2025-06-15",
            activitiesCount: 8,
            isPremiumTrip: true
        ),
        PremiumTravelPlan(
            id: "2", 
            location: "Barcelona", 
            startDate: "2025-07-22", 
            endDate: "2025-07-30",
            activitiesCount: 12,
            isPremiumTrip: true
        )
    ]
}

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            configuration: ConfigurationAppIntent(),
            isPremium: true,
            travelPlans: PremiumTravelPlan.samples
        )
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(
            date: Date(), 
            configuration: configuration,
            isPremium: checkPremiumStatus(),
            travelPlans: getPlans()
        )
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let isPremium = checkPremiumStatus()
        
        
        let currentDate = Date()
        let nextUpdateTime = Calendar.current.date(byAdding: .hour, value: 4, to: currentDate)!
        
        if isPremium {
            let entry = SimpleEntry(
                date: currentDate,
                configuration: configuration,
                isPremium: true,
                travelPlans: getPlans()
            )
            return Timeline(entries: [entry], policy: .after(nextUpdateTime))
        } else {
            
            let entry = SimpleEntry(
                date: currentDate,
                configuration: configuration,
                isPremium: false,
                travelPlans: []
            )
            return Timeline(entries: [entry], policy: .after(nextUpdateTime))
        }
    }
    
    
    private func checkPremiumStatus() -> Bool {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.app.CityTailor") else {
            print("Widget 2: Kein Zugriff auf group.com.app.CityTailor UserDefaults")
            return false
        }
        
        let isPremium = sharedDefaults.bool(forKey: "is_premium_user")
        print("Widget 2: Premium-Status geprüft: \(isPremium)")
        return isPremium
    }
    
    
    private func getPlans() -> [PremiumTravelPlan] {
        guard checkPremiumStatus(),
              let sharedDefaults = UserDefaults(suiteName: "group.com.app.CityTailor") else {
            print("Widget 2: Keine Premium-Berechtigung oder kein Zugriff auf UserDefaults")
            return []
        }
        
        if let planData = sharedDefaults.data(forKey: "premium_widget_plans") {
            do {
                let plans = try JSONDecoder().decode([PremiumTravelPlan].self, from: planData)
                print("Widget 2: \(plans.count) Premium-Reisepläne erfolgreich geladen")
                
                
                for (index, plan) in plans.enumerated() {
                    print("Widget 2: Geladener Plan \(index+1): \(plan.location) (\(plan.startDate) - \(plan.endDate))")
                }
                
                return plans.isEmpty ? PremiumTravelPlan.samples : plans
            } catch {
                print("Widget 2: Fehler beim Dekodieren der Premium-Reisepläne: \(error)")
            }
        } else {
            print("Widget 2: Keine Premium-Plandaten in UserDefaults gefunden")
        }
        
        print("Widget 2: Verwende Sample-Daten")
        return PremiumTravelPlan.samples
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let isPremium: Bool
    let travelPlans: [PremiumTravelPlan]
}

struct Widget_2EntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        ZStack {
            if !entry.isPremium {
                premiumUpsellView
            } else {
                if entry.travelPlans.isEmpty {
                    Text("Keine Reisepläne verfügbar")
                        .font(.callout)
                        .padding()
                } else {
                    switch family {
                    case .systemSmall:
                        smallPremiumView(entry: entry)
                    case .systemMedium:
                        mediumPremiumView(entry: entry)
                    case .systemLarge:
                        largePremiumView(entry: entry)
                    default:
                        mediumPremiumView(entry: entry)
                    }
                }
            }
        }
    }
    
    
    var premiumUpsellView: some View {
        VStack(spacing: 8) {
            Image(systemName: "crown.fill")
                .font(.system(size: 28))
                .foregroundStyle(.yellow)
            
            Text("Premium Widget")
                .font(.headline)
                .fontWeight(.bold)
            
            Text("Upgraden, um all deine Reisepläne in einem schönen Design zu sehen")
                .font(.caption)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
        .padding()
    }
    
    func smallPremiumView(entry: Provider.Entry) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            
            if let nextTrip = entry.travelPlans.first {
                
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text(nextTrip.location)
                            .font(.system(size: 15, weight: .bold))
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Image(systemName: "airplane.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.blue)
                    }
                    
                    Text("\(formatDate(nextTrip.startDate)) - \(formatDate(nextTrip.endDate))")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    
                    HStack {
                        Text("\(daysUntil(nextTrip.startDate)) Tage")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.blue)
                        
                        Text("·")
                            .foregroundStyle(.secondary)
                        
                        Text("\(nextTrip.activitiesCount) Akt.")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 1)
                }
                
                Divider()
                
                
                VStack(alignment: .leading, spacing: 0) {
                    Text("Weitere Reisen")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 2)
                    
                    ForEach(entry.travelPlans.dropFirst().prefix(2)) { plan in
                        HStack {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 5))
                                .foregroundStyle(.blue)
                                .padding(.trailing, -2)
                            
                            Text(plan.location)
                                .lineLimit(1)
                                .font(.system(size: 10, weight: .medium))
                            
                            Spacer()
                            
                            Text("\(daysUntil(plan.startDate))")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.blue)
                        }
                    }
                }
                
                
                Spacer(minLength: 2)
                HStack {
                    Text("Gesamt:")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                    
                    Text("\(entry.travelPlans.count) Reisen")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text("PREMIUM")
                        .font(.system(size: 7, weight: .bold))
                        .padding(2)
                        .background(Color.yellow)
                        .foregroundColor(.black)
                        .cornerRadius(2)
                }
            } else {
                Text("Keine Reisepläne")
                    .font(.callout)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
        .padding(4)
    }
    
    func mediumPremiumView(entry: Provider.Entry) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            
            if let firstPlan = entry.travelPlans.first {
                HStack(spacing: 8) {
                    Image(systemName: "airplane.circle.fill")
                        .font(.system(size: 23))
                        .foregroundStyle(.blue)
                    
                    VStack(alignment: .leading, spacing: 1) {

                        HStack {
                        Text(firstPlan.location)
                            .font(.headline)
                            .lineLimit(1)

                            Spacer()
                           Text("\(daysUntil(firstPlan.startDate)) Tage")
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 3))
                    }

                        Text("\(formatDate(firstPlan.startDate)) - \(formatDate(firstPlan.endDate))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                      /*  HStack {
                            Text("\(daysUntil(firstPlan.startDate)) Tage")
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(Color.blue.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 3))
                            
                            Text("·")
                                .foregroundStyle(.secondary)
                                
                            Text("\(firstPlan.activitiesCount) Aktivitäten")
                                .font(.caption2)
                                .foregroundStyle(.blue)
                        }*/
                    }
                }
                .padding(.bottom, 4)
            }
            
            Divider().padding(.vertical, 1)
            
            
            ForEach(entry.travelPlans.prefix(4).dropFirst()) { plan in
                HStack(spacing: 5) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 6))
                        .foregroundStyle(.blue)
                    
                    Text(plan.location)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(formatDate(plan.startDate))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("·")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("\(daysUntil(plan.startDate)) T")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.blue)
                }
                .padding(.vertical, 2)
                
                if plan.id != entry.travelPlans.prefix(4).dropFirst().last?.id {
                    Divider().padding(.vertical, 1)
                }
            }
            Spacer()
            
        /*    if entry.travelPlans.count < 4 {
                Spacer(minLength: 0)
                
                Divider().padding(.vertical, 2)
                
                
                HStack {
                    Text("Gesamt:")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Text("\(entry.travelPlans.count) Reisen")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    
                    let totalActivities = entry.travelPlans.reduce(0) { $0 + $1.activitiesCount }
                    Text("\(totalActivities) Aktivitäten gesamt")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 2)
            }*/
        }
        .padding(4)
    }
    
    func largePremiumView(entry: Provider.Entry) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            
            ForEach(entry.travelPlans.prefix(5)) { plan in
                HStack(spacing: 8) {
                    Image(systemName: "airplane.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.blue)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            Text(plan.location)
                                .font(.headline)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Text("\(daysUntil(plan.startDate))")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundStyle(.blue)
                        }
                        
                        HStack {
                            Text("\(formatDate(plan.startDate)) - \(formatDate(plan.endDate))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            Text("Tage")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        
                        Text("\(plan.activitiesCount) Aktivitäten")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }
                }
                
                if plan.id != entry.travelPlans.prefix(5).last?.id {
                    Divider().padding(.vertical, 1)
                }
            }
            
            Spacer()
        }
        .padding(4) 
    }
}


func formatDate(_ dateString: String) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    
    if let date = dateFormatter.date(from: dateString) {
        dateFormatter.dateFormat = "dd.MM."
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

struct Widget_2: Widget {
    let kind: String = "Widget_2"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            Widget_2EntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Premium Reiseübersicht")
        .description("Exklusives Widget für Premium-Nutzer mit übersichtlicher Darstellung deiner Reisepläne")
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

#Preview(as: .systemMedium) {
    Widget_2()
} timeline: {
    SimpleEntry(date: .now, configuration: .smiley, isPremium: true, travelPlans: PremiumTravelPlan.samples)
}

#Preview(as: .systemLarge) {
    Widget_2()
} timeline: {
    SimpleEntry(date: .now, configuration: .starEyes, isPremium: true, travelPlans: PremiumTravelPlan.samples)
}

#Preview(as: .systemSmall) {
    Widget_2()
} timeline: {
    SimpleEntry(date: .now, configuration: .smiley, isPremium: true, travelPlans: PremiumTravelPlan.samples)
}
