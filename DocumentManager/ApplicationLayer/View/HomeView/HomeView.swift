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
    @State private var isSignedIn: Bool = GoogleDriveSingletonClass.shared.isSignedIn
    @State private var isAddingContact = false
    @State private var isProcessingShare = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    @Query(sort: \CompanyModel.name) private var companyModels: [CompanyModel]

    var body: some View {
        NavigationSplitView {
            List(companyModels, id: \.id) { company in
                
                if isSignedIn {
                    NavigationLink(destination: CompanyDetailView(company: company)) {
                        Text(company.name ?? "n/a")
                            .font(.headline)
                    }
                } else {
                    Button(action: {
                        showLoginAlert()
                    }) {
                        Text(company.name ?? "n/a")
                            .font(.headline)
                            .foregroundColor(.red)
                    }
                }

            }
            .navigationTitle("Companies")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    progressView
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        if isSignedIn {
                            isAddingContact = true
                        } else {
                            showLoginAlert()
                        }
                    }) { Image(systemName: "plus") }
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
                isSignedIn = GoogleDriveSingletonClass.shared.isSignedIn
                if isSignedIn {
                    Task {
                        try await vm.initialize()
                        try await vm.refresh()
                        await fetchCompanyShare()
                    }
                }
            }
            .onChange(of: isSignedIn) { newValue in
               
                    print("newValue\(newValue)")
                
                
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Authentication Required"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .sheet(isPresented: $isAddingContact, content: {
                AddCompanyView(onCancel: { isAddingContact = false })
            })
        } detail: {
            if isSignedIn {
                Text("Select a company to view details.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            } else {
                Text("Please log in to access details.")
                    .font(.headline)
                    .foregroundColor(.red)
            }
        }
    }
    
    private func navigateToCompanyDetail(company: CompanyModel) {
      
    }

    private func showLoginAlert() {
        alertMessage = "You must log in to perform this action."
        showAlert = true
    }

    private func handleLogin() {
        if let rootVC = UIApplication.shared.windows.first?.rootViewController {
            GoogleDriveSingletonClass.shared.signIn(presenting: rootVC) {
                isSignedIn = GoogleDriveSingletonClass.shared.isSignedIn
                Task {
                    try await vm.initialize()
                    try await vm.refresh()
                    await fetchCompanyShare()
                }
            }
        }
    }

    private func handleLogout() {
        GoogleDriveSingletonClass.shared.signOut()
        isSignedIn = false
        alertMessage = "You have been logged out."
        showAlert = true
    }

    private func fetchCompanyShare() async {
        isProcessingShare = true
        do {
            let (privateContacts, sharedContacts) = try await vm.fetchPrivateAndSharedCompanies()
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
        for obj in companyModels{
            print("Local folder Id", obj.folderID)
        }
        if !companyModels.contains(where: { $0.folderID == remoteModel.folderID }) {
            print("Remote folder Id", remoteModel.folderID)
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
