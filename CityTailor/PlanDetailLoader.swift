import SwiftUI
import CoreData

struct PlanDetailLoader: View {
    let planID: String
    let context: NSManagedObjectContext
    @Environment(\.presentationMode) var presentationMode
    @State private var loadedPlan: SavedTravelPlanViewModel?
    @State private var isLoading = true
    @State private var loadError: String? = nil
    @State private var selectedDay: Int = 1
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Reiseplan wird geladen...")
                            .padding(.top, 20)
                    }
                } else if let plan = loadedPlan {
                    VStack(spacing: 0) {
                        VStack {
                            Text(plan.location)
                                .font(.largeTitle)
                                .bold()
                                .padding(.top)
                            
                            Text("\(DateFormatterUtils.formatDateString(plan.startDate)) bis \(DateFormatterUtils.formatDateString(plan.endDate))")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.bottom)
                        
                        if let dailyPlans = plan.plan.dailyPlans, !dailyPlans.isEmpty {
                            // Tag-Auswahl
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(dailyPlans) { day in
                                        Button(action: {
                                            selectedDay = day.dayNumber
                                        }) {
                                            VStack(spacing: 2) {
                                                Text("Tag \(day.dayNumber)")
                                                    .font(.caption)
                                                    .fontWeight(selectedDay == day.dayNumber ? .bold : .medium)
                                                    .foregroundColor(selectedDay == day.dayNumber ? .white : .primary)
                                                
                                                Text(formatDateShort(day.date))
                                                    .font(.caption2)
                                                    .foregroundColor(selectedDay == day.dayNumber ? .white.opacity(0.9) : .secondary)
                                            }
                                            .frame(width: 70)
                                            .padding(.vertical, 5)
                                            .padding(.horizontal, 4)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(selectedDay == day.dayNumber ? Color.blue : Color(.systemGray5))
                                            )
                                        }
                                    }
                                }
                                .padding()
                            }
                            .background(Color(.systemGray6))
                            .onAppear {
                                let validDayNumbers = dailyPlans.map { $0.dayNumber }
                                if !validDayNumbers.contains(selectedDay) {
                                    if let firstDay = dailyPlans.first {
                                        selectedDay = firstDay.dayNumber
                                    }
                                }
                            }
                            
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
                                                .foregroundColor(.primary)
                                            
                                            Text(activity.description)
                                                .font(.body)
                                                .foregroundColor(.secondary)
                                            
                                            HStack {
                                                Image(systemName: "mappin.circle.fill")
                                                    .foregroundColor(.red)
                                                Text(activity.location)
                                                    .font(.subheadline)
                                                    .foregroundColor(.primary)
                                            }
                                            .padding(.top, 3)
                                        }
                                        .padding(.vertical, 4)
                                    }
                                    
                                    if let recommendations = plan.plan.recommendations {
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
                        } else if let info = plan.plan.info {
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
                } else {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                            .padding()
                        
                        Text("Reiseplan konnte nicht geladen werden")
                            .font(.headline)
                        
                        if let error = loadError {
                            Text(error)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding()
                        }
                        
                        Button("Zurück") {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.top, 20)
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            print("DEBUG: PlanDetailLoader appeared with plan ID: \(planID)")
            loadPlanDetails()
        }
    }
    
    private func loadPlanDetails() {
        print("DEBUG: Loading plan with ID: \(planID)")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            guard !planID.isEmpty else {
                isLoading = false
                loadError = "Keine Plan-ID verfügbar"
                return
            }
            
            let plans = TravelPlanStore.shared.getTravelPlans(context: context)
            if let matchingPlan = plans.first(where: { $0.id == planID }) {
                print("DEBUG: Plan found for ID \(planID): \(matchingPlan.location)")
                self.loadedPlan = matchingPlan
            } else {
                print("DEBUG: No plan found with ID \(planID)")
                loadError = "Plan nicht gefunden (ID: \(planID))"
            }
            
            isLoading = false
        }
    }
    
    func formatDateShort(_ dateString: String) -> String {
        return DateFormatterUtils.formatDateShort(dateString)
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