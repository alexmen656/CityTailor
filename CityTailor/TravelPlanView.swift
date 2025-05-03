import SwiftUI

struct TravelPlanView: View {
    let travelPlan: TravelPlan
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedDay: Int = 1
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                VStack {
                    Text(travelPlan.location)
                        .font(.largeTitle)
                        .bold()
                        .padding(.top)
                    
                    Text("\(travelPlan.period.startDate) bis \(travelPlan.period.endDate)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.bottom)
                
                if let dailyPlans = travelPlan.dailyPlans, !dailyPlans.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(dailyPlans) { day in
                                DayButton(
                                    dayNumber: day.dayNumber,
                                    date: formatDateShort(day.date),
                                    isSelected: selectedDay == day.dayNumber
                                ) {
                                    selectedDay = day.dayNumber
                                }
                            }
                        }
                        .padding()
                    }
                    .background(Color(.systemGray6))
                    
                    if let dayPlan = dailyPlans.first(where: { $0.dayNumber == selectedDay }) {
                        List {
                            ForEach(dayPlan.activities) { activity in
                                VStack(alignment: .leading, spacing: 5) {
                                    HStack {
                                        Text(activity.time)
                                            .font(.headline)
                                            .foregroundColor(.blue)
                                        
                                        Spacer()
                                        
                                        Text(activity.category)
                                            .font(.caption)
                                            .padding(5)
                                            .background(categoryColor(for: activity.category))
                                            .foregroundColor(.white)
                                            .cornerRadius(5)
                                    }
                                    
                                    Text(activity.title)
                                        .font(.title3)
                                        .bold()
                                    
                                    Text(activity.description)
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                    
                                    HStack {
                                        Image(systemName: "mappin.circle.fill")
                                            .foregroundColor(.red)
                                        Text(activity.location)
                                            .font(.subheadline)
                                    }
                                    .padding(.top, 3)
                                }
                                .padding(.vertical, 8)
                            }
                            
                            if let recommendations = travelPlan.recommendations {
                                Section(header: Text("Empfehlungen für diesen Tag")) {
                                    if !recommendations.food.isEmpty {
                                        DisclosureGroup("Essen & Trinken") {
                                            ForEach(recommendations.food, id: \.self) { food in
                                                Label(food, systemImage: "fork.knife")
                                            }
                                        }
                                    }
                                    
                                    if !recommendations.transport.isEmpty {
                                        DisclosureGroup("Transport") {
                                            ForEach(recommendations.transport, id: \.self) { tip in
                                                Label(tip, systemImage: "tram.fill")
                                            }
                                        }
                                    }
                                    
                                    if !recommendations.tips.isEmpty {
                                        DisclosureGroup("Nützliche Tipps") {
                                            ForEach(recommendations.tips, id: \.self) { tip in
                                                Label(tip, systemImage: "lightbulb.fill")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        Spacer()
                        Text("Keine Aktivitäten für diesen Tag gefunden.")
                        Spacer()
                    }
                } else if let info = travelPlan.info {
                    Spacer()
                    Text(info)
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .padding()
                    Spacer()
                } else {
                    Spacer()
                    Text("Keine Reiseplan-Daten verfügbar.")
                    Spacer()
                }
            }
            .navigationBarItems(trailing: Button("Fertig") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    func formatDateShort(_ dateString: String) -> String {
        if let date = parseDate(dateString) {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd.MM."
            return formatter.string(from: date)
        }
        return dateString
    }
    
    func parseDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }
    
    func categoryColor(for category: String) -> Color {
        switch category.lowercased() {
        case "kunst": return Color.purple
        case "geschichte": return Color.orange
        case "architektur": return Color.blue
        case "gastronomie": return Color.red
        case "shopping": return Color.pink
        case "nachtleben": return Color.indigo
        case "kultur": return Color.teal
        case "sightseeing": return Color.green
        default: return Color.gray
        }
    }
}