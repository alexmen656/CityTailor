import Foundation
import MapKit
import Combine

class GeocodingService {
    static var appleMapsItems: [String: MKMapItem] = [:]
    
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
    
    static func getPhotoURLForPlace(place: String, city: String) -> URL? {
        let placeholderBaseURL = "https://source.unsplash.com/300x300/?"
        let searchTerm = "\(place),\(city),landmark"
        
        if let encodedSearchTerm = searchTerm.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: "\(placeholderBaseURL)\(encodedSearchTerm)") {
            return url
        }
        
        return nil
    }
    
    static func getRandomPhotoURL(for category: String) -> URL? {
        var searchTerm: String
        
        switch category.lowercased() {
        case let cat where cat.contains("art") || cat.contains("museum"):
            searchTerm = "art,museum,gallery"
        case let cat where cat.contains("history") || cat.contains("monument"):
            searchTerm = "monument,history,landmark"
        case let cat where cat.contains("architecture"):
            searchTerm = "architecture,building"
        case let cat where cat.contains("gastronomy") || cat.contains("restaurant"):
            searchTerm = "restaurant,food,cuisine"
        case let cat where cat.contains("shopping"):
            searchTerm = "shopping,market,store"
        case let cat where cat.contains("nightlife"):
            searchTerm = "bar,club,nightlife"
        case let cat where cat.contains("culture"):
            searchTerm = "culture,entertainment"
        case let cat where cat.contains("sightseeing"):
            searchTerm = "tourist,attraction,landmark"
        default:
            searchTerm = "landmark,place"
        }
        
        if let encodedSearchTerm = searchTerm.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: "https://source.unsplash.com/300x300/?\(encodedSearchTerm)") {
            return url
        }
        
        return nil
    }
    
    static func batchGeocode(activities: [Activity], city: String, completion: @escaping ([MapAnnotation]) -> Void) {
        var annotations: [MapAnnotation] = []
        let group = DispatchGroup()
        
        print("🗺️ DEBUG: Starting batch geocoding for \(activities.count) activities in \(city)")
        
        for activity in activities {
            group.enter()
            
            print("📌 DEBUG: Processing activity: \(activity.title) with address: \(activity.mapAddress)")
            
            
            searchForPointOfInterest(name: activity.title, city: city) { (mapItem, coordinate) in
                if let mapItem = mapItem, let coordinate = coordinate {
                    
                    appleMapsItems[activity.title] = mapItem
                    
                    
                    var photoURL: URL? = nil
                    if let imageUrlString = activity.imageUrl, !imageUrlString.isEmpty, 
                       let url = URL(string: imageUrlString) {
                        photoURL = url
                        print("🖼️ DEBUG: Using backend imageUrl for \(activity.title): \(imageUrlString)")
                    } else {
                        photoURL = getPhotoURLForPlace(place: activity.title, city: city) ?? 
                                  getRandomPhotoURL(for: activity.category)
                    }
                    
                    let annotation = MapAnnotation(
                        title: activity.title,
                        subtitle: activity.time,
                        coordinate: coordinate,
                        activityInfo: activity,
                        useAppleMapsStyle: true,
                        mapItem: mapItem,
                        imageURL: photoURL
                    )
                    annotations.append(annotation)
                    print("🍎 DEBUG: Using Apple Maps POI for \(activity.title)")
                    group.leave()
                } else {
                    
                    geocodeAddress(from: activity.mapAddress, inCity: city) { coordinate in
                        if let coordinate = coordinate {
                            
                            var photoURL: URL? = nil
                            if let imageUrlString = activity.imageUrl, !imageUrlString.isEmpty, 
                               let url = URL(string: imageUrlString) {
                                photoURL = url
                                print("🖼️ DEBUG: Using backend imageUrl for \(activity.title): \(imageUrlString)")
                            } else {
                                photoURL = getPhotoURLForPlace(place: activity.title, city: city) ?? 
                                          getRandomPhotoURL(for: activity.category)
                            }
                            
                            let annotation = MapAnnotation(
                                title: activity.title,
                                subtitle: activity.time,
                                coordinate: coordinate,
                                activityInfo: activity,
                                imageURL: photoURL
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
