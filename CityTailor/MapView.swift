import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    var annotations: [MapAnnotation] = []
    var selectedAnnotation: MapAnnotation? = nil
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        return mapView
    }
    
    func updateUIView(_ view: MKMapView, context: Context) {
        view.setRegion(region, animated: true)
        
        // Aktualisiere Annotationen
        updateAnnotations(view: view, annotations: annotations)
        
        // Zeige Callout für ausgewählte Annotation
        if let selectedAnnotation = selectedAnnotation, 
           let annotation = view.annotations.first(where: { $0.title == selectedAnnotation.title }) {
            view.selectAnnotation(annotation, animated: true)
        }
    }
    
    func updateAnnotations(view: MKMapView, annotations: [MapAnnotation]) {
        // Entferne alle bestehenden Annotationen
        view.removeAnnotations(view.annotations)
        
        // Füge neue Annotationen hinzu
        for annotation in annotations {
            let pin = MKPointAnnotation()
            pin.coordinate = annotation.coordinate
            pin.title = annotation.title
            pin.subtitle = annotation.subtitle
            view.addAnnotation(pin)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
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
            // Ignoriere Benutzerstandort
            if annotation is MKUserLocation {
                return nil
            }
            
            let identifier = "ActivityPin"
            
            // Wiederverwendbare Annotation View
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
                
                // Füge Infotaste hinzu
                let infoButton = UIButton(type: .detailDisclosure)
                annotationView?.rightCalloutAccessoryView = infoButton
            } else {
                annotationView?.annotation = annotation
            }
            
            // Setze Pin-Farbe basierend auf dem Aktivitätstyp
            if let markerView = annotationView as? MKMarkerAnnotationView {
                if let title = annotation.title, let title = title {
                    if title.contains("Museum") {
                        markerView.markerTintColor = .purple // Kunst/Museum
                    } else if title.contains("Essen") || title.contains("Restaurant") {
                        markerView.markerTintColor = .red // Gastronomie
                    } else if title.contains("Park") || title.contains("Natur") {
                        markerView.markerTintColor = .green // Natur
                    } else if title.contains("Shopping") || title.contains("Markt") {
                        markerView.markerTintColor = .orange // Shopping
                    } else {
                        markerView.markerTintColor = .blue // Standard
                    }
                }
            }
            
            return annotationView
        }
        
        // Reagiere auf Klicks auf den Info-Button
        func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
            if let annotation = view.annotation, let title = annotation.title {
                print("Info-Button wurde geklickt für: \(title ?? "Unbekannt")")
                // Hier könnte ein Aufruf erfolgen, um Details zu zeigen
            }
        }
    }
}