import SwiftUI
import MapKit
import CoreLocation

struct EmptyDetailView: View {
    var activity: Activity
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject private var languageManager: LanguageManager
    @State private var region = MKCoordinateRegion()
    @State private var userLocation: CLLocationCoordinate2D?
    @State private var destinationLocation: CLLocationCoordinate2D?
    @State private var isShowingDirections = false
    @StateObject private var locationManager = LocationManager()
    @State private var route: MKRoute?
    @State private var routeSteps: [String] = []
    @State private var showingRouteDetails = false
    @State private var isLoadingRoute = false
    @State private var selectedTransportType: MKDirectionsTransportType = .automobile
    @State private var errorMessage: String? = nil
    
    var body: some View {
        ZStack {
            
            if let route = route {
                RouteMapView(route: route)
                    .ignoresSafeArea(.all)
            } else {
                Map(coordinateRegion: $region, showsUserLocation: true, 
                    annotationItems: [LocationAnnotation(coordinate: destinationLocation ?? CLLocationCoordinate2D())]) { annotation in
                    MapMarker(coordinate: annotation.coordinate, tint: .red)
                }
                .ignoresSafeArea(.all)
            }
            
            VStack {     
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .padding(12)
                            .background(
                                Circle()
                                    .fill(colorScheme == .dark ? Color(.systemGray5) : Color.white)
                                    .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
                            )
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                    }
                    
                    Spacer()
                    
                    
                  /*  Button(action: {
                        
                    }) {
                        Text("3D")
                            .font(.system(size: 16, weight: .medium))
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(colorScheme == .dark ? Color(.systemGray5) : Color.white)
                                    .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
                            )
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                    }*/
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                Spacer()
                
                
                if isLoadingRoute {
                    
                    ProgressView()
                        .padding(15)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(colorScheme == .dark ? Color(.systemGray5) : Color.white)
                                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                        )
                        .padding(.bottom, 25)
                } else if !showingRouteDetails {
                    
                    Button(action: {
                        calculateDirections()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "location.fill")
                            Text(languageManager.localize("navigate"))
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(30)
                        .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 2)
                        .padding(.horizontal, 40)
                    }
                    .padding(.bottom, 25)
                }
                
                
                if showingRouteDetails, let route = route {
                    VStack(alignment: .leading, spacing: 0) {
                        
                        HStack {
                            Spacer()
                            Rectangle()
                                .fill(Color.gray.opacity(0.5))
                                .frame(width: 36, height: 5)
                                .cornerRadius(2.5)
                            Spacer()
                        }
                        .padding(.top, 6)
                        .padding(.bottom, 10)
                        
                        
                        HStack {
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(alignment: .firstTextBaseline) {
                                    Text(formatTimeInterval(route.expectedTravelTime))
                                        .font(.system(size: 32, weight: .bold))
                                    
                                    Spacer()
                                    
                                    Text(formatDistance(route.distance))
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                }
                                
                                HStack {
                                    Text(languageManager.localize("fastest"))
                                        .font(.subheadline)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(4)
                                    
                                    Text("\(languageManager.localize("eta")) \(formatETA(Date().addingTimeInterval(route.expectedTravelTime)))")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            
                        }
                        .padding(.bottom, 8) 
                        .padding(.horizontal)
                        
                        
                        if showingRouteDetails {
                            Divider()
                                .padding(.horizontal)
                            
                            ScrollView {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(languageManager.localize("directions"))
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Text("\(routeSteps.count) \(languageManager.localize("steps"))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, 4)
                                    
                                    if routeSteps.isEmpty {
                                        Text(languageManager.localize("no_directions_available"))
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .padding(.vertical, 8)
                                    } else {
                                        ForEach(Array(routeSteps.enumerated()), id: \.1) { index, step in
                                            HStack(alignment: .top, spacing: 12) {
                                                Text("\(index + 1)")
                                                    .font(.caption)
                                                    .foregroundColor(.white)
                                                    .frame(width: 22, height: 22)
                                                    .background(Circle().fill(Color.blue))
                                                
                                                Text(step)
                                                    .font(.subheadline)
                                                    .foregroundColor(.primary)
                                                    .fixedSize(horizontal: false, vertical: true)
                                                
                                                Spacer()
                                            }
                                            .padding(.vertical, 4)
                                            
                                            if index < routeSteps.count - 1 {
                                                Divider()
                                                    .padding(.leading, 34)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .frame(height: 200)
                            
                            
                            HStack(spacing: 0) {
                                ForEach(["car", "figure.walk", "tram"], id: \.self) { icon in
                                    Button(action: {
                                        let newTransportType: MKDirectionsTransportType
                                        switch icon {
                                        case "car":
                                            newTransportType = .automobile
                                        case "figure.walk":
                                            newTransportType = .walking
                                        case "tram":
                                            newTransportType = .transit
                                        default:
                                            newTransportType = .automobile
                                        }
                                        
                                        if newTransportType != selectedTransportType {
                                            selectedTransportType = newTransportType
                                            calculateDirections()
                                        }
                                    }) {
                                        Image(systemName: icon)
                                            .font(.system(size: 20))
                                            .foregroundColor((selectedTransportType == .automobile && icon == "car") || 
                                                             (selectedTransportType == .walking && icon == "figure.walk") ||
                                                             (selectedTransportType == .transit && icon == "tram") 
                                                              ? .white : (colorScheme == .dark ? .white : .primary))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 18)
                                            .background((selectedTransportType == .automobile && icon == "car") || 
                                                        (selectedTransportType == .walking && icon == "figure.walk") ||
                                                        (selectedTransportType == .transit && icon == "tram")
                                                         ? Color.blue : Color.clear)
                                    }
                                }
                            }
                            .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6))
                        }
                    }
                    .background(
                        Rectangle()
                            .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 5, y: -2)
                            .edgesIgnoringSafeArea(.bottom)
                    )
                }
            }
            .animation(.spring(), value: showingRouteDetails)
            .animation(.easeInOut, value: isLoadingRoute)
        }
        .onAppear {
            setupMap()
        }
        .navigationBarHidden(true)
        .alert(isPresented: Binding<Bool>(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Alert(
                title: Text(languageManager.localize("directions_not_available")),
                message: Text(errorMessage ?? ""),
                dismissButton: .default(Text(languageManager.localize("ok")))
            )
        }
    }
    
    private func formatETA(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
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
        
        if selectedTransportType == .transit {
            isLoadingRoute = false
            errorMessage = "\(languageManager.localize("transit_coming_soon"))\n\n\(languageManager.localize("transit_future_update"))"
            return
        }
        
        guard let userLocation = locationManager.location?.coordinate else {
            print("User location not available")
            return
        }
        
        guard let destinationLocation = destinationLocation else {
            print("Destination location not available")
            return
        }
        
        isLoadingRoute = true
        errorMessage = nil
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLocation))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destinationLocation))
        request.transportType = selectedTransportType
        
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            isLoadingRoute = false
            
            if let error = error as NSError? {
                self.errorMessage = "\(languageManager.localize("route_calculation_error")) \(error.localizedDescription)"
                print(self.errorMessage ?? "")
                return
            }
            
            guard let response = response, let route = response.routes.first else {
                self.errorMessage = languageManager.localize("no_route_found")
                print(self.errorMessage ?? "")
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