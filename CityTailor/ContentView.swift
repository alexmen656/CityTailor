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
                }
            }
        }
    }

    // MapView struct using UIViewRepresentable to show full screen MapKit view
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
        // Umwandeln der Interessen in ein speicherbares Format
        let interestDicts = interests.map { ["name": $0.name, "rating": $0.rating] }
        UserDefaults.standard.set(interestDicts, forKey: "userInterests")
    }
    
    static func loadInterests() -> [Interest] {
        // Laden der Interessen aus UserDefaults oder Verwendung von Standardwerten
        if let savedInterests = UserDefaults.standard.array(forKey: "userInterests") as? [[String: Any]] {
            return savedInterests.compactMap { dict in
                guard let name = dict["name"] as? String,
                      let rating = dict["rating"] as? Double else {
                    return nil
                }
                return Interest(name: name, rating: rating)
            }
        } else {
            // Standard-Interessen zurückgeben, wenn keine gespeichert wurden
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
                Interest(name: "Musik", rating: 5)
            ]
        }
    }
}

struct Interest: Identifiable {
    var id = UUID()
    var name: String
    var rating: Double
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
        
        // Start observing searchTerm changes
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
        // Get suggestions and publish them
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
