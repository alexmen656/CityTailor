//
//  CustomPointAnnotation.swift
//  CityTailor
//
//  Created by GitHub Copilot on 5/20/25.
//

import MapKit
import Foundation

class CustomPointAnnotation: MKPointAnnotation {
    var activityInfo: Activity?
    var clusteringIdentifier: String?
    var originalCoordinate: CLLocationCoordinate2D?
    var useAppleMapsStyle: Bool = false
    var mapItem: MKMapItem?
    var imageURL: URL?
}
