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

//@available(iOS 17, *)
//@Model struct CompanyModel {
//    @Attribute(.primaryKey) var id: String
//    @Attribute(.required) var name: String
//    @Attribute(.required) var siret: String
//    @Attribute(.required) var primaryLocation: CLLocationCoordinate2D
//    @Attribute(.required) var secondaryLocation: CLLocationCoordinate2D
//}
//
//@Model struct Document {
//    @Attribute(.primaryKey) var id: String
//    @Attribute(.required) var name: String
//    @Attribute(.required) var type: FileType
//}

import SwiftData
import CoreLocation

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

    init(name: String, siret: String, primaryLocation: CLLocationCoordinate2D, secondaryLocation: CLLocationCoordinate2D) {
        self.id = UUID() // Auto-generate a unique ID
        self.name = name
        self.siret = siret
        self.primaryLocationLatitude = primaryLocation.latitude
        self.primaryLocationLongitude = primaryLocation.longitude
        self.secondaryLocationLatitude = secondaryLocation.latitude
        self.secondaryLocationLongitude = secondaryLocation.longitude
    }

    // Computed properties for CLLocationCoordinate2D
    var primaryLocation: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: primaryLocationLatitude, longitude: primaryLocationLongitude)
    }

    var secondaryLocation: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: secondaryLocationLatitude, longitude: secondaryLocationLongitude)
    }
}

@available(iOS 17, *)
@Model
class Document {
    @Attribute(.unique) var id: UUID
    var name: String
    var typeRawValue: String

    init(name: String, type: FileType) {
        self.id = UUID() // Auto-generate a unique ID
        self.name = name
        self.typeRawValue = type.rawValue
    }

    // Enum conversion
    var type: FileType {
        get { FileType(rawValue: typeRawValue) ?? .unknown }
        set { typeRawValue = newValue.rawValue }
    }
}

// Define the FileType enum
enum FileType: String {
    case pdf
    case word
    case excel
    case image // Fallback case
    case unknown // Fallback case
}
