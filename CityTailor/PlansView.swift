//
//  PlansView.swift
//  CityTailor
//
//  Created by Alex Polan on 5/4/25.
//

import SwiftUI

struct PlansView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var savedPlans: [SavedTravelPlanViewModel] = []

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
                        NavigationLink(destination: PlanDetailLoader(planID: plan.id, context: viewContext)) {
                            HStack(spacing: 9) {
                                if let imageInfo = plan.imageInfo, let imageUrl = URL(string: imageInfo.url) {
                                    AsyncImage(url: imageUrl) { phase in
                                        switch phase {
                                        case .empty:
                                            ProgressView()
                                                .frame(width: 70, height: 70)
                                                .background(Color(.systemGray5))
                                                .cornerRadius(6)
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 70, height: 70)
                                                .cornerRadius(6)
                                        case .failure:
                                            Image(systemName: "photo")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 30, height: 30)
                                                .frame(width: 70, height: 70)
                                                .background(Color(.systemGray5))
                                                .cornerRadius(6)
                                        @unknown default:
                                            EmptyView()
                                        }
                                    }
                                } else {
                                    Image(systemName: "photo")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 30, height: 30)
                                        .frame(width: 70, height: 70)
                                        .background(Color(.systemGray5))
                                        .cornerRadius(6)
                                }
                                
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
                                        Text("\(formatDateString(plan.startDate)) - \(formatDateString(plan.endDate))")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        
                                        Spacer()
                                                                            }
                                    
                                    if let imageInfo = plan.imageInfo {
                                        Text("Foto: \(imageInfo.photographer)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
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
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy" 
        return formatter.string(from: date)
    }
    
    private func formatDateString(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        if let date = formatter.date(from: dateString) {
            formatter.dateFormat = "dd.MM.yyyy"
            return formatter.string(from: date)
        }
        return dateString
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
            
            loadSavedPlans()
        }
    }
}