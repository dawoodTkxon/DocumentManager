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


@available(iOS 17, *)
struct CompanyDetailView: View {
    var company: CompanyModel
    @Query private var documentModel: [CompanyModel]
    let googleDriveService = GTLRDriveService()
    @State private var isScannerPresented = false
    @State private var scannedImages: [UIImage] = []
    @State private var selectedDocument: DocumentModel?

    var body: some View {
        VStack{
            Form {
                Section(header: Text("Company Details")) {
                    Text("Name: \(company.name)")
                    Text("SIRET: \(company.siret)")
                }
                Section(header: Text("Documents")) {
                    if documentModel.isEmpty {
                        Text("No documents available.")
                            .foregroundColor(.gray)
                    } else {
                        List(company.documents, id: \.id) { document in
                            NavigationLink(
                                destination: DocumentView(document: document),
                                tag: document,
                                selection: $selectedDocument
                            ) {
                                Text(document.name)
                                    .onTapGesture {
                                        handleDocumentTap(document)
                                    }
                            }
                        }
                    }
                    NavigationLink(destination: {
                        return ScannedImageView(company: company)
                    }) {
                        Button(action: {}) {
                            Label("Add Document", systemImage: "plus")
                        }
                    }
                    
                }
                Section(header: Text("More")) {
                    Section {
                        NavigationLink(destination: ScannedImageView(company: company)) {
                            Text("View Location")
                        }
                        
                        Button("Share Company") {
                            
                        }
                    }
                }
            }
        }
        .navigationTitle("Company Details")
        
    }
    private func handleDocumentTap(_ document: DocumentModel) {
        if let imageURL = document.generateImageURL() {
            print("Image URL: \(imageURL)")
            GoogleDriveSingletonClass.shared.uploadFile(
                name: document.name,
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
}




//                        List(company.documents, id: \.id) { document in
//                            Text(document.name)
//                                .onTapGesture {
//                                    if let imageURL = document.generateImageURL() {
//                                        print("Image URL: \(imageURL)")
//                                        GoogleDriveSingletonClass.shared.uploadFile(
//                                            name: document.name,
//                                            folderID: company.folderID,
//                                            fileURL: imageURL,
//                                            mimeType: "image/jpeg",
//                                            completion: { success in
//                                                if success {
//                                                    print("File uploaded successfully.")
//                                                } else {
//                                                    print("Failed to upload file.")
//                                                    print("\(company.folderID)")
//                                                }
//                                            })
//                                    } else {
//                                        print("Failed to generate image URL.")
//                                    }
//
//                                }
//
//
//                            NavigationLink(destination: DocumentView(document: document)) {
//                                Text(document.name)
//                            }
//                        }
