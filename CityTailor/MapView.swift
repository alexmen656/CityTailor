import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    var annotations: [MapAnnotation] = []
    var selectedAnnotation: MapAnnotation? = nil
    @EnvironmentObject private var settings: AppSettings
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        
        mapView.register(
            MKMarkerAnnotationView.self,
            forAnnotationViewWithReuseIdentifier:MKMapViewDefaultAnnotationViewReuseIdentifier
        )
        
        mapView.register(
            MKMarkerAnnotationView.self,
            forAnnotationViewWithReuseIdentifier:MKMapViewDefaultClusterAnnotationViewReuseIdentifier
        )
        
        return mapView
    }
    
    func updateUIView(_ view: MKMapView, context: Context) {
        view.setRegion(region, animated: true)
        
        applyMapSettings(to: view)
        
        updateAnnotations(view: view, annotations: annotations)
        
        if let selectedAnnotation = selectedAnnotation, 
           let annotation = view.annotations.first(where: { $0.title == selectedAnnotation.title }) {
            view.selectAnnotation(annotation, animated: true)
        }
    }
    
    private func applyMapSettings(to view: MKMapView) {
        if #available(iOS 16.0, *) {
            var mapConfiguration: MKMapConfiguration
            
            switch AppSettings.MapStyle(rawValue: settings.mapStyle) {
            case .standard:
                mapConfiguration = MKStandardMapConfiguration()
            case .satellite:
                mapConfiguration = MKHybridMapConfiguration()
            default:
                mapConfiguration = MKStandardMapConfiguration()
            }
            
            if let standardConfig = mapConfiguration as? MKStandardMapConfiguration {
                standardConfig.pointOfInterestFilter = settings.showPOIs ? .includingAll : .excludingAll
                standardConfig.showsTraffic = settings.showTraffic
            }
            
            if settings.nightMode && mapConfiguration is MKStandardMapConfiguration {
                (mapConfiguration as? MKStandardMapConfiguration)?.elevationStyle = .realistic
            }
            
            view.preferredConfiguration = mapConfiguration
        } else {
            switch AppSettings.MapStyle(rawValue: settings.mapStyle) {
            case .standard:
                view.mapType = .standard
            case .satellite:
                view.mapType = .hybrid
            default:
                view.mapType = .standard
            }
            
            view.showsTraffic = settings.showTraffic
            
            view.pointOfInterestFilter = settings.showPOIs ? .includingAll : .excludingAll
            
            if #available(iOS 13.0, *) {
                view.overrideUserInterfaceStyle = settings.nightMode ? .dark : .light
            }
        }
    }
    
    func updateAnnotations(view: MKMapView, annotations: [MapAnnotation]) {
        
        var coordinateGroups = [String: [MapAnnotation]]()
        
        for annotation in annotations {
            let coordinateKey = "\(annotation.coordinate.latitude),\(annotation.coordinate.longitude)"
            if coordinateGroups[coordinateKey] == nil {
                coordinateGroups[coordinateKey] = [annotation]
            } else {
                coordinateGroups[coordinateKey]?.append(annotation)
            }
        }
        
        let existingAnnotations = view.annotations.compactMap { $0 as? CustomPointAnnotation }
        let newCoordinateKeys = Set(coordinateGroups.keys)
        
        let annotationsToRemove = existingAnnotations.filter {
            let key = "\($0.coordinate.latitude),\($0.coordinate.longitude)"
            
            return !newCoordinateKeys.contains(key) || 
                   (coordinateGroups[key]?.count ?? 0) > 1
        }
        
        if !annotationsToRemove.isEmpty {
            view.removeAnnotations(annotationsToRemove)
        }
        
        let isZoomedIn = view.region.span.latitudeDelta < 0.01 
        
        for (coordinateKey, group) in coordinateGroups {
            
            if group.count == 1 {
                
                if !existingAnnotations.contains(where: { 
                    "\($0.coordinate.latitude),\($0.coordinate.longitude)" == coordinateKey
                }) {
                    let annotation = group[0]
                    let pin = CustomPointAnnotation()
                    pin.coordinate = annotation.coordinate
                    pin.title = annotation.title
                    pin.subtitle = annotation.subtitle
                    pin.activityInfo = annotation.activityInfo
                    pin.clusteringIdentifier = "ActivityCluster"
                    view.addAnnotation(pin)
                }
            } else if isZoomedIn {
                
                let baseCoordinate = group[0].coordinate
                let offsetDistance = 0.0001 * Double(min(group.count, 5)) 
                
                for (index, annotation) in group.enumerated() {
                    let angle = Double(index) * (2.0 * .pi / Double(group.count))
                    
                    let offsetLat = baseCoordinate.latitude + offsetDistance * cos(angle)
                    let offsetLon = baseCoordinate.longitude + offsetDistance * sin(angle)
                    
                    let pin = CustomPointAnnotation()
                    pin.coordinate = CLLocationCoordinate2D(latitude: offsetLat, longitude: offsetLon)
                    pin.title = annotation.title
                    pin.subtitle = annotation.subtitle
                    pin.activityInfo = annotation.activityInfo
                    pin.originalCoordinate = baseCoordinate 
                    pin.clusteringIdentifier = "ActivityCluster"
                    view.addAnnotation(pin)
                }
            } else {
                for annotation in group {
                    let pin = CustomPointAnnotation()
                    pin.coordinate = annotation.coordinate
                    pin.title = annotation.title
                    pin.subtitle = annotation.subtitle
                    pin.activityInfo = annotation.activityInfo
                    pin.clusteringIdentifier = "ActivityCluster"
                    view.addAnnotation(pin)
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class CustomPointAnnotation: MKPointAnnotation {
        var activityInfo: Activity?
        var clusteringIdentifier: String?
        var originalCoordinate: CLLocationCoordinate2D?
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        
        init(_ parent: MapView) {
            self.parent = parent
        }
        
        func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            parent.region = mapView.region
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            
            if annotation is MKUserLocation {
                return nil
            }
            
            if let cluster = annotation as? MKClusterAnnotation {
                let identifier = "ClusterPin"
                var clusterView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
                
                if clusterView == nil {
                    clusterView = MKMarkerAnnotationView(annotation: cluster, reuseIdentifier: identifier)
                } else {
                    clusterView?.annotation = cluster
                }
                
                clusterView?.markerTintColor = .systemBlue
                clusterView?.glyphText = "\(cluster.memberAnnotations.count)"
                clusterView?.displayPriority = .required
                clusterView?.collisionMode = .rectangle
                clusterView?.layer.zPosition = 1000
                clusterView?.layer.shouldRasterize = false
                clusterView?.layer.isOpaque = false
                clusterView?.alpha = 1
                clusterView?.isHidden = false
                clusterView?.layer.speed = 0.99999

                let count = cluster.memberAnnotations.count
                cluster.title = "\(count) " + (count == 1 ? "Aktivität" : "Aktivitäten")
                
                if let firstAnnotation = cluster.memberAnnotations.first as? CustomPointAnnotation,
                   let title = firstAnnotation.title {
                    cluster.subtitle = "Mehrere Aktivitäten in der Nähe"
                }
                
                clusterView?.canShowCallout = true
                return clusterView
            }
            
            if let customAnnotation = annotation as? CustomPointAnnotation {
                let identifier = "ActivityPin"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
                
                if annotationView == nil {
                    annotationView = MKMarkerAnnotationView(annotation: customAnnotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = true
                    
                    let infoButton = UIButton(type: .detailDisclosure)
                    annotationView?.rightCalloutAccessoryView = infoButton
                } else {
                    annotationView?.annotation = customAnnotation
                }
                
                annotationView?.clusteringIdentifier = "ActivityCluster"
                annotationView?.displayPriority = .required
                
                if let title = customAnnotation.title {
                    if title.contains("Museum") {
                        annotationView?.markerTintColor = .purple 
                    } else if title.contains("Essen") || title.contains("Restaurant") {
                        annotationView?.markerTintColor = .red 
                    } else if title.contains("Park") || title.contains("Natur") {
                        annotationView?.markerTintColor = .green 
                    } else if title.contains("Shopping") || title.contains("Markt") {
                        annotationView?.markerTintColor = .orange 
                    } else {
                        annotationView?.markerTintColor = .blue 
                    }
                }
                
                return annotationView
            }
            
            return nil
        }
        
        func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
            if let annotation = view.annotation, let title = annotation.title {
                print("Info-Button wurde geklickt für: \(title ?? "Unbekannt")")
                
            }
        }
    }
}