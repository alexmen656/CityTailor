import Foundation
import MapKit
import Combine

class GeocodingService {
    
    static func geocodeAddress(from address: String, inCity city: String, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        let geocoder = CLGeocoder()
        let fullAddress = "\(address), \(city)"
        
        geocoder.geocodeAddressString(fullAddress) { (placemarks, error) in
            guard error == nil else {
                print("Geocoding error: \(error!.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let placemark = placemarks?.first, let location = placemark.location else {
                print("Keine Koordinaten gefunden für: \(fullAddress)")
                completion(nil)
                return
            }
            
            completion(location.coordinate)
        }
    }
    
    static func batchGeocode(activities: [Activity], city: String, completion: @escaping ([MapAnnotation]) -> Void) {
        var annotations: [MapAnnotation] = []
        let group = DispatchGroup()
        
        for activity in activities {
            group.enter()
            
            geocodeAddress(from: activity.location, inCity: city) { coordinate in
                if let coordinate = coordinate {
                    let annotation = MapAnnotation(
                        title: activity.title,
                        subtitle: activity.time,
                        coordinate: coordinate,
                        activityInfo: activity
                    )
                    annotations.append(annotation)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(annotations)
        }
    }
}
