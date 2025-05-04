//
//  PlansView.swift
//  CityTailor
//
//  Created by Alex Polan on 5/4/25.
//

import SwiftUI

// Reisepläne Ansicht
struct PlansView: View {
    @State private var savedPlans: [TravelPlan] = []
    
    var body: some View {
        NavigationView {
            List {
                if savedPlans.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "map")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("Noch keine Reisepläne gespeichert")
                            .font(.headline)
                        
                        Text("Ihre gespeicherten Reisepläne erscheinen hier")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(savedPlans) { plan in
                        VStack(alignment: .leading) {
                            Text(plan.location)
                                .font(.headline)
                            
                            Text("\(plan.period.startDate) - \(plan.period.endDate)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Meine Reisepläne")
        }
    }
}