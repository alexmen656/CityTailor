import Foundation
import CoreData
import SwiftUI

class TravelPlanStore {
    
    static let shared = TravelPlanStore()
    
    func saveTravelPlan(_ travelPlan: TravelPlan, context: NSManagedObjectContext) {
        // Create a new SavedTravelPlan entity
        let savedPlan = SavedTravelPlan(context: context)
        savedPlan.id = UUID().uuidString
        savedPlan.location = travelPlan.location
        savedPlan.startDate = travelPlan.period.startDate
        savedPlan.endDate = travelPlan.period.endDate
        savedPlan.creationDate = Date()
        
        // Convert TravelPlan to Data for storage
        if let encodedData = try? JSONEncoder().encode(travelPlan) {
            savedPlan.planData = encodedData
        }
        
        // Save the context
        do {
            try context.save()
            print("Travel plan saved successfully: \(travelPlan.location)")
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
                
                // Debug-Ausgabe für die planData
                print("DEBUG: Plan data size: \(planData.count) bytes")
                
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
                    // Versuche, den Fehler detaillierter zu analysieren
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
        } catch {
            print("Failed to delete travel plan: \(error.localizedDescription)")
        }
    }
}

// A view model to represent a saved travel plan
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