//
//  MapView.swift
//  DocumentManager
//
//  Created by TKXON on 05/01/2025.
//

import Foundation
import SwiftUI
import MapKit

struct IdentifiableLocation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

struct MapView: View {
    var primaryLocation: CLLocationCoordinate2D
    var secondaryLocation: CLLocationCoordinate2D

    var body: some View {
        let locations = [
            IdentifiableLocation(coordinate: primaryLocation),
            IdentifiableLocation(coordinate: secondaryLocation)
        ]
        
        Map(coordinateRegion: .constant(MKCoordinateRegion(
            center: primaryLocation,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))),
            annotationItems: locations) { location in
                MapMarker(coordinate: location.coordinate, tint: .blue)
            }
        .navigationTitle("Company Locations")
    }
}
