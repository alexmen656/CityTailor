//
//  PlansView.swift
//  CityTailor
//
//  Created by Alex Polan on 5/4/25.
//

import SwiftUI

struct PlansView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var storeManager: StoreManager
    @EnvironmentObject private var languageManager: LanguageManager
    @State private var savedPlans: [SavedTravelPlanViewModel] = []
    @State private var showPremiumView = false
    @State private var remainingFreePlans = 0
    
    var body: some View {
        NavigationView {
            List {
                // Zeige Premium-Upgrade Information an, wenn der Benutzer nicht Premium ist und das Limit erreicht hat
                if !storeManager.isPremium() && remainingFreePlans == 0 && !savedPlans.isEmpty {
                    Section {
                        VStack(alignment: .center, spacing: 10) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.yellow)
                            
                            Text("Limit erreicht: Maximale Anzahl von Reiseplänen (3)")
                                .font(.headline)
                                .multilineTextAlignment(.center)
                            
                            Text("Upgrade auf Premium für unbegrenzte Reisepläne")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            Button(action: {
                                showPremiumView = true
                            }) {
                                Text("Upgrade auf Premium")
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color.blue)
                                    .cornerRadius(8)
                            }
                            .padding(.top, 5)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                    }
                }
                // Zeige Anzahl verbleibender Pläne an, wenn der Benutzer nicht Premium ist
                else if !storeManager.isPremium() && remainingFreePlans > 0 {
                    Section {
                        HStack {
                            Text("Verbleibende kostenlose Reisepläne: \(remainingFreePlans)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button(action: {
                                showPremiumView = true
                            }) {
                                Text("Unbegrenzt")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.yellow)
                                    .foregroundColor(.black)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                
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
                                        
                                        Text(DateFormatterUtils.formatDate(plan.creationDate))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    HStack {
                                        Text("\(DateFormatterUtils.formatDateString(plan.startDate)) - \(DateFormatterUtils.formatDateString(plan.endDate))")
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
            .sheet(isPresented: $showPremiumView) {
                PremiumView()
            }
        }
    }
    
    private func loadSavedPlans() {
        self.savedPlans = TravelPlanStore.shared.getTravelPlans(context: viewContext)
        
        // Aktualisiere die Anzahl der verbleibenden kostenlosen Pläne
        self.remainingFreePlans = TravelPlanStore.shared.getRemainingFreePlans(context: viewContext)
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