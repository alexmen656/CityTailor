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
    @EnvironmentObject private var settings: AppSettings
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
    
    @State private var mapAnnotations: [MapAnnotation] = []
    @State private var selectedAnnotation: MapAnnotation? = nil
    @State private var travelPlan: TravelPlan? = nil
    @State private var showActivityDetails = false
    @State private var selectedActivity: Activity? = nil
    @State private var selectedDayNumber: Int = 1
    @State private var showSaveFeedback = false

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>

    var body: some View {
        TabView {
            mainView
                .tabItem {
                    Image(systemName: "map")
                    Text("Karte")
                }
            
            PlansView()
                .tabItem {
                    Image(systemName: "map.fill")
                    Text("Pläne")
                }
            
     ///       FavoritesView()
        //        .tabItem {
          //          Image(systemName: "heart")
            //        Text("Favoriten")
              //  }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Einstellungen")
                }
        }
        .onAppear {
            // TabBar mit weißem Hintergrund
            UITabBar.appearance().backgroundColor = .white
        }
    }
    
    // Hauptinhalt der App in einer Variable ausgelagert für bessere Lesbarkeit
    var mainView: some View {
        ZStack(alignment: .top) {
            MapView(
                region: $region,
                annotations: mapAnnotations,
                selectedAnnotation: selectedAnnotation
            )
            .environmentObject(settings)
            .edgesIgnoringSafeArea(.all)
            .contentShape(Rectangle())
            .onTapGesture {
                if !isSearching {
                    showSuggestions = false
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
            
            VStack(alignment: .leading, spacing: 0) {
                SearchBar(
                    text: $searchText,
                    isSearching: $isSearching,
                    searchAction: searchLocation,
                    showSettings: $showSettings,
                    showSuggestions: $showSuggestions
                )
                .padding(.horizontal)
                .padding(.top, 5)
                .zIndex(1) 
                .onChange(of: searchText) { newValue in
                    searchCompleter.searchTerm = newValue
                }
                
                if !searchText.isEmpty && !searchCompleter.suggestions.isEmpty {
                    SearchSuggestionsView(
                        suggestions: searchCompleter.suggestions,
                        onSelect: { suggestion in
                            searchText = suggestion
                            showSuggestions = false
                            searchLocation()
                        }
                    )
                }
                
                if let plan = travelPlan, let dailyPlans = plan.dailyPlans, !dailyPlans.isEmpty {
                    DayButtonsView(
                        dailyPlans: dailyPlans,
                        selectedDayNumber: $selectedDayNumber,
                        onDaySelected: { dayNumber in
                            if let dailyPlans = plan.dailyPlans {
                                updateMapForSelectedDay(dailyPlans: dailyPlans, in: plan.location)
                            }
                        },
                        formatDateShort: formatDateShort
                    )
                }
                
                Spacer()
                
                if let plan = travelPlan {
                    TravelPlanSummaryView(
                        plan: plan,
                        onTap: {
                            showDateSelectionView = true
                        }
                    )
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showDateSelectionView, onDismiss: {
            if let plan = self.travelPlan, let dailyPlans = plan.dailyPlans {
                self.selectedDayNumber = 1
                updateMapForSelectedDay(dailyPlans: dailyPlans, in: plan.location)
            }
        }) {
            if let plan = self.travelPlan {
                TravelPlanView(
                    travelPlan: plan,
                    selectedDay: $selectedDayNumber,
                    onActivitySelected: { activity in
                        self.selectedActivity = activity
                        self.showActivityDetails = true
                        
                        if let annotation = self.mapAnnotations.first(where: { $0.title == activity.title }) {
                            self.selectedAnnotation = annotation
                            self.region = MKCoordinateRegion(
                                center: annotation.coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                            )
                        }
                    }
                )
            } else {
                DateSelectionView(
                    locationName: selectedLocation,
                    onTravelPlanReceived: { plan in
                        self.travelPlan = plan
                        TravelPlanStore.shared.saveTravelPlan(plan, context: viewContext)
                        self.showSaveFeedback = true
                    }
                )
            }
        }
        .sheet(isPresented: $showActivityDetails) {
            if let activity = selectedActivity {
                ActivityDetailView(activity: activity)
            }
        }
        .alert(isPresented: $showSaveFeedback) {
            Alert(title: Text("Reiseplan gespeichert"), message: Text("Ihr Reiseplan wurde erfolgreich gespeichert."), dismissButton: .default(Text("OK")))
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
                    

                    self.travelPlan = nil
                    self.mapAnnotations = []
                    
                    self.showSuggestions = false
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.showDateSelectionView = true
                    }
                }
            }
        }
    }
    
    func updateMapForSelectedDay(dailyPlans: [DailyPlan], in city: String) {
        guard let selectedDayPlan = dailyPlans.first(where: { $0.dayNumber == selectedDayNumber }) else {
            self.mapAnnotations = []
            return
        }
        
        searchText = ""
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        GeocodingService.batchGeocode(activities: selectedDayPlan.activities, city: city) { annotations in
            self.mapAnnotations = annotations
            
            if let firstAnnotation = annotations.first {
                self.region = MKCoordinateRegion(
                    center: firstAnnotation.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
                )
            }
        }
    }
    
    func formatDateShort(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        if let date = formatter.date(from: dateString) {
            formatter.dateFormat = "dd.MM."
            return formatter.string(from: date)
        }
        return dateString
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

    private func saveTravelPlan(_ plan: TravelPlan) {
        TravelPlanStore.shared.saveTravelPlan(plan, context: viewContext)
        showSaveFeedback = true
    }
}

// SearchSuggestionsView als separater Komponente
struct SearchSuggestionsView: View {
    let suggestions: [String]
    let onSelect: (String) -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(zip(suggestions.indices, suggestions)), id: \.0) { index, suggestion in
                    Button(action: {
                        onSelect(suggestion)
                    }) {
                        HStack(alignment: .center) {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 20))
                                .padding(.leading, 8)
                            
                            Text(suggestion)
                                .foregroundColor(.primary)
                                .padding(.vertical, 12)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Image(systemName: "arrow.forward.circle")
                                .foregroundColor(.gray)
                                .font(.system(size: 16))
                                .opacity(0.7)
                                .padding(.trailing, 8)
                        }
                    }
                    .background(
                        Rectangle()
                            .fill(Color(UIColor.systemBackground))
                            .cornerRadius(0)
                    )
                    
                    if index < suggestions.count - 1 {
                        Divider()
                            .padding(.leading, 40)
                    }
                }
            }
            .background(Color(UIColor.systemBackground))
        }
        .frame(maxHeight: 250)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(10, corners: [.bottomLeft, [.bottomRight]])
        .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
        .padding(.top, -8)
    }
}

// DayButtonsView als einfache Komponente mit festen Größen
struct DayButtonsView: View {
    let dailyPlans: [DailyPlan]
    @Binding var selectedDayNumber: Int
    let onDaySelected: (Int) -> Void
    let formatDateShort: (String) -> String
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(dailyPlans) { day in
                    DayButton(
                        dayNumber: day.dayNumber,
                        date: formatDateShort(day.date),
                        isSelected: selectedDayNumber == day.dayNumber
                    ) {
                        selectedDayNumber = day.dayNumber
                        onDaySelected(day.dayNumber)
                    }
                    .frame(width: 72)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
        .frame(height: 50)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.top, 5)
    }
}

// TravelPlanSummaryView als separate Komponente
struct TravelPlanSummaryView: View {
    let plan: TravelPlan
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Reiseplan für \(plan.location)")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("\(plan.period.startDate) - \(plan.period.endDate)")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.vertical, 8)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue)
            )
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
        .cornerRadius(10, corners: [.topLeft, .topRight])
        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: -3)
    }
}

struct ActivityDetailView: View {
    let activity: Activity
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
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
                        .font(.title)
                        .bold()
                    
                    Text(activity.description)
                        .padding(.top, 2)
                    
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.red)
                        Text(activity.location)
                    }
                    .padding(.top, 8)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Aktivität")
            .navigationBarItems(trailing: Button("Fertig") {
                presentationMode.wrappedValue.dismiss()
            })
        }
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

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
