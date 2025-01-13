//
//  CompanyDetailView.swift
//
//
//  Created by TKXON on 05/01/2025.
//

import SwiftUI
import MapKit
import SwiftData
import AppKit
import CloudKit
import GoogleSignIn
import GoogleAPIClientForREST
import GTMSessionFetcher




@available(macOS 13.0, *)
struct CompanyDetailMacOSView: View {
    var company: CompanyModel
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var vm: CloudKitViewModel
    @State private var sharedCompanyData: CompanayRemoteModel?
    @State private var selectedDocument: DocumentModel?

    @State private var activeShare: CKShare?
    @State private var activeContainer: CKContainer?
    

    @State private var isUploading: Bool = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var navigate = false
    @State private var isSharing = false
    @State private var showPicker = false
    @State private var isProcessingShare = false
    @State private var fileURL: URL?
    @State private var inspectorIsShown: Bool = false
    @State private var isCreatingFolder = false
    
    var body: some View {
        ZStack{
            ScrollView {
                companyDetailsSection
            }
            .padding()
            
            if isProcessingShare {
                LoaderView()
            }
        }
        .background(Group{ if showPicker{shareView()}})
        .navigationTitle("Company Details")
        .inspector(isPresented: $inspectorIsShown) {
            Group {
                if let document = selectedDocument {
                    DocumentView(document: document)
                }
                
                if let sharedCompanyData = sharedCompanyData {
                    EditCompanyMacOSView(sharedCompanyData: sharedCompanyData, company: company)
                }
            }
        }
        .onAppear{
            
            createFolderIfNotExists()
            
            
            
        }
        .onChange(of: company) { oldValue,newValue in
            createFolderIfNotExists()
            print("Company changed name to \(newValue.name)" )
            
        
        }
    }
    // MARK: - Sections
    private var companyDetailsSection: some View {
        VStack(alignment: .leading, spacing: 20){
            HStack(alignment: .bottom,spacing: 20){
                VStack(alignment: .leading, spacing: 10) {
                    Text("Company Details")
                        .font(.title)
                        .fontWeight(.medium)
                    
                    Text("Name: \(sharedCompanyData?.name ?? "")")
                        .font(.callout)
                    
                    Text("Siret: \(sharedCompanyData?.siret ?? "")")
                        .font(.callout)
                    
                }
                
                
                actionsSection
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Documents")
                    .font(.title)
                    .fontWeight(.medium)
                if company.documents.isEmpty {
                    Text("No documents available.")
                        .foregroundColor(.gray)
                        .font(.headline)
                } else {
                    ForEach(company.documents, id: \.id) { document in
                        Text(document.name ?? "n/a")
                            .onTapGesture {
                                selectedDocument = document
                                inspectorIsShown.toggle()
                            }
                    }
                }
            }
            
        }
    }
    private var actionsSection: some View {
        HStack(spacing: 20) {
            NavigationLink(destination: MapView(
                primaryLocation: CLLocationCoordinate2D(
                    latitude: company.primaryLocationLatitude,
                    longitude: company.primaryLocationLongitude),
                secondaryLocation: CLLocationCoordinate2D(
                    latitude: company.secondaryLocationLatitude,
                    longitude: company.secondaryLocationLongitude))) {
                        Text("View Location")
                    }
            
            Button(action: {showPicker = true}) {Text("Share Company")}
            
            Button(action: {inspectorIsShown.toggle()}) {Text("Edit Company")}
            
            
            Spacer()
            
            HStack {
                Text("Add Document")
                Image(systemName: "plus")
                
            }
            .font(.headline)
            .padding(10)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(4)
            .onTapGesture {
                navigate = true
            }
            .background(
                NavigationLink(
                    destination: ScannedImageView(company: company),
                    isActive: $navigate) {}.hidden())
        }
    }
    private func fetchSharedCompany() async {
        isProcessingShare = true
        do {
            let (privateContacts, sharedContacts) = try await vm.fetchPrivateAndSharedCompanies()
            if privateContacts.contains(where: {$0.folderID == company.folderID}){
                for obj in privateContacts {
                    if obj.folderID == company.folderID {
                        sharedCompanyData = obj
                        
                        if let sharedCompanyData = self.sharedCompanyData{
                            company.name = sharedCompanyData.name
                            company.siret = sharedCompanyData.siret
                            company.primaryLocationLatitude = sharedCompanyData.primaryLocationLatitude
                            company.primaryLocationLongitude = sharedCompanyData.primaryLocationLongitude
                            company.folderID = sharedCompanyData.folderID
                        }
                        
                        if let sharedCompanyData = sharedCompanyData {
                            do {
                                let (share, container) = try await vm.fetchOrCreateShare(company: sharedCompanyData)
                                activeShare = share
                                activeContainer = container
                                self.fileURL = saveCKShareToTemporaryFile(share)
                                
                                isProcessingShare = false
                                
                            } catch {
                                debugPrint("Error sharing contact record: \(error)")
                                isProcessingShare = false
                            }
                        }
                        break
                    }
                }
            }
            else if sharedContacts.contains(where: {$0.folderID == company.folderID}){
                for obj in sharedContacts {
                    if obj.folderID == company.folderID {
                        sharedCompanyData = obj
                        print("sharedCompanyData..\(obj.siret)")
                        
                        if let sharedCompanyData = self.sharedCompanyData{
                            company.name = sharedCompanyData.name
                            company.siret = sharedCompanyData.siret
                            company.primaryLocationLatitude = sharedCompanyData.primaryLocationLatitude
                            company.primaryLocationLongitude = sharedCompanyData.primaryLocationLongitude
                            company.folderID = sharedCompanyData.folderID
                        }

                        if let sharedCompanyData = sharedCompanyData {
                            do {
                                let (share, container) = try await vm.fetchOrCreateShare(company: sharedCompanyData)
                                activeShare = share
                                activeContainer = container
                                print("Share ActiveShare\(share)")
                                print("Share ActiveContainer \(container)")
                                self.fileURL = saveCKShareToTemporaryFile(share)
                                
                                isProcessingShare = false
                                
                            } catch {
                                debugPrint("Error sharing contact record: \(error)")
                                isProcessingShare = false
                            }
                        }
                        break
                    }
                }
            }
    
        } catch {
            print("Error fetching or sharing company record: \(error.localizedDescription)")
            isProcessingShare = false
        }
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
    private func createFolderIfNotExists() {
        if company.folderID != "" {
            print("Folder already exists with ID: \(company.folderID)")
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
                            print("Company saved successfully with folderID: \(folderID).")
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
    
    private func newShareView() -> SharingView? {
        guard let fileURL = fileURL else {
            return nil
        }
        return SharingView(fileURL: fileURL)
    }
    
    
    func saveCKShareToTemporaryFile(_ share: CKShare) -> URL? {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: share, requiringSecureCoding: true)
            let tempDirectory = FileManager.default.temporaryDirectory
            let fileURL = tempDirectory.appendingPathComponent("CKShare.share")
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Error saving CKShare: \(error)")
            return nil
        }
    }
    
    func presentSharingService(for fileURL: URL, from view: NSView) {
        let sharingServicePicker = NSSharingServicePicker(items: [fileURL])
        sharingServicePicker.show(relativeTo: .zero, of: view, preferredEdge: .minY)
    }
    
}



extension CompanyDetailMacOSView {
    
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
                                    guard let image = NSImage(data: imageData) else {
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
                                    
                                    guard let newImageURL = newDocument.generateImageURL() else {
                                        print("Failed to generate a temporary image URL.")
                                        return
                                    }
                                    
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
