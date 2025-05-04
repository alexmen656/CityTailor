//
//  PlansView.swift
//  CityTailor
//
//  Created by Alex Polan on 5/4/25.
//

import SwiftUI

// Reisepläne Ansicht
struct PlansView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var savedPlans: [SavedTravelPlanViewModel] = []
    @State private var showTravelPlanDetail = false
    @State private var selectedTravelPlan: TravelPlan? = nil
    @State private var selectedDayNumber = 1

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
                        Button(action: {
                            selectedTravelPlan = plan.plan
                            showTravelPlanDetail = true
                        }) {
                            VStack(alignment: .leading, spacing: 5) {
                                HStack {
                                    Text(plan.location)
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    Text(formatDate(plan.creationDate))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                HStack {
                                    Text("\(plan.startDate) - \(plan.endDate)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .onDelete(perform: deletePlans)
                }
            }
            .navigationTitle("Meine Reisepläne")
            .onAppear {
                loadSavedPlans()
            }
        }
        .sheet(isPresented: $showTravelPlanDetail) {
            if let plan = selectedTravelPlan {
                TravelPlanView(
                    travelPlan: plan,
                    selectedDay: $selectedDayNumber
                )
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func loadSavedPlans() {
        self.savedPlans = TravelPlanStore.shared.getTravelPlans(context: viewContext)
    }
    
    private func deletePlans(at offsets: IndexSet) {
        withAnimation {
            offsets.forEach { index in
                let plan = savedPlans[index]
                TravelPlanStore.shared.deleteTravelPlan(withId: plan.id, context: viewContext)
            }
            
            // Reload saved plans after deletion
            loadSavedPlans()
        }
    }
}