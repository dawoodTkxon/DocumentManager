//
//  AddNewCompanyView.swift
//  DocumentManager
//
//  Created by TKXON on 05/01/2025.
//

import Foundation
import SwiftUI
import SwiftData
import MapKit

@available(iOS 17, *)
struct AddCompanyView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var name = ""
    @State private var siret = ""
    @State private var primaryLatitude = ""
    @State private var primaryLongitude = ""
    @State private var secondaryLatitude = ""
    @State private var secondaryLongitude = ""
    
    var body: some View {
        VStack {
            Form {
                Section(header: Text("Company Info")) {
                    TextField("Name", text: $name)
                    TextField("SIRET", text: $siret)
                }
                
                Section(header: Text("Primary Location")) {
                    TextField("Latitude", text: $primaryLatitude)
                    TextField("Longitude", text: $primaryLongitude)
                }
                
                Section(header: Text("Secondary Location")) {
                    TextField("Latitude", text: $secondaryLatitude)
                    TextField("Longitude", text: $secondaryLongitude)
                }
            }
            .navigationTitle("Add Company")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        guard let primaryLat = Double(primaryLatitude),
                              let primaryLon = Double(primaryLongitude),
                              let secondaryLat = Double(secondaryLatitude),
                              let secondaryLon = Double(secondaryLongitude) else {
                            return
                        }
                        
                        let newCompany = CompanyModel(
                            name: name,
                            siret: siret,
                            primaryLocation: CLLocationCoordinate2D(latitude: primaryLat, longitude: primaryLon),
                            secondaryLocation: CLLocationCoordinate2D(latitude: secondaryLat, longitude: secondaryLon)                        )
                        modelContext.insert(newCompany)
                        
                        do {
                            try modelContext.save()
                            print("Company saved successfully.")
                        } catch {
                            print("Failed to save company: \(error)")
                        }
                        
                        GoogleDriveSingletonClass.shared.signInSilently()
                        if !GoogleDriveSingletonClass.shared.folderCreated {
                            GoogleDriveSingletonClass.shared.createFolder(name: name) { folderID in
                                if let folderID = folderID {
                                    newCompany.folderID = folderID
                                    do {
                                        try modelContext.save()
                                        print("Company saved successfully with folderID: \(folderID).")
                                    } catch {
                                        print("Failed to save company: \(error)")
                                    }
                                } else {
                                    print("Failed to create folder.")
                                }
                            }
                            
                        }
                        
                        dismiss()
                    }
                }
            }
        }
    }
}
