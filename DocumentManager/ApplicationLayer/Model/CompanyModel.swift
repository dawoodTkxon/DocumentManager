//
//  CompanyModel.swift
//  DocumentManager
//
//  Created by TKXON on 05/01/2025.
//

import Foundation
import SwiftData
import CoreLocation
import SwiftUI


@available(iOS 17, *)
@Model
class CompanyModel {
    @Attribute(.unique) var id: UUID
    var name: String
    var siret: String
    var primaryLocationLatitude: Double
    var primaryLocationLongitude: Double
    var secondaryLocationLatitude: Double
    var secondaryLocationLongitude: Double
    var documents: [DocumentModel] = [] // Relationship with documents
    var folderID: String = ""// Optional folder ID


    init(name: String, siret: String, primaryLocation: CLLocationCoordinate2D, secondaryLocation: CLLocationCoordinate2D) {
        self.id = UUID()
        self.name = name
        self.siret = siret
        self.primaryLocationLatitude = primaryLocation.latitude
        self.primaryLocationLongitude = primaryLocation.longitude
        self.secondaryLocationLatitude = secondaryLocation.latitude
        self.secondaryLocationLongitude = secondaryLocation.longitude
    }
}

