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
        
        let currentAnnotations = view.annotations.compactMap { $0 as? CustomPointAnnotation }
        let currentCoordinates = Set(currentAnnotations.map { 
            "\($0.coordinate.latitude),\($0.coordinate.longitude)"
        })
        
        for annotation in annotations {
            let coordinateKey = "\(annotation.coordinate.latitude),\(annotation.coordinate.longitude)"
            
            if !currentCoordinates.contains(coordinateKey) {
                let pin = CustomPointAnnotation()
                pin.coordinate = annotation.coordinate
                pin.title = annotation.title
                pin.subtitle = annotation.subtitle
                pin.activityInfo = annotation.activityInfo
                pin.clusteringIdentifier = "ActivityCluster"
                view.addAnnotation(pin)
            }
        }
        
        let newCoordinates = Set(annotations.map {
            "\($0.coordinate.latitude),\($0.coordinate.longitude)"
        })
        
        let annotationsToRemove = currentAnnotations.filter {
            let key = "\($0.coordinate.latitude),\($0.coordinate.longitude)"
            return !newCoordinates.contains(key)
        }
        
        if !annotationsToRemove.isEmpty {
            view.removeAnnotations(annotationsToRemove)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class CustomPointAnnotation: MKPointAnnotation {
        var activityInfo: Activity?
        var clusteringIdentifier: String?
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