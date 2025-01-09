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

#if os(macOS)
import AppKit
#endif

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
        ZStack{
            if isUploading {
                ProgressView("Uploading...")
                    .padding()
            }
            VStack {
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
                        .disabled(documentName.isEmpty || scannedImages.isEmpty)
                        
                        Button("Cancel") {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .foregroundColor(.red)
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
        }
        
    }
    private func handleDocumentTap(_ document: DocumentModel) {
        
        selectedDocument = document
    }
    private func saveScannedDocument() {
        guard !documentName.isEmpty, let scannedImage = scannedImages.first else { return }
        
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
        
        if let imageURL = newDocument.generateImageURL() {
            isUploading = true
            GoogleDriveSingletonClass.shared.uploadFile(
                name: newDocument.name ?? "n/a",
                folderID: company.folderID,
                fileURL: imageURL,
                mimeType: "image/jpeg",
                completion: { success in
                    if success {
                        // Save the context
                        do {
                            try modelContext.save()
                            print("Document saved successfully.")
                            isUploading = false
                            alertMessage = "Document saved successfully."
                            showAlert = true
                        } catch {
                            print("Failed to save document: \(error)")
                            isUploading = false
                            alertMessage = "Failed to save document. Please try again."
                            showAlert = true
                        }
                        print("File uploaded successfully.")
                    } else {
                        isUploading = false
                        print("Failed to upload file.")
                        print("\(company.folderID)")
                        alertMessage = "Failed to upload file."
                        showAlert = true
                    }
                })
            
        }
        
        
    }
    private func uploadToGoogleDrive(scannedImages: [UIImage], name: String, completion: @escaping (Result<String, Error>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            completion(.success("https://drive.google.com/file/dummy-link"))
        }
    }
    
    private func isMac() -> Bool {
        if ProcessInfo.processInfo.isiOSAppOnMac {
            return true
        }
        return false
    }
}

// A SwiftUI wrapper for VNDocumentCameraViewController
@available(iOS 13.0, *)
struct ScannerViewControllerWrapper: UIViewControllerRepresentable {
    @Binding var scannedImages: [UIImage]
    
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let viewController = VNDocumentCameraViewController()
        viewController.delegate = context.coordinator
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
    
    // Create a Coordinator to handle delegate methods
    func makeCoordinator() -> Coordinator {
        return Coordinator(scannedImages: $scannedImages)
    }
    
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        @Binding var scannedImages: [UIImage]
        
        init(scannedImages: Binding<[UIImage]>) {
            _scannedImages = scannedImages
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            for pageIndex in 0..<scan.pageCount {
                let image = scan.imageOfPage(at: pageIndex)
                scannedImages.append(image)
            }
            controller.dismiss(animated: true, completion: nil)
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            controller.dismiss(animated: true, completion: nil)
        }
    }
}

// Extension to convert NSImage to UIImage on macOS
#if os(macOS)
extension NSImage {
    func toUIImage() -> UIImage? {
        let data = self.tiffRepresentation
        guard let bitmapImageRep = NSBitmapImageRep(data: data!),
              let cgImage = bitmapImageRep.cgImage else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
#endif



import SwiftUI
import VisionKit
import UIKit

struct ScannedImageViewaa: View {
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
                    
                    // Enable scanner button on macOS only if Continuity Camera is available
                    if isMac() {
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
                    } else {
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
            .navigationTitle("Document Scanner")
            .sheet(isPresented: $isScannerPresented) {
                if isMac() {
                    ContinuityCameraView(scannedImages: $scannedImages, isPresented: $isScannerPresented)
                } else {
                    DocumentScannerView(scannedImages: $scannedImages, isPresented: $isScannerPresented)
                }
            }
        }
    }
    
    private func saveScannedDocument() {
        guard !documentName.isEmpty, !scannedImages.isEmpty else { return }
        
        saveLocally(scannedImages: scannedImages, name: documentName)
        
        uploadToGoogleDrive(scannedImages: scannedImages, name: documentName) { result in
            switch result {
            case .success(let sharingLink):
                print("Document uploaded successfully. Link: \(sharingLink)")
            case .failure(let error):
                print("Failed to upload document: \(error.localizedDescription)")
            }
        }
        
        presentationMode.wrappedValue.dismiss()
    }
    
    private func saveLocally(scannedImages: [UIImage], name: String) {
        print("Document '\(name)' saved locally with \(scannedImages.count) pages.")
    }
    
    private func uploadToGoogleDrive(scannedImages: [UIImage], name: String, completion: @escaping (Result<String, Error>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            completion(.success("https://drive.google.com/file/dummy-link"))
        }
    }
    
    private func isMac() -> Bool {
        if ProcessInfo.processInfo.isiOSAppOnMac {
            return true
        }
        return false
    }
}

// A SwiftUI view that wraps Continuity Camera on macOS/Mac Catalyst
@available(iOS 13.0, *)
struct ContinuityCameraView: View {
    @Binding var scannedImages: [UIImage]
    @Binding var isPresented: Bool
    
    var body: some View {
        ContinuityCameraWrapper(scannedImages: $scannedImages, isPresented: $isPresented)
    }
}

// A UIViewControllerRepresentable to use Continuity Camera on macOS/Mac Catalyst
@available(iOS 13.0, *)
struct ContinuityCameraWrapper: UIViewControllerRepresentable {
    @Binding var scannedImages: [UIImage]
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let pickerController = UIImagePickerController()
        pickerController.sourceType = .camera
        pickerController.cameraDevice = .front
        pickerController.delegate = context.coordinator
        return pickerController
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(scannedImages: $scannedImages, isPresented: $isPresented)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        @Binding var scannedImages: [UIImage]
        @Binding var isPresented: Bool
        
        init(scannedImages: Binding<[UIImage]>, isPresented: Binding<Bool>) {
            _scannedImages = scannedImages
            _isPresented = isPresented
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                scannedImages.append(image)
            }
            isPresented = false
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            isPresented = false
        }
    }
}


