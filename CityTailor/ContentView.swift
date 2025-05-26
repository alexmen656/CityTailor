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
import CoreLocation

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var languageManager: LanguageManager
    @EnvironmentObject private var storeManager: StoreManager
    @StateObject private var locationManager = LocationManager()
    
    @State private var initialLocationSet = false
    
    @State private var region = MKCoordinateRegion(
        // Default to Berlin, will be updated with user location when available
        center: CLLocationCoordinate2D(latitude: 52.520008, longitude: 13.404954),
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
    @StateObject private var tabSelection = TabSelection()
    
    // City struct to store city name and emoji
    struct City: Identifiable, Hashable {
        let id = UUID()
        let name: String
        let emoji: String
        
        static let paris = City(name: "Paris", emoji: "🗼")
        static let london = City(name: "London", emoji: "🎡")
        static let newYork = City(name: "New York", emoji: "🗽")
        static let tokyo = City(name: "Tokyo", emoji: "🎌")
        static let rome = City(name: "Rome", emoji: "🏛️")
        static let barcelona = City(name: "Barcelona", emoji: "🎨")//⛪
        static let berlin = City(name: "Berlin", emoji: "🧸")
        static let amsterdam = City(name: "Amsterdam", emoji: "🚲")
        static let vienna = City(name: "Vienna", emoji: "🎼")//🎭
        static let prague = City(name: "Prague", emoji: "🕰️")
    }
    
    private let popularCities = [
        City.paris,
        City.london,
        City.newYork,
        City.tokyo,
        City.rome,
        City.barcelona,
        City.berlin,
        City.amsterdam,
        City.vienna,
        City.prague
    ]

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                if tabSelection.selectedTab == 0 {
                    PlansView()
                        .padding(.bottom, 70)
                } else if tabSelection.selectedTab == 1 {
                    DiscoverView()
                        .padding(.bottom, 70)
                } else if tabSelection.selectedTab == 2 {
                    mainView
                } else if tabSelection.selectedTab == 3 {
                    MediaView()
                        .padding(.bottom, 70)
                } else if tabSelection.selectedTab == 4 {
                    SettingsView(isModal: false)
                        .padding(.bottom, 70)
                }
            }
            
            VStack {
                Spacer()
                CustomTabBar(selectedTab: $tabSelection.selectedTab)
                    .edgesIgnoringSafeArea(.bottom)
            }
            .ignoresSafeArea(.keyboard)
        }
        .edgesIgnoringSafeArea(.bottom)
        .onAppear {
            // Update the map region when user location becomes available
            if let location = locationManager.location {
                region = MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                )
                initialLocationSet = true
            }
        }
        .onChange(of: locationManager.location) { newLocation in
            if let location = newLocation, !initialLocationSet && travelPlan == nil && mapAnnotations.isEmpty {
                region = MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                )
                initialLocationSet = true
            }
        }
    }
    
    var mainView: some View {
        ZStack(alignment: .top) {
            MapView(
                region: $region,
                annotations: mapAnnotations,
                selectedAnnotation: selectedAnnotation,
                languageManager: languageManager
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
                
                
                if searchText.isEmpty && travelPlan == nil {
                    SuggestedCityTags(cities: popularCities) { city in
                        searchText = city.name
                        searchLocation()
                    }
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
            .padding(.bottom, 90)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(isModal: true)
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
                        
                        if TravelPlanStore.shared.canSaveTravelPlan(isPremium: storeManager.isPremium(), context: viewContext) {
                            TravelPlanStore.shared.saveTravelPlan(plan, context: viewContext)
                            self.showSaveFeedback = true
                        }
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
            Alert(
                title: Text(languageManager.localize("travel_plan_saved")), 
                message: Text(languageManager.localize("travel_plan_saved_message")), 
                dismissButton: .default(Text(languageManager.localize("ok")))
            )
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
        return DateFormatterUtils.formatDateShort(dateString)
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


struct TravelPlanSummaryView: View {
    let plan: TravelPlan
    let onTap: () -> Void
    @EnvironmentObject private var languageManager: LanguageManager
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(languageManager.localize("travel_plan_for")) \(plan.location)")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("\(DateFormatterUtils.formatDateString(plan.period.startDate)) - \(DateFormatterUtils.formatDateString(plan.period.endDate))")
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
    @EnvironmentObject private var languageManager: LanguageManager
    
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
                        Text(activity.displayAddress)
                    }
                    .padding(.top, 8)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle(languageManager.localize("activity"))
            .navigationBarItems(trailing: Button(languageManager.localize("done")) {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    func categoryColor(for category: String) -> Color {
        switch category.lowercased() {
        case languageManager.localize("art").lowercased(): return Color.purple
        case languageManager.localize("history").lowercased(): return Color.orange
        case languageManager.localize("architecture").lowercased(): return Color.blue
        case languageManager.localize("gastronomy").lowercased(): return Color.red
        case languageManager.localize("shopping").lowercased(): return Color.pink
        case languageManager.localize("nightlife").lowercased(): return Color.indigo
        case languageManager.localize("culture").lowercased(): return Color.teal
        case languageManager.localize("sightseeing").lowercased(): return Color.green
        default: return Color.gray
        }
    }
}

struct SuggestedCityTags: View {
    let cities: [ContentView.City]
    let onSelect: (ContentView.City) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 5) {
                ForEach(cities, id: \.self) { city in
                    Button(action: {
                        onSelect(city)
                    }) {
                        HStack {
                            Text(city.emoji)
                            Text(city.name)
                        }
                        .font(.system(size: 14, weight: .medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(UIColor.systemBackground))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 5)
        }
        .frame(height: 50)
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
