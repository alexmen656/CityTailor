import Foundation
import MapKit
import Combine

class GeocodingService {
    
    static func searchForPointOfInterest(name: String, city: String, completion: @escaping (MKMapItem?, CLLocationCoordinate2D?) -> Void) {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = "\(name), \(city)"
        searchRequest.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            span: MKCoordinateSpan(latitudeDelta: 180, longitudeDelta: 180)
        )
        
        print("🔍 DEBUG: Searching for POI: \(name) in \(city)")
        
        let search = MKLocalSearch(request: searchRequest)
        search.start { (response, error) in
            guard error == nil, let response = response else {
                print("❌ DEBUG: POI search error for \(name): \(error?.localizedDescription ?? "Unknown error")")
                completion(nil, nil)
                return
            }
            
            if let firstItem = response.mapItems.first {
                let coordinate = firstItem.placemark.coordinate
                print("🏬 DEBUG: Found Apple Maps POI for \(name) → Lat: \(coordinate.latitude), Lng: \(coordinate.longitude)")
                completion(firstItem, coordinate)
                return
            } else {
                print("🔍 DEBUG: No Apple Maps POI found for \(name)")
                completion(nil, nil)
            }
        }
    }
    
    static func geocodeAddress(from address: String, inCity city: String, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        let geocoder = CLGeocoder()
        let fullAddress = "\(address), \(city)"
        
        print("📍 DEBUG: Starting geocoding for address: \(fullAddress)")
        
        geocoder.geocodeAddressString(fullAddress) { (placemarks, error) in
            guard error == nil else {
                print("❌ DEBUG: Geocoding error for \(fullAddress): \(error!.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let placemark = placemarks?.first, let location = placemark.location else {
                print("❌ DEBUG: No coordinates found for address: \(fullAddress)")
                completion(nil)
                return
            }
            
            let coordinate = location.coordinate
            print("✅ DEBUG: Successfully geocoded \(fullAddress) → Lat: \(coordinate.latitude), Lng: \(coordinate.longitude)")
            
            completion(coordinate)
        }
    }
    
    static func batchGeocode(activities: [Activity], city: String, completion: @escaping ([MapAnnotation]) -> Void) {
        var annotations: [MapAnnotation] = []
        var appleMapsItems: [String: MKMapItem] = [:]  
        let group = DispatchGroup()
        
        print("🗺️ DEBUG: Starting batch geocoding for \(activities.count) activities in \(city)")
        
        for activity in activities {
            group.enter()
            
            print("📌 DEBUG: Processing activity: \(activity.title) with address: \(activity.mapAddress)")
            
            
            searchForPointOfInterest(name: activity.title, city: city) { (mapItem, coordinate) in
                if let mapItem = mapItem, let coordinate = coordinate {
                    
                    appleMapsItems[activity.title] = mapItem
                    let annotation = MapAnnotation(
                        title: activity.title,
                        subtitle: activity.time,
                        coordinate: coordinate,
                        activityInfo: activity,
                        useAppleMapsStyle: true,
                        mapItem: mapItem
                    )
                    annotations.append(annotation)
                    print("🍎 DEBUG: Using Apple Maps POI for \(activity.title)")
                    group.leave()
                } else {
                    
                    geocodeAddress(from: activity.mapAddress, inCity: city) { coordinate in
                        if let coordinate = coordinate {
                            let annotation = MapAnnotation(
                                title: activity.title,
                                subtitle: activity.time,
                                coordinate: coordinate,
                                activityInfo: activity
                            )
                            annotations.append(annotation)
                            print("📍 DEBUG: Created custom annotation for \(activity.title) at coordinates: \(coordinate.latitude), \(coordinate.longitude)")
                        } else {
                            print("⚠️ DEBUG: Failed to create annotation for \(activity.title) - no coordinates returned")
                        }
                        group.leave()
                    }
                }
            }
        }
        
        group.notify(queue: .main) {
            let appleMapsCount = annotations.filter { $0.useAppleMapsStyle }.count
            print("🏁 DEBUG: Batch geocoding completed. Created \(annotations.count) annotations (\(appleMapsCount) Apple Maps POIs, \(annotations.count - appleMapsCount) custom) out of \(activities.count) activities")
            completion(annotations)
        }
    }
}
