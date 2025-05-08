import SwiftUI

struct TravelPlanView: View {
    let travelPlan: TravelPlan
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedDay: Int
    @EnvironmentObject private var languageManager: LanguageManager
    @EnvironmentObject private var settings: AppSettings
    var onActivitySelected: ((Activity) -> Void)? = nil
    
    // Führe eine Initialisierung am Anfang durch
    init(travelPlan: TravelPlan, selectedDay: Binding<Int>, onActivitySelected: ((Activity) -> Void)? = nil) {
        self.travelPlan = travelPlan
        self._selectedDay = selectedDay
        self.onActivitySelected = onActivitySelected
        
        print("DEBUG: TravelPlanView init for \(travelPlan.location)")
        print("DEBUG: Initial selected day: \(selectedDay.wrappedValue)")
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                VStack {
                    Text(travelPlan.location)
                        .font(.largeTitle)
                        .bold()
                        .padding(.top)
                    
                    Text("\(formatDateString(travelPlan.period.startDate)) \(languageManager.localize("to")) \(formatDateString(travelPlan.period.endDate))")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.bottom)
                .onAppear {
                    // Debug-Ausgaben
                    print("DEBUG: TravelPlanView appeared for \(travelPlan.location)")
                    print("DEBUG: Selected day: \(selectedDay)")
                    if let dailyPlans = travelPlan.dailyPlans {
                        print("DEBUG: Available days: \(dailyPlans.map { $0.dayNumber })")
                        print("DEBUG: First day activities count: \(dailyPlans.first?.activities.count ?? 0)")
                    } else {
                        print("DEBUG: No daily plans available")
                    }
                }
                
                if let dailyPlans = travelPlan.dailyPlans, !dailyPlans.isEmpty {
                    // Die State-Validierung wird in onAppear verschoben
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(dailyPlans) { day in
                                DayButton(
                                    dayNumber: day.dayNumber,
                                    date: formatDateShort(day.date),
                                    isSelected: selectedDay == day.dayNumber
                                ) {
                                    print("DEBUG: Day \(day.dayNumber) selected")
                                    selectedDay = day.dayNumber
                                }
                            }
                        }
                        .padding()
                    }
                    .background(Color(.systemGray6))
                    .onAppear {
                        // Validiere den ausgewählten Tag erst nach der Darstellung
                        let validDayNumbers = dailyPlans.map { $0.dayNumber }
                        if !validDayNumbers.contains(selectedDay) {
                            // Wähle den ersten Tag, falls der aktuelle nicht gültig ist
                            if let firstDay = dailyPlans.first {
                                print("DEBUG: Selected day \(selectedDay) not valid, switching to day \(firstDay.dayNumber)")
                                selectedDay = firstDay.dayNumber
                            }
                        }
                    }
                    
                    if let dayPlan = dailyPlans.first(where: { $0.dayNumber == selectedDay }) {
                        List {
                            ForEach(dayPlan.activities) { activity in
                                Button(action: {
                                    if let onActivitySelected = onActivitySelected {
                                        onActivitySelected(activity)
                                    }
                                }) {
                                    VStack(alignment: .leading, spacing: 5) {
                                        HStack {
                                            Text(activity.time)
                                                .font(.headline)
                                                .foregroundColor(.blue)
                                            
                                            Spacer()
                                            
                                            Text(translateCategory(activity.category))
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
                                            .lineLimit(2)
                                        
                                        HStack {
                                            Image(systemName: "mappin.circle.fill")
                                                .foregroundColor(.red)
                                            Text(activity.location)
                                                .font(.subheadline)
                                                .foregroundColor(.primary)
                                            
                                            Spacer()
                                            
                                            Image(systemName: "map")
                                                .foregroundColor(.blue)
                                                .padding(.trailing, 4)
                                        }
                                        .padding(.top, 3)
                                    }
                                }
                                .padding(.vertical, 8)
                                .buttonStyle(PlainButtonStyle()) // Damit die Listenzeile nicht standardmäßig "blau" wird
                            }
                            
                            if let recommendations = travelPlan.recommendations {
                                Section(header: Text(languageManager.localize("recommendations"))) {
                                    if !recommendations.food.isEmpty {
                                        DisclosureGroup(languageManager.localize("food_drinks")) {
                                            ForEach(recommendations.food, id: \.self) { food in
                                                Label(food, systemImage: "fork.knife")
                                            }
                                        }
                                    }
                                    
                                    if !recommendations.transport.isEmpty {
                                        DisclosureGroup(languageManager.localize("transport")) {
                                            ForEach(recommendations.transport, id: \.self) { tip in
                                                Label(tip, systemImage: "tram.fill")
                                            }
                                        }
                                    }
                                    
                                    if !recommendations.tips.isEmpty {
                                        DisclosureGroup(languageManager.localize("useful_tips")) {
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
                        Text(languageManager.localize("no_activities_found"))
                            .onAppear {
                                print("DEBUG: No day plan found for day \(selectedDay)")
                                print("DEBUG: Available day numbers: \(dailyPlans.map { $0.dayNumber })")
                            }
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
                    Text(languageManager.localize("no_plan_data"))
                        .onAppear {
                            print("DEBUG: No travel plan data available at all")
                        }
                    Spacer()
                }
            }
            .navigationBarItems(trailing: Button(languageManager.localize("done")) {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    func formatDateShort(_ dateString: String) -> String {
        // Verwende benutzerdefinierte Formatierung für kurze Datumsanzeige in Tabs
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        
        guard let date = inputFormatter.date(from: dateString) else {
            return dateString
        }
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "dd.MM."
        return outputFormatter.string(from: date)
    }
    
    func formatDateString(_ dateString: String) -> String {
        // Verwende die Datumsformateinstellung des Benutzers
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        
        guard let date = inputFormatter.date(from: dateString) else {
            return dateString
        }
        
        let outputFormatter = DateFormatter()
        
        let dateFormat = AppSettings.DateFormat(rawValue: settings.dateFormat) ?? .system
        switch dateFormat {
        case .system:
            outputFormatter.dateStyle = .medium
            outputFormatter.timeStyle = .none
        case .european:
            outputFormatter.dateFormat = "dd.MM.yyyy"
        case .american:
            outputFormatter.dateFormat = "MM/dd/yyyy"
        case .iso:
            outputFormatter.dateFormat = "yyyy-MM-dd"
        }
        
        return outputFormatter.string(from: date)
    }
    
    func parseDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }
    
    // Funktion zur Formatierung der Kategorienamen (nur erster Buchstabe groß)
    func translateCategory(_ category: String) -> String {
        // Erster Buchstabe groß, Rest unverändert
        guard let firstChar = category.first else { return category }
        return String(firstChar).uppercased() + category.dropFirst()
    }
    
    func categoryColor(for category: String) -> Color {
        let lowercasedCategory = category.lowercased()
        
        // Kunst/Art-Kategorien (Lila)
        if ["kunst", "art", "arte"].contains(where: lowercasedCategory.contains) {
            return Color.purple
        }
        
        // Geschichte/History-Kategorien (Orange)
        if ["geschichte", "history", "histoire", "historia", "storia"].contains(where: lowercasedCategory.contains) {
            return Color.orange
        }
        
        // Architektur/Architecture-Kategorien (Blau)
        if ["architektur", "architecture", "arquitectura", "architettura"].contains(where: lowercasedCategory.contains) {
            return Color.blue
        }
        
        // Gastronomie/Gastronomy-Kategorien (Rot)
        if ["gastronomie", "gastronomy", "gastronomía", "gastronomia", "essen", "food", "cuisine"].contains(where: lowercasedCategory.contains) {
            return Color.red
        }
        
        // Shopping-Kategorien (Pink)
        if ["shopping", "einkaufen", "compras", "achats"].contains(where: lowercasedCategory.contains) {
            return Color.pink
        }
        
        // Nachtleben/Nightlife-Kategorien (Indigo)
        if ["nachtleben", "nightlife", "vida nocturna", "vie nocturne", "vita notturna"].contains(where: lowercasedCategory.contains) {
            return Color.indigo
        }
        
        // Kultur/Culture-Kategorien (Teal)
        if ["kultur", "culture", "cultura"].contains(where: lowercasedCategory.contains) {
            return Color.teal
        }
        
        // Sightseeing-Kategorien (Grün)
        if ["sightseeing", "besichtigung", "visites", "visitas", "visite"].contains(where: lowercasedCategory.contains) {
            return Color.green
        }
        
        // Standard für unbekannte Kategorien
        return Color.gray
    }
}