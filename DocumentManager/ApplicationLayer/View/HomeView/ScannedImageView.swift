//
//  ScannedImageView.swift
//  DocumentManager
//
//  Created by TKXON on 05/01/2025.
//

import Foundation
import SwiftUI

struct ScannedImageView: View {
    @State private var isScannerPresented = false
    @State private var scannedImages: [UIImage] = []
    @State private var documentName: String = ""
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Fields")) {
                    Text("POLICASTRO SERVICES")
                        .font(.headline)
                    Text("Boréale Project")
                        .font(.subheadline)
                    
                    TextField("Document Name", text: $documentName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
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
                            .font(.headline)
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
                    .disabled(documentName.isEmpty || scannedImages.isEmpty) // Enable only when valid
                    
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Document Scanner")
            .sheet(isPresented: $isScannerPresented) {
                DocumentScannerView(scannedImages: $scannedImages, isPresented: $isScannerPresented)
            }
        }
    }
    
    private func saveScannedDocument() {
        // Save document locally and upload to Google Drive
        guard !documentName.isEmpty, !scannedImages.isEmpty else { return }
        
        // 1. Save locally (e.g., using FileManager or CoreData).
        saveLocally(scannedImages: scannedImages, name: documentName)
        
        // 2. Upload to Google Drive and retrieve sharing link.
        uploadToGoogleDrive(scannedImages: scannedImages, name: documentName) { result in
            switch result {
            case .success(let sharingLink):
                print("Document uploaded successfully. Link: \(sharingLink)")
            case .failure(let error):
                print("Failed to upload document: \(error.localizedDescription)")
            }
        }
        
        // Dismiss the view after saving
        presentationMode.wrappedValue.dismiss()
    }
    
    private func saveLocally(scannedImages: [UIImage], name: String) {
        // Implement saving to local storage
        print("Document '\(name)' saved locally with \(scannedImages.count) pages.")
    }
    
    private func uploadToGoogleDrive(scannedImages: [UIImage], name: String, completion: @escaping (Result<String, Error>) -> Void) {
        // Use Google Drive API to upload
        // Simulated response:
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            completion(.success("https://drive.google.com/file/dummy-link"))
        }
    }
}
