//
//  EditCompanyMacOSView.swift
//  DocumentManagerMacos
//
//  Created by TKXON on 13/01/2025.
//

import SwiftUI
import SwiftData

struct EditCompanyMacOSView: View {
    
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
    
    var sharedCompanyData: CompanayRemoteModel

    var company: CompanyModel
    
    var body: some View {
        ZStack {
            VStack {
                Form {
                    Section(header: Text("Company Info")) {
                        TextField("Name", text: $name)
                        TextField("Siret", text: $siret)
                    }
                    Section(header: Text("Primary Location")) {
                        TextField("Latitude", text: $primaryLatitude)
                        TextField("Longitude", text: $primaryLongitude)
                    }
                    Section(header: Text("Secondary Location")) {
                        TextField("Latitude", text: $secondaryLatitude)
                        TextField("Longitude", text: $secondaryLongitude)
                    }
                    Section(header: Text("")) {
                        acrtionButtonClicked
                    }

                }
                
                
            }
            if isSaving {
                LoaderView()
            }
        }
        .onAppear{
            name = company.name
            siret = company.siret
            primaryLatitude = String(company.primaryLocationLatitude)
            primaryLongitude = String(company.primaryLocationLongitude)
            secondaryLatitude = String(company.secondaryLocationLatitude)
            secondaryLongitude = String(company.secondaryLocationLongitude)
            
            print("=====================")
            print(sharedCompanyData.name)
            print(sharedCompanyData.siret)
            print(sharedCompanyData.id)
            print(sharedCompanyData.folderID)
            print(sharedCompanyData.associatedRecord)
            print("=====================")
            print("Company Data is empty")
        }
        .onChange(of: company) { oldValue,newValue in
                name = company.name
                siret = company.siret
                primaryLatitude = String(company.primaryLocationLatitude)
                primaryLongitude = String(company.primaryLocationLongitude)
                secondaryLatitude = String(company.secondaryLocationLatitude)
                secondaryLongitude = String(company.secondaryLocationLongitude)
            
            
        }
        .navigationTitle("Edit Company")
    }
    var acrtionButtonClicked: some View {
        HStack{
            Button("Cancel") {
                dismiss()
            }
            
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
                            existingCompany.name = name
                            existingCompany.siret = siret
                            existingCompany.primaryLocationLatitude = primaryLat
                            existingCompany.primaryLocationLongitude = primaryLon
                            existingCompany.secondaryLocationLatitude = secondaryLat
                            existingCompany.secondaryLocationLongitude = secondaryLon
                            
                            try modelContext.save()
                            
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

                            
                            isSaving = false
                            dismiss()
                        } else {
                            errorMessage = "Company not found."
                            isSaving = false
                        }
                    } catch {
                        errorMessage = "Failed to update company: \(error.localizedDescription)"
                        isSaving = false
                    }
                }
            }) {
                Text("Update")
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


