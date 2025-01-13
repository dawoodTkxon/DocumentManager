//
//  EditCompanyView.swift
//  DocumentManager
//
//  Created by TKXON on 12/01/2025.
//

import Foundation
import SwiftUI
import SwiftData
import MapKit

@available(iOS 17.0, *)
struct EditCompanyView: View {
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
    
    
    
    //Alert
    @State private var showAlert = false
    @State private var alertMessage = ""


    
    var sharedCompanyData: CompanayRemoteModel

    var company: CompanyModel

    var body: some View {
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
        .onAppear {
            name = company.name
            siret = company.siret
            primaryLatitude = String(company.primaryLocationLatitude)
            primaryLongitude = String(company.primaryLocationLongitude)
            secondaryLatitude = String(company.secondaryLocationLatitude)
            secondaryLongitude = String(company.secondaryLocationLongitude)

        }
        .navigationTitle("Edit Company")
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Error"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK")))}
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                
                Button(action: {
                    isSaving = true
                    guard let primaryLat = Double(primaryLatitude),
                          let primaryLon = Double(primaryLongitude),
                          let secondaryLat = Double(secondaryLatitude),
                          let secondaryLon = Double(secondaryLongitude) else {
                        errorMessage = "Invalid coordinates."
                        isSaving = false
                        return
                    }
                    
                    Task {
                        do {
                            if let existingCompany = fetchExistingCompany(folderID: sharedCompanyData.folderID, in: modelContext) {
                                
                                let updatedCompany = CompanayRemoteModel(
                                    id: sharedCompanyData.id,
                                               name: name,
                                               siret: siret,
                                               primaryLocationLatitude: primaryLat,
                                               primaryLocationLongitude: primaryLon,
                                               secondaryLocationLatitude: secondaryLat,
                                               secondaryLocationLongitude: secondaryLon,
                                               folderID: existingCompany.folderID,
                                               associatedRecord: sharedCompanyData.associatedRecord
                                )
                                
                                try await vm.updateCompanyModelData(company: updatedCompany)
                                
                                existingCompany.name = name
                                existingCompany.siret = siret
                                existingCompany.primaryLocationLatitude = primaryLat
                                existingCompany.primaryLocationLongitude = primaryLon
                                existingCompany.secondaryLocationLatitude = secondaryLat
                                existingCompany.secondaryLocationLongitude = secondaryLon
                                
                                try modelContext.save()

                                
                                isSaving = false
                                dismiss()
                            } else {
                                errorMessage = "Company not found."
                                isSaving = false
                            }
                        } catch {
                            errorMessage = "Failed to update company: \(error.localizedDescription)"
                            showAlert = true
                            alertMessage = "Failed to update data on icloud"
                            isSaving = false
                        }
                    }
                }) {
                    Text("Update")
                }
                
            }
        }
    }
    func fetchExistingCompany(folderID: String, in modelContext: ModelContext) -> CompanyModel? {
        let fetchRequest = FetchDescriptor<CompanyModel>(
            predicate: #Predicate { $0.folderID == folderID }
        )
        let results = try? modelContext.fetch(fetchRequest)
        return results?.first
    }
}

