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
import AppKit

@available(macOS 13.0, *)
struct HomeMacOSView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var companyModels: [CompanyModel]
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var vm: CloudKitViewModel
    
    @State private var isSignedIn: Bool = GoogleSignInManager.shared.isSignedIn
    
    @State private var isProcessingShare = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationSplitView {
            ZStack{
                List(companyModels, id: \.id) { company in
                    NavigationLink(destination: CompanyDetailMacOSView(company: company)) {
                        Text(company.name)
                            .font(.headline)
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
            .navigationTitle("Companies")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    NavigationLink {
                        AddCompanyView()
                    } label: {
                        Image(systemName: "plus")
                            .font(.headline)
                    }
                }
                ToolbarItem(placement: .navigation) {
                    HStack{
                        Button(action: {
                            handleAuthentication()
                        }) {
                            Text(isSignedIn ? "Logout" : "Login")
                                .font(.headline)
                        }
                    }
                }
            }
            .onAppear {
                GoogleSignInManager.shared.signInSilently{
                    isSignedIn = GoogleSignInManager.shared.isSignedIn
                    if isSignedIn {
                        Task {
                            try await vm.initialize()
                            try await vm.refresh()
                            await fetchCompanyShare()
                        }
                    }
                }
            }
        } detail: {
            Text("Select a company to view details.")
                .font(.subheadline)
                .foregroundColor(.gray)
            
        }
    }
    private func handleAuthentication() {
        if isSignedIn {
            GoogleSignInManager.shared.signOut()
            isSignedIn = false
        } else {
            if let window = NSApplication.shared.windows.first {
                GoogleSignInManager.shared.signIn(presenting: window, completion: {
                    isSignedIn = GoogleSignInManager.shared.isSignedIn
                    Task {
                        try await vm.initialize()
                        try await vm.refresh()
                        await fetchCompanyShare()
                    }
                    
                })
            }
        }
    }
    private func showLoginAlert() {
        alertMessage = "You must log in to perform this action."
        showAlert = true
    }
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
        for obj in companyModels{

        }
        if !companyModels.contains(where: { $0.folderID == remoteModel.folderID }) {
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
            do{
                try modelContext.save()
            }catch{
                
            }
        }
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
}



