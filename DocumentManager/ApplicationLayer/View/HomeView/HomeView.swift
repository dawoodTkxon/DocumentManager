//
//  HomeView.swift
//  DocumentManager
//
//  Created by TKXON on 05/01/2025.
//

import Foundation
import SwiftUI
import MapKit
import SwiftData
import CloudKit

@available(iOS 17, *)
struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var vm: CloudKitViewModel
    @State private var isSignedIn: Bool = GoogleSignInManager.shared.isSignedIn
    @State private var isAddingContact = false
    @State private var isProcessingShare = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @Query private var companyModels: [CompanyModel]

    private var geoJSONLoaded = false

    var body: some View {
        NavigationSplitView {
            List(companyModels, id: \.id) { company in
                
                if isSignedIn {
                    NavigationLink(destination: CompanyDetailView(company: company)) {
                        Text(company.name)
                            .font(.headline)
                    }
                } else {
                    Button(action: {
                        showLoginAlert()
                    }) {
                        Text(company.name)
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                }

            }
            .navigationTitle("Companies")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    progressView
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isSignedIn {
                        Menu {
                            Button("Add Manually") {
                                isAddingContact = true
                            }
                            Button("Import from JSON") {
                                loadAndSaveGeoJSON()
                            }
                            Button("Delete All") {
                                deleteAllCompanyModels()
                                Task{ try await vm.deleteAllData()}
                            }
                        } label: {
                            Image(systemName: "plus")
                        }
                    } else {
                        Button(action: {
                            showLoginAlert()
                        }) {
                            Image(systemName: "plus")
                                .foregroundColor(.gray)
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    if isSignedIn {
                        Button(action: { handleLogout() }) {
                            Text("Logout")
                                .font(.headline)
                        }
                    } else {
                        Button(action: { handleLogin() }) {
                            Text("Login")
                                .font(.headline)
                        }
                    }
                }
                
                
            }
            .onAppear {
                Task {
                    try await vm.initialize()
                    try await vm.refresh()
                    await fetchCompanyShare()
                }
                GoogleSignInManager.shared.signInSilently{
                    isSignedIn = GoogleSignInManager.shared.isSignedIn

                }
                
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("FetchData"))) { _ in
                Task {
                    try await vm.initialize()
                    try await vm.refresh()
                    await fetchCompanyShare()
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Authentication Required"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .fullScreenCover(isPresented: $isAddingContact, content: {
                AddCompanyView(onCancel: { isAddingContact = false })
            })
        } detail: {
            if isSignedIn {
                Text("Select a company to view details.")
                    .font(.subheadline)
                    .foregroundColor(.white)
            } else {
                Text("Please log in to access details.")
                    .font(.headline)
                    .foregroundColor(.gray)
            }
        }
    }
    
    private func navigateToCompanyDetail(company: CompanyModel) {
      
    }

    private func showLoginAlert() {
        alertMessage = "You must log in to perform this action."
        showAlert = true
    }
    private func deleteAllCompanyModels() {
            for company in companyModels {
                modelContext.delete(company)
            }
            do {
                try modelContext.save()
            } catch {
                print("Failed to delete all: \(error.localizedDescription)")
            }
        }

    private func handleLogin() {
        if let rootVC = UIApplication.shared.windows.first?.rootViewController {
            GoogleSignInManager.shared.signIn(presenting: rootVC) {
                isSignedIn = GoogleSignInManager.shared.isSignedIn
                Task {
                    try await vm.initialize()
                    try await vm.refresh()
                    await fetchCompanyShare()
                }
            }
        }
    }

    private func handleLogout() {
        GoogleSignInManager.shared.signOut()
        isSignedIn = false
        alertMessage = "You have been logged out."
        showAlert = true
    }

    private func fetchCompanyShare() async {
        isProcessingShare = true
        do {
            let (privateContacts, sharedContacts) = try await vm.fetchPrivateAndSharedCompanies()
            for remoteModel in privateContacts {
                await saveCompany(remoteModel: remoteModel)
            }
            for remoteModel in sharedContacts {
                await saveCompany(remoteModel: remoteModel)
            }
        } catch {
            alertMessage = "Error fetching company records: \(error.localizedDescription)"
            showAlert = true
        }
        isProcessingShare = false
    }

    private func saveCompany(remoteModel: CompanayRemoteModel) async {

        if companyModels.contains(where: { $0.folderID == remoteModel.folderID }) {
//            for companyModel in companyModels {
//                if companyModel.folderID == remoteModel.folderID {
//                    companyModel.name = remoteModel.name
//                    companyModel.siret = remoteModel.siret
//                    companyModel.primaryLocationLatitude = remoteModel.primaryLocationLatitude
//                    companyModel.primaryLocationLongitude = remoteModel.primaryLocationLongitude
//                    companyModel.secondaryLocationLatitude = remoteModel.secondaryLocationLatitude
//                    companyModel.secondaryLocationLatitude = remoteModel.secondaryLocationLatitude
//                }
//                Task{try modelContext.save()}
//            }
            
            
           
        }else{
            let newCompany = CompanyModel(
                name: remoteModel.name,
                siret: remoteModel.siret,
                primaryLocation: CLLocationCoordinate2D(
                    latitude: remoteModel.primaryLocationLatitude,
                    longitude: remoteModel.primaryLocationLongitude
                ),
                secondaryLocation: CLLocationCoordinate2D(
                    latitude: remoteModel.secondaryLocationLatitude,
                    longitude: remoteModel.secondaryLocationLongitude
                ),
                folderID: remoteModel.folderID
                
                
            )
            modelContext.insert(newCompany)
        }
    }
    
    /// This progress view will display when either the ViewModel is loading, or a share is processing.
    var progressView: some View {
        let showProgress: Bool = {
            if isSignedIn{
                if case .loading = vm.state {
                    return true
                } else if isProcessingShare {
                    return true
                }
                return false
            }
            return false
        }()

        return Group {
            if showProgress {
                ProgressView()
            }
        }
    }

}

// Load Jason File
@available(iOS 17, *)
extension HomeView {
    private func loadAndSaveGeoJSON() {
        let companies = loadGeoJSON()
        for company in companies {
            if !companyModels.contains(where: { $0.id == company.id }) {
                modelContext.insert(company)
            }
        }
        do {
            try modelContext.save()
        } catch {
            print("Failed to save companies to SwiftData: \(error)")
        }
    }
    
    
    func loadGeoJSON() -> [CompanyModel] {
        guard let fileURL = Bundle.main.url(forResource: "geosiret_parcelles", withExtension: "geojson") else {
            print("GeoJSON file not found.")
            return []
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let features = json["features"] as? [[String: Any]] else {
                print("Invalid GeoJSON structure.")
                return []
            }
            
            return features.compactMap { feature in
                guard
                    let properties = feature["properties"] as? [String: Any],
                    let geometry = feature["geometry"] as? [String: Any],
                    let coordinates = geometry["coordinates"] as? [Double],
                    let siret = properties["siret"] as? String,
                    let name = properties["nom_complet_x"] as? String else {
                    return nil
                }
                
                let primaryLatitude = properties["latitude"] as? Double ?? 0.0
                let primaryLongitude = properties["longitude"] as? Double ?? 0.0
                let secondaryLatitude = coordinates.last ?? 0.0
                let secondaryLongitude = coordinates.first ?? 0.0
                
                return CompanyModel(
                    name: name,
                    siret: siret,
                    primaryLocation: CLLocationCoordinate2D(latitude: primaryLatitude, longitude: primaryLongitude),
                    secondaryLocation: CLLocationCoordinate2D(latitude: secondaryLatitude, longitude: secondaryLongitude),
                    folderID: nil
                )
            }
        } catch {
            print("Failed to load GeoJSON: \(error)")
            return []
        }
    }
}
