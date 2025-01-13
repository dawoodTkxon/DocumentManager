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
    @EnvironmentObject private var vm: CloudKitViewModel
    
    @State private var name = ""
    @State private var siret = ""
    @State private var primaryLatitude = ""
    @State private var primaryLongitude = ""
    @State private var secondaryLatitude = ""
    @State private var secondaryLongitude = ""
    
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    let onCancel: (() -> Void)?
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    Form {
                        Section(header: Text("Company Info")) {
                            TextField("Name", text: $name)
                                .keyboardType(.asciiCapable)
                            TextField("Siret", text: $siret)
                                .keyboardType(.numberPad)
                            
                        }
                        
                        Section(header: Text("Primary Location")) {
                            TextField("Latitude", text: $primaryLatitude)
                                .keyboardType(.decimalPad)
                            
                            TextField("Longitude", text: $primaryLongitude)
                                .keyboardType(.decimalPad)
                            
                        }
                        
                        Section(header: Text("Secondary Location")) {
                            TextField("Latitude", text: $secondaryLatitude)
                                .keyboardType(.decimalPad)
                            
                            TextField("Longitude", text: $secondaryLongitude)
                                .keyboardType(.decimalPad)
                            
                        }
                    }
                }
                
                if isSaving {
                    LoaderView()
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
                    Button(action: {
                        isSaving = true
                        errorMessage = nil
                        
                        guard let primaryLat = Double(primaryLatitude),
                              let primaryLon = Double(primaryLongitude),
                              let secondaryLat = Double(secondaryLatitude),
                              let secondaryLon = Double(secondaryLongitude) else {
                            errorMessage = "Invalid coordinates."
                            isSaving = false
                            return
                        }
                        
                        let newCompany = CompanyModel(
                            name: name,
                            siret: siret,
                            primaryLocation: CLLocationCoordinate2D(latitude: primaryLat, longitude: primaryLon),
                            secondaryLocation: CLLocationCoordinate2D(latitude: secondaryLat, longitude: secondaryLon), folderID: ""
                        )
                        
                        modelContext.insert(newCompany)
                        
                        Task {
                            do {
                                try modelContext.save()
                                if !GoogleSignInManager.shared.folderCreated {
                                    GoogleSignInManager.shared.createFolder(name: name) { folderID in
                                        if let folderID = folderID {
                                            newCompany.folderID = folderID
                                            do {
                                                try modelContext.save()
                                                Task {
                                                    try await vm.addCompnay(
                                                        name: name,
                                                        siret: siret,
                                                        primaryLocationLatitude: primaryLat,
                                                        primaryLocationLongitude: primaryLon,
                                                        secondaryLocationLatitude: secondaryLat,
                                                        secondaryLocationLongitude: secondaryLon,
                                                        folderID:  newCompany.folderID
                                                    )
                                                    isSaving = false
                                                    dismiss()
                                                }
                                            } catch {
                                                errorMessage = "Failed to save company: \(error.localizedDescription)"
                                                isSaving = false
                                            }
                                        } else {
                                            errorMessage = "Failed to create folder."
                                            isSaving = false
                                        }
                                    }
                                }
                            } catch {
                                errorMessage = "Failed to save company: \(error.localizedDescription)"
                                isSaving = false
                            }
                        }
                    }) {
                        Text("Save")
                    }
                }
            }
        }
    }
}




