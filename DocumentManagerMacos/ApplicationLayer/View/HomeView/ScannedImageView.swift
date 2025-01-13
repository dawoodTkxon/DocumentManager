//
//  ScannedImageView.swift
//  DocumentManagerMacOS
//
//  Created by TKXON on 05/01/2025.
//

import Foundation
import SwiftUI
import VisionKit

#if os(macOS)
import AppKit
import UniformTypeIdentifiers
#endif

@available(iOS 17, *)

struct ScannedImageView: View {
    @State private var isScannerPresented = false
    @State private var documentName: String = ""
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dismiss) private var dismiss
    
    let company: CompanyModel
    @Environment(\.modelContext) private var modelContext
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    @State private var image: NSImage?
    @State private var icon: NSImage?
    @State private var fileType: UTType?
    @State private var fileName: String?
    @State private var message: String?
    @State private var hovering = false
    @State private var isUploading = false
    @State private var selectedDocument: DocumentModel?
    
    
    var body: some View {
        VStack {
            HStack{
                
                VStack(alignment: .leading, spacing: 20) {
                    Text("Policastro Service")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Boréale Project")
                        .font(.subheadline)
                    
                    labeledTextField(title: "Enter document name", text: $documentName)
                    
                    
                    Section(header: Text("Scanned Documents")) {
                        if image == nil {
                            Text("No documents scanned.")
                                .foregroundColor(.gray)
                        } else {
                            
                            if let image = self.image {
                                Image(nsImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 200)
                                    .padding()
                            }
                        }
                    }
                    
                    Section {
                        
                        
                        Text("Right Click to add Document")
                            .font(.headline)
                            .padding(10)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                            .allowsHitTesting(false)
                            .background(
                                ContinuityCameraStartView(placeholder: "") { data, fileType in
                                    print("ContinuityCamera is sending \(fileType): \(data)")
                                    self.showImage(data: data, fileType: fileType)
                                    return true
                                }
                            )
                        
                        HStack{
                            
                            Button("Save") {
                                saveScannedDocument()
                            }
                            
                            Button("Cancel") {
                                presentationMode.wrappedValue.dismiss()
                            }
                            .foregroundColor(.red)
                            
                            Spacer()
                            
                            Button("Back") {
                                presentationMode.wrappedValue.dismiss()
                            }
                            .foregroundColor(.red)
                        }
                    }
                    
                }
                
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .padding()
            .onDrop(of: [.fileURL], isTargeted: $hovering, perform: { (itemProviders, targetPosition) -> Bool in
                let urlIdentifier = UTType.fileURL.identifier
                for itemProvider in itemProviders {
                    if itemProvider.hasItemConformingToTypeIdentifier(urlIdentifier) {
                        itemProvider.loadItem(forTypeIdentifier: urlIdentifier, options: nil, completionHandler: { (item, error) in
                            if let error = error {
                                print(error)
                            }
                            if let item = item,
                               let data = item as? Data,
                               let url = URL(dataRepresentation: data, relativeTo: nil),
                               let data = try? Data(contentsOf: url),
                               let fileType = UTType(filenameExtension: url.pathExtension)
                            {
                                self.showImage(data: data, fileType: fileType, fileName: url.lastPathComponent)
                            }
                            else {
                                print("Something is wrong with the data: \(String(describing: item))")
                            }
                        })
                        return true
                    }
                }
                return false
            })
            .sheet(isPresented: $isScannerPresented) {
                
                if !isMac() {
                    DocumentScannerView(scannedImage: $image, isPresented: $isScannerPresented)
                    
                } else {
                    ContinuityCameraView(scannedImage: $image, isPresented: $isScannerPresented)
                    
                    
                }
                
            }
        }
        
    }
    private func showImage(data: Data, fileType: UTType, fileName: String = "No Name") {
        let nsImage = NSImage(data: data)
        DispatchQueue.main.async {
            self.image = nsImage
            self.fileType = fileType
            self.icon = NSWorkspace.shared.icon(for: fileType)
            self.fileName = fileName
            self.message = nsImage == nil ? "Not a valid image" : nil
        }
    }
    
    
    private func saveScannedDocument() {
        guard !documentName.isEmpty, let scannedImage = image else { return }
        
        let imageName = "\(documentName)_image.jpg"  // You can modify this as needed
        
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
    
    
    
    private func labeledTextField(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.headline)
            TextField("", text: text)
                .frame(maxWidth: 300)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
    
    
    private func isMac() -> Bool {
        if ProcessInfo.processInfo.isiOSAppOnMac {
            return true
        }
        return false
    }
}
