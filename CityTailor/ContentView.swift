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
                    showSettings: $showSettings,
                    showSuggestions: $showSuggestions
                )
                .padding(.horizontal)
                .padding(.top, 5)
                .zIndex(1) // Sorgt dafür, dass die SearchBar über den Ergebnissen liegt
                .onChange(of: searchText) { newValue in
                    searchCompleter.searchTerm = newValue
                    showSuggestions = !newValue.isEmpty
                }
                
                if showSuggestions && !searchCompleter.suggestions.isEmpty {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(Array(zip(searchCompleter.suggestions.indices, searchCompleter.suggestions)), id: \.0) { index, suggestion in
                                Button(action: {
                                    searchText = suggestion
                                    showSuggestions = false
                                    searchLocation()
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
                                
                                if index < searchCompleter.suggestions.count - 1 {
                                    Divider()
                                        .padding(.leading, 40)
                                }
                            }
                        }
                        .background(Color(UIColor.systemBackground))
                    }
                    .frame(maxHeight: 250)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(10, corners: [.bottomLeft, .bottomRight])
                    .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                    .padding(.horizontal)
                    .padding(.top, -8) // Für einen nahtlosen Übergang
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

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
