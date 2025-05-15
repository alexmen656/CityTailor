import SwiftUI
import MapKit
import CoreLocation

struct EmptyDetailView: View {
    var activity: Activity
    @Environment(\.presentationMode) var presentationMode
    @State private var region = MKCoordinateRegion()
    @State private var userLocation: CLLocationCoordinate2D?
    @State private var destinationLocation: CLLocationCoordinate2D?
    @State private var isShowingDirections = false
    @StateObject private var locationManager = LocationManager()
    @State private var route: MKRoute?
    @State private var routeSteps: [String] = []
    @State private var showingRouteDetails = false
    @State private var isLoadingRoute = false
    
    var body: some View {
        VStack {
            Map(coordinateRegion: $region, showsUserLocation: true, 
                annotationItems: [LocationAnnotation(coordinate: destinationLocation ?? CLLocationCoordinate2D())]) { annotation in
                MapMarker(coordinate: annotation.coordinate, tint: .red)
            }
            .overlay(
                Group {
                    if let route = route {
                        RouteMapView(route: route)
                    }
                }
            )
            .edgesIgnoringSafeArea(.all)
            .onAppear {
                setupMap()
            }
            
            VStack(spacing: 20) {
                Text(activity.title)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(activity.mapAddress)
                    .font(.subheadline)
                
                if isLoadingRoute {
                    ProgressView("Calculating route...")
                } else {
                    Button(action: {
                        calculateDirections()
                    }) {
                        HStack {
                            Image(systemName: "map.fill")
                            Text("Show Directions")
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                
                if showingRouteDetails, let route = route {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("ETA: \(formatTimeInterval(route.expectedTravelTime))")
                            .font(.headline)
                        Text("Distance: \(formatDistance(route.distance))")
                            .font(.headline)
                        
                        Divider()
                        
                        Text("Directions:")
                            .font(.headline)
                        
                        ScrollView {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(routeSteps.indices, id: \.self) { index in
                                    HStack(alignment: .top) {
                                        Text("\(index + 1).")
                                            .font(.subheadline)
                                            .frame(width: 25, alignment: .leading)
                                        Text(routeSteps[index])
                                            .font(.subheadline)
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                        }
                        .frame(maxHeight: 200)
                    }
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(15)
            .shadow(radius: 5)
            .padding()
        }
        .navigationTitle("Directions")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func setupMap() {
        
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(activity.mapAddress) { placemarks, error in
            guard error == nil else {
                print("Geocoding error: \(error!.localizedDescription)")
                return
            }
            
            guard let placemark = placemarks?.first,
                  let location = placemark.location?.coordinate else {
                print("Could not find coordinates for address")
                return
            }
            
            destinationLocation = location
            
            
            region = MKCoordinateRegion(
                center: location,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
        
        
        userLocation = locationManager.location?.coordinate
    }
    
    private func calculateDirections() {
        guard let userLocation = locationManager.location?.coordinate else {
            print("User location not available")
            return
        }
        
        guard let destinationLocation = destinationLocation else {
            print("Destination location not available")
            return
        }
        
        isLoadingRoute = true
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLocation))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destinationLocation))
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            isLoadingRoute = false
            
            guard let response = response, let route = response.routes.first, error == nil else {
                print("Error calculating directions: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            self.route = route
            self.routeSteps = route.steps.map { $0.instructions }.filter { !$0.isEmpty }
            
            
            let rect = route.polyline.boundingMapRect
            self.region = MKCoordinateRegion(rect)
            
            
            self.showingRouteDetails = true
        }
    }
    
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: interval) ?? ""
    }
    
    private func formatDistance(_ distance: CLLocationDistance) -> String {
        let formatter = MKDistanceFormatter()
        formatter.unitStyle = .abbreviated
        return formatter.string(fromDistance: distance)
    }
    
    private func getDirections() {
        
        calculateDirections()
    }
}


class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var location: CLLocation?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last
    }
}

struct LocationAnnotation: Identifiable {
    let id = UUID()
    var coordinate: CLLocationCoordinate2D
}

struct RouteMapView: UIViewRepresentable {
    let route: MKRoute
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        
        
        mapView.addOverlay(route.polyline)
        
        
        if let destinationCoordinate = route.steps.last?.polyline.coordinate {
            let annotation = MKPointAnnotation()
            annotation.coordinate = destinationCoordinate
            mapView.addAnnotation(annotation)
        }
        
        
        mapView.showsUserLocation = true
        
        
        mapView.setVisibleMapRect(route.polyline.boundingMapRect, 
                                 edgePadding: UIEdgeInsets(top: 40, left: 40, bottom: 40, right: 40),
                                 animated: true)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: RouteMapView
        
        init(_ parent: RouteMapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if overlay is MKPolyline {
                let renderer = MKPolylineRenderer(overlay: overlay)
                renderer.strokeColor = UIColor.systemBlue
                renderer.lineWidth = 5
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}