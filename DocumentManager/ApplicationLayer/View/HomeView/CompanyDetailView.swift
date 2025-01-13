//
//  CompanyDetailView.swift
//  DocumentManager
//
//  Created by TKXON on 05/01/2025.
//

import MapKit
import SwiftUI
import CloudKit
import SwiftData
import GoogleSignIn
import GTMSessionFetcher
import GoogleAPIClientForREST

@available(iOS 17, *)
struct CompanyDetailView: View {
    
    @EnvironmentObject private var vm: CloudKitViewModel
    @Environment(\.modelContext) private var modelContext
    @Query private var documentModel: [CompanyModel]
    let googleDriveService = GTLRDriveService()
    
    @State private var isScannerPresented = false
    @State private var scannedImages: [UIImage] = []
    @State private var selectedDocument: DocumentModel?
    
    @State private var isSharing = false
    @State private var isProcessingShare = false
    @State private var activeShare: CKShare?
    @State private var activeContainer: CKContainer?
    @State private var sharedCompanyData: CompanayRemoteModel?
    @State private var isCreatingFolder = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    var company: CompanyModel
    
    var body: some View {
        ZStack{
            VStack {
                Form {
                    Section(header: Text("Company Details")) {
                        Text("Name: \(company.name)")
                        Text("Siret: \(company.siret)")
                    }
                    Section(header: Text("Documents")) {
                        if documentModel.isEmpty {
                            Text("No documents available.")
                                .foregroundColor(.gray)
                        } else {
                            List(company.documents, id: \.id) { document in
                                
                                NavigationLink(destination: {
                                    DocumentView(document: document)
                                }) {
                                    Button(action: {}) {
                                        Text(document.name ?? "n/a")
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
                                latitude: company.primaryLocationLatitude,
                                longitude: company.primaryLocationLongitude
                            ),
                            secondaryLocation: CLLocationCoordinate2D(
                                latitude: company.secondaryLocationLatitude,
                                longitude: company.secondaryLocationLongitude
                            )
                        )) {
                            Text("View Location")
                                .padding(10)
                        }
                        
                        
                        NavigationLink(destination: {
                            if let sharedCompanyData = sharedCompanyData {
                                EditCompanyView(sharedCompanyData: sharedCompanyData, company: company)
                            }
                        }) {
                            Text("Edit Company")
                        }
                        
                        
                        Button("Share Company") {
                            isSharing = true
                            if let sharedData = sharedCompanyData {
                                Task{ await shareCompanyWithId(companyData: sharedData)}
                            }
                        }
                    }
                }
            }
            if isProcessingShare {
                LoaderView()
            }
        }
        .navigationTitle("Company Details")
        .sheet(isPresented: $isSharing, content: { shareView() })
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK")))}
        .onAppear {
            createFolderIfNotExists()
            fetchAndSaveFiles()
        }
    }
    private func createFolderIfNotExists() {
        if company.folderID != "" {
            Task{ await fetchSharedCompany()}
            fetchAndSaveFiles()
            return
        }
        else{
            isCreatingFolder = true
            isProcessingShare = true
            GoogleSignInManager.shared.createFolder(name: company.name) { folderID in
                if let folderID = folderID {
                    company.folderID  = folderID
                    do {
                        try modelContext.save()
                        Task{
                            let status = try await vm.addNewCompnay(
                                name:  company.name ,
                                siret:  company.siret,
                                primaryLocationLatitude: company.primaryLocationLatitude,
                                primaryLocationLongitude: company.primaryLocationLatitude,
                                secondaryLocationLatitude: company.primaryLocationLatitude,
                                secondaryLocationLongitude: company.primaryLocationLatitude,
                                folderID: folderID
                            )
                            
                            if status{
                                print("Company created successfully in Icoud", status)
                                Task{ await fetchSharedCompany()}
                                isProcessingShare = false
                            }
                        }
                    } catch {
                        alertMessage = "Failed to save company: \(error.localizedDescription)"
                    }
                } else {
                    alertMessage = "Failed to create folder."
                }
            }
        }
        
    }
    private func shareView() -> CloudSharingView? {
        guard let share = activeShare, let container = activeContainer else {
            return nil
        }
        
        return CloudSharingView(container: container, share: share)
    }
    
    private func fetchSharedCompany() async {
        isProcessingShare = true
        do {
            let (privateCompany, sharedCompany) = try await vm.fetchPrivateAndSharedCompanies()
            for obj in privateCompany {
                if obj.folderID == company.folderID {
                    sharedCompanyData = obj
                    isProcessingShare = false
                    
                    if let sharedCompanyData = self.sharedCompanyData {
                        
                        company.name = sharedCompanyData.name
                        company.siret = sharedCompanyData.siret
                        company.primaryLocationLatitude = sharedCompanyData.primaryLocationLatitude
                        company.primaryLocationLongitude = sharedCompanyData.primaryLocationLongitude
                        company.secondaryLocationLatitude = sharedCompanyData.secondaryLocationLatitude
                        company.secondaryLocationLatitude = sharedCompanyData.secondaryLocationLatitude
                        Task{try modelContext.save()}
                        
                    }
                    return
                }
                
                for obj in sharedCompany {
                    if obj.folderID == company.folderID {
                        sharedCompanyData = obj
                        isProcessingShare = false
                        
                        if let sharedCompanyData = self.sharedCompanyData {
                            
                            company.name = sharedCompanyData.name
                            company.siret = sharedCompanyData.siret
                            company.primaryLocationLatitude = sharedCompanyData.primaryLocationLatitude
                            company.primaryLocationLongitude = sharedCompanyData.primaryLocationLongitude
                            company.secondaryLocationLatitude = sharedCompanyData.secondaryLocationLatitude
                            company.secondaryLocationLatitude = sharedCompanyData.secondaryLocationLatitude
                            Task{try modelContext.save()}
                            
                        }
                        return
                    }
                    
                    
                }
            }
            print("Private Contacts", privateCompany)
            print("Shared Contacts", sharedCompany)
            
            Task{
                let status = try await vm.addNewCompnay(
                    name: sharedCompanyData?.name ?? "",
                    siret: sharedCompanyData?.siret ?? "",
                    primaryLocationLatitude: sharedCompanyData?.primaryLocationLatitude ?? 0.0,
                    primaryLocationLongitude: sharedCompanyData?.primaryLocationLongitude ?? 0.0,
                    secondaryLocationLatitude: sharedCompanyData?.secondaryLocationLatitude ?? 0.0,
                    secondaryLocationLongitude: sharedCompanyData?.secondaryLocationLongitude ?? 0.0,
                    folderID: sharedCompanyData?.folderID ?? "")
                
                if status {
                    print("Company created successfully in Icoud", status)
                    Task{ await fetchSharedCompany()}
                    isProcessingShare = false
                }
            }
            
        } catch {
            print("Error fetching or sharing company record: \(error.localizedDescription)")
        }
        
        isProcessingShare = false
    }
    
    private func shareCompanyWithId(companyData: CompanayRemoteModel) async {
        isProcessingShare = true
        
        do {
            let (share, container) = try await vm.fetchOrCreateShare(company: companyData)
            activeShare = share
            activeContainer = container
        } catch {
            debugPrint("Error sharing contact record: \(error)")
        }
        
        isProcessingShare = false
    }
}


@available(iOS 17, *)
extension CompanyDetailView {
    
    private func fetchAndSaveFiles() {
        if company.folderID != ""{
            GoogleSignInManager.shared.listFiles(inFolder: company.folderID) { files in
                guard let files = files, !files.isEmpty else {
                    print("No files found in the folder.")
                    return
                }
                
                let existingDocuments = fetchExistingDocuments()
                
                for file in files {
                    if !existingDocuments.contains(where: { $0.name == file.name }) {
                        guard let fileName = file.name,
                              let mimeType = file.mimeType,
                              mimeType.hasPrefix("image/jpeg"),
                              let fileID = file.identifier else { continue }
                        
                        GoogleSignInManager.shared.downloadFile(fileID: fileID) { fileURL in
                            if let fileURL = fileURL {
                                do {
                                    let imageData = try Data(contentsOf: fileURL)
                                    guard let image = UIImage(data: imageData) else {
                                        print("Failed to create image from data.")
                                        return
                                    }
                                    
                                    let newDocument = DocumentModel(
                                        name: fileName,
                                        type: .image,
                                        company: company,
                                        image: image,
                                        imageName: fileName
                                    )
                                    
                                    
                                    if isDuplicate(name: fileName, existingDocuments: existingDocuments) {
                                        print("Duplicate image found: \(fileName). Skipping insertion.")
                                    } else {
                                        print("Inserting new document: \(fileName).")
                                        modelContext.insert(newDocument)
                                        do {
                                            try modelContext.save()
                                        } catch {
                                            print("Error saving new document: \(error)")
                                        }
                                    }
                                } catch {
                                    print("Error processing image: \(error)")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// Fetch existing documents with their URLs and names from SwiftData
    private func fetchExistingDocuments() -> [(name: String, url: URL)] {
        return company.documents.compactMap { document in
            guard let name = document.name,
                  let url = document.generateImageURL() else {
                return nil
            }
            return (name: name, url: url)
        }
    }
    
    /// Check for duplicates by comparing both name and URL
    private func isDuplicate(name: String, existingDocuments: [(name: String, url: URL)]) -> Bool {
        return existingDocuments.contains { $0.name == name }
    }
    
}
