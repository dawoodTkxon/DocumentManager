//
//  ScannedImageView.swift
//  DocumentManager
//
//  Created by TKXON on 05/01/2025.
//

import Foundation
import SwiftUI
import VisionKit
import UIKit

@available(iOS 17, *)
struct ScannedImageView: View {
    @State private var isScannerPresented = false
    @State private var scannedImages: [UIImage] = []
    @State private var documentName: String = ""
    @Environment(\.presentationMode) var presentationMode
    let company: CompanyModel
    @State private var selectedDocument: DocumentModel?
    @Environment(\.modelContext) private var modelContext
    @State private var showAlert = false
    @State private var isUploading = false
    @State private var alertMessage = ""
    var body: some View {
        ZStack {
            Form {
                Section(header: Text("Fields")) {
                    Text("Policastro Services")
                    Text("Boréale Project")
                    
                }
                Section(header: Text("Document Name")) {
                    TextField("Type here..", text: $documentName)
                        .autocapitalization(.none)
                }
                
                Section(header: Text("Scanned Documents")) {
                    if scannedImages.isEmpty {
                        Text("No documents scanned.")
                            .foregroundColor(.gray)
                    } else {
                        ScrollView {
                            ForEach(scannedImages, id: \.self) { image in
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 200)
                                    .padding()
                            }
                        }
                    }
                    Button(action: {
                        isScannerPresented = true
                    }) {
                        Label("Scan Document", systemImage: "doc.text.viewfinder")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                
                Section {
                    Button("Save") {
                        saveScannedDocument()
                        
                    }
                    .disabled(documentName.isEmpty || scannedImages.isEmpty)
                    
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.red)
                }
            }
            
            if isUploading {
                LoaderView()
            }
        }
        .navigationTitle("Scanner")
        .alert("Confirmation", isPresented: $showAlert) {
            Button("OK") {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $isScannerPresented) {
            
            if !isMac() {
                DocumentScannerView(scannedImages: $scannedImages, isPresented: $isScannerPresented)
                
            } else {
                ContinuityCameraView(scannedImages: $scannedImages, isPresented: $isScannerPresented)
                
                
            }
            
        }
        
    }
    
    private func saveScannedDocument() {
        guard !documentName.isEmpty, let scannedImage = scannedImages.first else { return }
        
        let imageName = "\(documentName)_image.jpg"
        
        guard let imageData = scannedImage.jpegData(compressionQuality: 0.8) else { return }
        
        let newDocument = DocumentModel(
            name: documentName,
            type: .image,
            company: company,
            image: scannedImage,
            imageName: imageName
        )
        modelContext.insert(newDocument)
        do {
            try modelContext.save()
            if let imageURL = newDocument.generateImageURL() {
                isUploading = true
                GoogleSignInManager.shared.uploadFile(
                    name: newDocument.name ?? "n/a",
                    folderID: company.folderID,
                    fileURL: imageURL,
                    mimeType: "image/jpeg",
                    completion: { success in
                        if success {
                            isUploading = false
                            showAlert = true
                            alertMessage = "Document saved successfully."
                            selectedDocument = newDocument
                            print("Document saved successfully.")
                        } else {
                            alertMessage = "Failed to save document. Please try again."
                            showAlert = true
                        }
                    })
            }
        }catch{
            alertMessage = "Error saving document: \(error.localizedDescription)"
            showAlert = true
        }
    }
    
    
    private func isMac() -> Bool {
        if ProcessInfo.processInfo.isiOSAppOnMac {
            return true
        }
        return false
    }
}
