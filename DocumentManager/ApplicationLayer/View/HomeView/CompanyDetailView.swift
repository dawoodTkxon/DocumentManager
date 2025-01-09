//
//  CompanyDetailView.swift
//  DocumentManager
//
//  Created by TKXON on 05/01/2025.
//

import SwiftUI
import MapKit
import SwiftData
import GoogleSignIn
import GoogleAPIClientForREST
import GTMSessionFetcher
import CloudKit

@available(iOS 17, *)
struct CompanyDetailView: View {
    var company: CompanyModel
    @Query private var documentModel: [CompanyModel]
    let googleDriveService = GTLRDriveService()
    @State private var isScannerPresented = false
    @State private var scannedImages: [UIImage] = []
    @State private var selectedDocument: DocumentModel?
    @EnvironmentObject private var vm: CloudKitViewModel
    
    @State private var isSharing = false
    @State private var isProcessingShare = false
    @State private var activeShare: CKShare?
    @State private var activeContainer: CKContainer?
    
    var body: some View {
        VStack {
            Form {
                Section(header: Text("Company Details")) {
                    Text("Name: \(company.name ?? "n/a")")
                    Text("SIRET: \(company.siret ?? "n/a")")
                }
                Section(header: Text("Documents")) {
                    if documentModel.isEmpty {
                        Text("No documents available.")
                            .foregroundColor(.gray)
                    } else {
                        List(company.documents, id: \.id) { document in
                            NavigationLink(value: document) {
                                Text(document.name ?? "n/a")
                                    .onTapGesture {
                                        handleDocumentTap(document)
                                    }
                            }
                        }
                    }
                    
                    NavigationLink(destination: {
                        ScannedImageView(company: company)
                    }) {
                        Button(action: {}) {
                            Label("Add Document", systemImage: "plus")
                        }
                    }
                }
                Section(header: Text("More")) {
                    NavigationLink(destination: MapView(
                        primaryLocation: CLLocationCoordinate2D(
                            latitude: company.primaryLocationLatitude ?? 0.0,
                            longitude: company.primaryLocationLongitude ?? 0.0
                        ),
                        secondaryLocation: CLLocationCoordinate2D(
                            latitude: company.secondaryLocationLatitude ?? 0.0,
                            longitude: company.secondaryLocationLongitude ?? 0.0
                        )
                    )) {
                        Text("View Location")
                            .padding(10)
                    }
                    
                    Button("Share Company") {
                        isSharing = true
                    }
                }
            }
        }
        .navigationTitle("Company Details")
        .sheet(isPresented: $isSharing, content: { shareView() })
        .toolbar{
            ToolbarItem(placement: .navigationBarLeading) {
                if isProcessingShare {
                    ProgressView()
                }
            }
        }
        .onAppear {
            Task {
                await shareCompany()
            }
        }
    }
    
    private func handleDocumentTap(_ document: DocumentModel) {
        if let imageURL = document.generateImageURL() {
            print("Image URL: \(imageURL)")
            GoogleDriveSingletonClass.shared.uploadFile(
                name: document.name ?? "n/a",
                folderID: company.folderID,
                fileURL: imageURL,
                mimeType: "image/jpeg",
                completion: { success in
                    if success {
                        print("File uploaded successfully.")
                    } else {
                        print("Failed to upload file.")
                        print("\(company.folderID)")
                    }
                })
        } else {
            print("Failed to generate image URL.")
        }
        
        selectedDocument = document
    }
    
    private func shareView() -> CloudSharingView? {
        guard let share = activeShare, let container = activeContainer else {
            return nil
        }
        
        return CloudSharingView(container: container, share: share)
    }
    
    private func shareCompany() async {
        isProcessingShare = true
        
        do {
            let (privateContacts, sharedContacts) = try await vm.fetchPrivateAndSharedCompanies()
            for obj in privateContacts {
                if obj.folderID == company.folderID {
                    await shareCompanyWithId(companyData: obj)
                    break
                }
            }
            print("Private Contacts", privateContacts)
            print("Shared Contacts", sharedContacts)
        } catch {
            print("Error fetching or sharing company record: \(error.localizedDescription)")
        }
        
        isProcessingShare = false
    }
    
    private func shareCompanyWithId(companyData: CompanayRemoteModel) async {
        isProcessingShare = true
        
        do {
            let (share, container) = try await vm.fetchOrCreateShare(contact: companyData)
            activeShare = share
            activeContainer = container
        } catch {
            debugPrint("Error sharing contact record: \(error)")
        }
        
        isProcessingShare = false
    }
}
