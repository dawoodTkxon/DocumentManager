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
import CloudKit


@available(iOS 17, *)
@Model
class CompanyModel {
    var id =  UUID()
    var name: String = ""
    var siret: String = ""
    var primaryLocationLatitude: Double = 0.0
    var primaryLocationLongitude: Double = 0.0
    var secondaryLocationLatitude: Double = 0.0
    var secondaryLocationLongitude: Double = 0.0
    var documents: [DocumentModel] = []
    var folderID: String = ""
    var isCompleted: Bool = false


    init(name: String, siret: String, primaryLocation: CLLocationCoordinate2D, secondaryLocation: CLLocationCoordinate2D, folderID: String?) {
        self.name = name
        self.siret = siret
        self.primaryLocationLatitude = primaryLocation.latitude
        self.primaryLocationLongitude = primaryLocation.longitude
        self.secondaryLocationLatitude = secondaryLocation.latitude
        self.secondaryLocationLongitude = secondaryLocation.longitude
        self.folderID = folderID ?? ""
        
    }
    
    init(){
        
    }
    
}



@available(iOS 17, *)
struct CompanayRemoteModel: Identifiable {
    var id: String
    var name: String
    var siret: String
    var primaryLocationLatitude: Double
    var primaryLocationLongitude: Double
    var secondaryLocationLatitude: Double
    var secondaryLocationLongitude: Double
    var folderID: String
    let associatedRecord: CKRecord
    
    

}


@available(iOS 17, *)
extension CompanayRemoteModel {
    init?(record: CKRecord) {
        guard let name = record["name"] as? String,
              let siret = record["siret"] as? String,
              let primaryLocationLatitude = record["primaryLocationLatitude"] as? Double,
              let primaryLocationLongitude = record["primaryLocationLongitude"] as? Double,
              let secondaryLocationLatitude = record["secondaryLocationLatitude"] as? Double,
              let secondaryLocationLongitude = record["secondaryLocationLongitude"] as? Double,
              let folderID = record["folderID"] as? String else {
            return nil
        }

        self.id = record.recordID.recordName
        self.name = name
        self.siret = siret
        self.primaryLocationLatitude = primaryLocationLatitude
        self.primaryLocationLongitude = primaryLocationLongitude
        self.secondaryLocationLatitude = secondaryLocationLatitude
        self.secondaryLocationLongitude = secondaryLocationLongitude
        self.folderID = folderID
        self.associatedRecord = record
    }

}

