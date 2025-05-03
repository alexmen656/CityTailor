//
//  ContentView.swift
//  CityTailor
//
//  Created by Alex Polan on 5/2/25.
//

import SwiftUI
import CoreData
import MapKit
import Combine

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 52.520008, longitude: 13.404954), // Berlin as default
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var searchText = ""
    @State private var isSearching = false
    @StateObject private var searchCompleter = SearchCompleter()
    @State private var showSuggestions = false
    @State private var showSettings = false
    
    @State private var selectedLocation: String = ""
    @State private var showDateSelectionView = false

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>

    var body: some View {
        ZStack(alignment: .top) {
            MapView(region: $region)
                .edgesIgnoringSafeArea(.all)
            
            VStack(alignment: .leading, spacing: 0) {
                SearchBar(
                    text: $searchText,
                    isSearching: $isSearching,
                    searchAction: searchLocation,
                    showSettings: $showSettings
                )
                .padding(.horizontal)
                .padding(.top, 5)
                .onChange(of: searchText) { newValue in
                    searchCompleter.searchTerm = newValue
                    showSuggestions = !newValue.isEmpty
                }
                
                if showSuggestions && !searchCompleter.suggestions.isEmpty {
                    List {
                        ForEach(searchCompleter.suggestions, id: \.self) { suggestion in
                            Text(suggestion)
                                .padding(.vertical, 8)
                                .onTapGesture {
                                    searchText = suggestion
                                    showSuggestions = false
                                    searchLocation()
                                }
                        }
                    }
                    .frame(maxHeight: 200)
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    .padding(.horizontal)
                }
                
                Spacer()
            }
        }
        .onTapGesture {
            // Dismiss suggestions when tapping outside
            showSuggestions = false
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showDateSelectionView) {
            DateSelectionView(locationName: selectedLocation)
        }
    }
    
    func searchLocation() {
        guard !searchText.isEmpty else { return }
        
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = searchText
        
        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            guard let response = response, error == nil else {
                print("Error searching for \(searchText): \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            if let firstMapItem = response.mapItems.first {
                withAnimation {
                    self.region = MKCoordinateRegion(
                        center: firstMapItem.placemark.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                    )
                    
                    self.selectedLocation = firstMapItem.name ?? searchText
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.showDateSelectionView = true
                    }
                }
            }
        }
    }

    struct MapView: UIViewRepresentable {
        @Binding var region: MKCoordinateRegion
        
        func makeUIView(context: Context) -> MKMapView {
            let mapView = MKMapView()
            mapView.delegate = context.coordinator
            return mapView
        }
        
        func updateUIView(_ view: MKMapView, context: Context) {
            view.setRegion(region, animated: true)
        }
        
        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }
        
        class Coordinator: NSObject, MKMapViewDelegate {
            var parent: MapView
            
            init(_ parent: MapView) {
                self.parent = parent
            }
            
            func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
                parent.region = mapView.region
            }
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    @Binding var isSearching: Bool
    var searchAction: () -> Void
    @Binding var showSettings: Bool
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Stadt eingeben...", text: $text, onCommit: {
                    searchAction()
                })
                .foregroundColor(.primary)
                
                if !text.isEmpty {
                    Button(action: {
                        self.text = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
                
                Button(action: {
                    self.showSettings = true
                }) {
                    Image(systemName: "gear")
                        .foregroundColor(.gray)
                        .padding(.trailing, 8)
                }
            }
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            if isSearching {
                Button("Abbrechen") {
                    self.text = ""
                    self.isSearching = false
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .foregroundColor(.blue)
                .transition(.move(edge: .trailing))
                .animation(.default)
            }
        }
    }
}

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var showInterestsView = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Karteneinstellungen")) {
                    Toggle("Verkehr anzeigen", isOn: .constant(false))
                    Toggle("Points of Interest anzeigen", isOn: .constant(true))
                }
                
                Section(header: Text("Erscheinungsbild")) {
                    Picker("Kartenstil", selection: .constant(0)) {
                        Text("Standard").tag(0)
                        Text("Satellit").tag(1)
                        Text("Hybrid").tag(2)
                    }
                    
                    Toggle("Nachtmodus", isOn: .constant(false))
                }
                
                Section(header: Text("Persönliche Einstellungen")) {
                    Button(action: {
                        showInterestsView = true
                    }) {
                        HStack {
                            Text("Interessen")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                      }
                    }
                }
                
                Section(header: Text("Allgemein")) {
                    Toggle("Standort verwenden", isOn: .constant(true))
                    Toggle("Automatische Updates", isOn: .constant(true))
                }
                
                Section {
                    Button(action: {
                        // Hier könnte ein Reset aller Einstellungen erfolgen
                    }) {
                        Text("Auf Standardwerte zurücksetzen")
                            .foregroundColor(.red)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Einstellungen")
            .navigationBarItems(trailing: Button("Fertig") {
                presentationMode.wrappedValue.dismiss()
            })
            .sheet(isPresented: $showInterestsView) {
                InterestsView()
            }
        }
    }
}

struct InterestsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var interests: [Interest] = loadInterests()
    
    var body: some View {
        NavigationView {
            List {
                ForEach(interests.indices, id: \.self) { index in
                    VStack(alignment: .leading) {
                        Text(interests[index].name)
                            .font(.headline)
                        
                        HStack {
                            Text("1")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Slider(value: $interests[index].rating, in: 1...10, step: 1)
                            
                            Text("10")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Text("Bewertung: \(Int(interests[index].rating))")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .padding(.vertical, 5)
                }
            }
            .navigationTitle("Interessen")
            .navigationBarItems(trailing: Button("Fertig") {
                saveInterests()
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    func saveInterests() {
        let interestDicts = interests.map { ["name": $0.name, "rating": $0.rating] }
        UserDefaults.standard.set(interestDicts, forKey: "userInterests")
    }
    
    static func loadInterests() -> [Interest] {
        if let savedInterests = UserDefaults.standard.array(forKey: "userInterests") as? [[String: Any]] {
            return savedInterests.compactMap { dict in
                guard let name = dict["name"] as? String,
                      let rating = dict["rating"] as? Double else {
                    return nil
                }
                return Interest(name: name, rating: rating)
            }
        } else {
            return [
                Interest(name: "Kunst", rating: 5),
                Interest(name: "Architektur", rating: 5),
                Interest(name: "Geschichte", rating: 5),
                Interest(name: "Natur", rating: 5),
                Interest(name: "Gastronomie", rating: 5),
                Interest(name: "Shopping", rating: 5),
                Interest(name: "Nachtleben", rating: 5),
                Interest(name: "Sport", rating: 5),
                Interest(name: "Technologie", rating: 5),
                Interest(name: "Musik", rating: 5),
                Interest(name: "Reisen", rating: 5)
            ]
        }
    }
}

struct Interest: Identifiable {
    var id = UUID()
    var name: String
    var rating: Double
}

struct DateSelectionView: View {
    @Environment(\.presentationMode) var presentationMode
    let locationName: String
    
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(3 * 24 * 60 * 60)
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    @State private var travelPlan: TravelPlan?
    @State private var showTravelPlan = false
    
    var tripLengthInDays: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Reiseziel")) {
                    HStack {
                        Text("Ort:")
                        Spacer()
                        Text(locationName)
                            .bold()
                    }
                }
                
                Section(header: Text("Reisezeitraum")) {
                    DatePicker("Anreisedatum", selection: $startDate, displayedComponents: .date)
                    
                    DatePicker("Abreisedatum", selection: $endDate, in: startDate..., displayedComponents: .date)
                    
                    HStack {
                        Text("Aufenthaltsdauer:")
                        Spacer()
                        Text("\(tripLengthInDays) \(tripLengthInDays == 1 ? "Tag" : "Tage")")
                            .bold()
                    }
                }
                
                Section {
                    Button(action: {
                        sendDataToBackend()
                    }) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("An Backend senden")
                                .frame(maxWidth: .infinity)
                                .bold()
                        }
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .disabled(isLoading)
                }
            }
            .navigationTitle("Reiseplanung")
            .navigationBarItems(trailing: Button("Schließen") {
                presentationMode.wrappedValue.dismiss()
            })
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Backend-Benachrichtigung"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .sheet(isPresented: $showTravelPlan) {
                if let plan = travelPlan {
                    TravelPlanView(travelPlan: plan)
                }
            }
        }
    }
    
    func sendDataToBackend() {
        isLoading = true
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let tripData: [String: Any] = [
            "location": locationName,
            "startDate": dateFormatter.string(from: startDate),
            "endDate": dateFormatter.string(from: endDate),
            "durationInDays": tripLengthInDays
        ]
        
        guard let url = URL(string: "http://192.168.178.149:4040/api/trips") else {
            self.alertMessage = "Ungültige URL"
            self.showAlert = true
            self.isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: tripData)
            request.httpBody = jsonData
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        self.alertMessage = "Fehler: \(error.localizedDescription)"
                        self.showAlert = true
                        return
                    }
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        self.alertMessage = "Ungültige Serverantwort"
                        self.showAlert = true
                        return
                    }
                    
                    if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                        if let data = data {
                            do {
                                let decoder = JSONDecoder()
                                let backendResponse = try decoder.decode(BackendResponse.self, from: data)
                                self.travelPlan = backendResponse.data
                                self.showTravelPlan = true
                            } catch {
                                print("Fehler beim Dekodieren: \(error)")
                                self.alertMessage = "Fehler beim Verarbeiten der Daten: \(error.localizedDescription)"
                                self.showAlert = true
                            }
                        }
                    } else {
                        self.alertMessage = "Server-Fehler: Status \(httpResponse.statusCode)"
                        self.showAlert = true
                    }
                }
            }.resume()
        } catch {
            self.isLoading = false
            self.alertMessage = "Fehler beim Erstellen der JSON-Daten: \(error.localizedDescription)"
            self.showAlert = true
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

class SearchCompleter: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var searchTerm = ""
    @Published var suggestions: [String] = []
    
    private var completer: MKLocalSearchCompleter
    
    override init() {
        completer = MKLocalSearchCompleter()
        super.init()
        completer.delegate = self
        completer.resultTypes = .address
        
        $searchTerm
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] term in
                guard let self = self else { return }
                
                if term.isEmpty {
                    self.suggestions = []
                    return
                }
                
                self.completer.queryFragment = term
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        suggestions = completer.results.map { $0.title }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Search completer error: \(error.localizedDescription)")
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
