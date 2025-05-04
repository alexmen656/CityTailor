//
//  FavoritesView.swift
//  CityTailor
//
//  Created by Alex Polan on 5/4/25.
//

import SwiftUI

// Favoriten Ansicht
struct FavoritesView: View {
    @State private var favorites: [String] = []
    
    var body: some View {
        NavigationView {
            List {
                if favorites.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "heart")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("Keine Favoriten vorhanden")
                            .font(.headline)
                        
                        Text("Gespeicherte Lieblingsorte erscheinen hier")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(favorites, id: \.self) { favorite in
                        Text(favorite)
                    }
                }
            }
            .navigationTitle("Favoriten")
        }
    }
}