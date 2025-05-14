import Foundation
import CoreData
import SwiftUI
import WidgetKit

class TravelPlanStore {
    
    static let shared = TravelPlanStore()
    static let FREE_PLAN_LIMIT = 3
    
    func saveTravelPlan(_ travelPlan: TravelPlan, context: NSManagedObjectContext) {
        
        let savedPlan = SavedTravelPlan(context: context)
        savedPlan.id = UUID().uuidString
        savedPlan.location = travelPlan.location
        savedPlan.startDate = travelPlan.period.startDate
        savedPlan.endDate = travelPlan.period.endDate
        savedPlan.creationDate = Date()
        
        
        if let encodedData = try? JSONEncoder().encode(travelPlan) {
            savedPlan.planData = encodedData
        }
        
        do {
            try context.save()
            print("Travel plan saved successfully: \(travelPlan.location)")
            
            
            updateWidgetData(context: context)
        } catch {
            print("Failed to save travel plan: \(error.localizedDescription)")
        }
    }
    
    func getTravelPlans(context: NSManagedObjectContext) -> [SavedTravelPlanViewModel] {
        let fetchRequest: NSFetchRequest<SavedTravelPlan> = SavedTravelPlan.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        do {
            let savedPlans = try context.fetch(fetchRequest)
            return savedPlans.compactMap { savedPlan in
                guard let location = savedPlan.location,
                      let startDate = savedPlan.startDate,
                      let endDate = savedPlan.endDate,
                      let id = savedPlan.id,
                      let planData = savedPlan.planData else {
                    print("DEBUG: Missing required fields in saved plan")
                    return nil
                }
                
                do {
                    let plan = try JSONDecoder().decode(TravelPlan.self, from: planData)
                    print("DEBUG: Successfully decoded travel plan for \(location)")
                    print("DEBUG: Plan has \(plan.dailyPlans?.count ?? 0) daily plans")
                    return SavedTravelPlanViewModel(
                        id: id,
                        location: location,
                        startDate: startDate,
                        endDate: endDate,
                        creationDate: savedPlan.creationDate ?? Date(),
                        plan: plan,
                        image: nil,
                        imageInfo: plan.image
                    )
                } catch {
                    print("DEBUG: Failed to decode travel plan: \(error.localizedDescription)")
                    
                    if let decodingError = error as? DecodingError {
                        switch decodingError {
                        case .dataCorrupted(let context):
                            print("DEBUG: Data corrupted: \(context.debugDescription)")
                        case .keyNotFound(let key, let context):
                            print("DEBUG: Key '\(key.stringValue)' not found: \(context.debugDescription)")
                        case .typeMismatch(let type, let context):
                            print("DEBUG: Type mismatch for type \(type): \(context.debugDescription)")
                        case .valueNotFound(let type, let context):
                            print("DEBUG: Value of type \(type) not found: \(context.debugDescription)")
                        @unknown default:
                            print("DEBUG: Unknown decoding error")
                        }
                    }
                    return nil
                }
            }
        } catch {
            print("Failed to fetch travel plans: \(error.localizedDescription)")
            return []
        }
    }
    
    func deleteTravelPlan(withId id: String, context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<SavedTravelPlan> = SavedTravelPlan.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)
        
        do {
            let results = try context.fetch(fetchRequest)
            for plan in results {
                context.delete(plan)
            }
            try context.save()
            
            
            updateWidgetData(context: context)
        } catch {
            print("Failed to delete travel plan: \(error.localizedDescription)")
        }
    }
    
    func canSaveTravelPlan(isPremium: Bool, context: NSManagedObjectContext) -> Bool {
        
        if isPremium {
            return true
        }
         
        let fetchRequest: NSFetchRequest<SavedTravelPlan> = SavedTravelPlan.fetchRequest()
        
        do {
            let count = try context.count(for: fetchRequest)
            return count < TravelPlanStore.FREE_PLAN_LIMIT
        } catch {
            print("Error counting travel plans: \(error.localizedDescription)")
            return false
        }
    }
    
    func getNumberOfSavedPlans(context: NSManagedObjectContext) -> Int {
        let fetchRequest: NSFetchRequest<SavedTravelPlan> = SavedTravelPlan.fetchRequest()
        
        do {
            let count = try context.count(for: fetchRequest)
            return count
        } catch {
            print("Error counting travel plans: \(error.localizedDescription)")
            return 0
        }
    }
    
    func getRemainingFreePlans(context: NSManagedObjectContext) -> Int {
        let currentCount = getNumberOfSavedPlans(context: context)
        return max(0, TravelPlanStore.FREE_PLAN_LIMIT - currentCount)
    }
    
    func updateWidgetData(context: NSManagedObjectContext) {
        let plans = getTravelPlans(context: context)
        
        let upcomingPlans = plans.sorted { 
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            guard let date1 = dateFormatter.date(from: $0.startDate),
                  let date2 = dateFormatter.date(from: $1.startDate) else {
                return false
            }
            return date1 < date2
        }
        
        let today = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let filteredPlans = upcomingPlans.filter { 
            guard let startDate = dateFormatter.date(from: $0.startDate) else {
                return false
            }
            return startDate >= today
        }
        
        struct WidgetPlan: Codable {
            let id: String
            let location: String
            let startDate: String
            let endDate: String
        }
        
        let widgetPlans = filteredPlans.prefix(5).map { plan in
            WidgetPlan(
                id: plan.id,
                location: plan.location,
                startDate: plan.startDate,
                endDate: plan.endDate
            )
        }
        
        if let sharedDefaults = UserDefaults(suiteName: "group.com.app.CityTailor") {
            do {
                let encodedData = try JSONEncoder().encode(widgetPlans)
                sharedDefaults.set(encodedData, forKey: "widget_travel_plans")
                print("App: \(widgetPlans.count) Reisepläne für Widget gespeichert")
            } catch {
                print("App: Fehler beim Speichern der Widget-Daten: \(error)")
            }
        }
        
        #if !targetEnvironment(macCatalyst) && !os(macOS)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
    
    func updatePremiumWidgetData(context: NSManagedObjectContext, isPremium: Bool) {
         if let sharedDefaults = UserDefaults(suiteName: "group.com.app.CityTailor") {
            sharedDefaults.set(isPremium, forKey: "is_premium_user")
            sharedDefaults.synchronize()
        } else {
            return
        }
        
        if !isPremium {
            return
        }
        
        let plans = getTravelPlans(context: context)        
        
        struct PremiumWidgetPlan: Codable {
            let id: String
            let location: String
            let startDate: String
            let endDate: String
            let activitiesCount: Int
            let isPremiumTrip: Bool
        }
        
        let premiumPlans = plans.map { plan -> PremiumWidgetPlan in
            
            let activitiesCount = plan.plan.dailyPlans?.reduce(0) { count, day in
                return count + day.activities.count
            } ?? 0
            
            return PremiumWidgetPlan(
                id: plan.id,
                location: plan.location,
                startDate: plan.startDate,
                endDate: plan.endDate,
                activitiesCount: activitiesCount,
                isPremiumTrip: true  
            )
        }
        
        if let sharedDefaults = UserDefaults(suiteName: "group.com.app.CityTailor") {
            do {
                let encodedData = try JSONEncoder().encode(premiumPlans)
                sharedDefaults.set(encodedData, forKey: "premium_widget_plans")
                sharedDefaults.synchronize()
            } catch {
                print("TravelPlanStore: Fehler beim Speichern der Premium-Daten: \(error)")
            }
        }
        
        #if !targetEnvironment(macCatalyst) && !os(macOS)
        WidgetCenter.shared.reloadTimelines(ofKind: "Widget_2")
        #endif
    }
}

struct SavedTravelPlanViewModel: Identifiable {
    let id: String
    let location: String
    let startDate: String
    let endDate: String
    let creationDate: Date
    let plan: TravelPlan
    var image: UIImage?
    var imageInfo: ImageInfo?
}