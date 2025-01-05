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
                    .disabled(documentName.isEmpty || scannedImages.isEmpty)
                    
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Document Scanner")
            .sheet(isPresented: $isScannerPresented) {
                
                if !isMac() {
                    DocumentScannerView(scannedImages: $scannedImages, isPresented: $isScannerPresented)
                    
                } else {
                    ContinuityCameraView(scannedImages: $scannedImages, isPresented: $isScannerPresented)
                    
                    
                }
                
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


/*

import SwiftUI
import VisionKit
import UIKit
//import AppKit

#if targetEnvironment(macCatalyst)
import AppKit
#endif

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

                    if isContinuityCameraAvailable() || !isMac() {
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
                        Text("Continuity Camera is not available on this device.")
                            .foregroundColor(.red)
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
#if targetEnvironment(macCatalyst)
                    ContinuityCameraView(scannedImages: $scannedImages, isPresented: $isScannerPresented)
#endif
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

    private func isContinuityCameraAvailable() -> Bool {
        if #available(macOS 10.15, *) {
            return CIFilter.localizedName(forFilterName: "CINoiseReduction") != nil
        }
        return false
    }
}



#if targetEnvironment(macCatalyst)
import SwiftUI
import AppKit

// Continuity Camera implementation for macOS
struct ContinuityCameraView: View {
    @Binding var scannedImages: [UIImage]
    @Binding var isPresented: Bool

    var body: some View {
        VStack {
            Text("Use your iPhone to scan documents via Continuity Camera.")
                .padding()

            Button("Start Scanning") {
//#if targetEnvironment(macCatalyst)
                
                openContinuityCamera()
//#endif
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)

            Button("Cancel") {
                isPresented = false
            }
            .padding()
            .foregroundColor(.red)
        }
        .frame(width: 400, height: 300)
    }
//#if targetEnvironment(macCatalyst)
    private func openContinuityCamera() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowedFileTypes = ["public.image"]
        panel.prompt = "Scan Document"

        if panel.runModal() == .OK {
            if let url = panel.url, let nsImage = NSImage(contentsOf: url), let uiImage = nsImage.toUIImage() {
                scannedImages.append(uiImage)
            }
        }
        isPresented = false
    }
//#endif
}

//#if targetEnvironment(macCatalyst)
// Extension to convert NSImage to UIImage
extension NSImage {
    func toUIImage() -> UIImage? {
        guard let tiffData = self.tiffRepresentation,
              let bitmapImageRep = NSBitmapImageRep(data: tiffData),
              let cgImage = bitmapImageRep.cgImage else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
#endif

*/





//import SwiftUI
//import VisionKit
////import UIKit
//
//#if canImport(AppKit)
//import AppKit
//#endif
//
//struct ScannedImageView: View {
//    @State private var isScannerPresented = false
//    @State private var scannedImages: [UIImage] = []
//    @State private var documentName: String = ""
//    @Environment(\.presentationMode) var presentationMode
//
//    var body: some View {
//        NavigationStack {
//            Form {
//                Section(header: Text("Fields")) {
//                    Text("POLICASTRO SERVICES")
//                        .font(.headline)
//                    Text("Boréale Project")
//                        .font(.subheadline)
//
//                    TextField("Document Name", text: $documentName)
//                        .textFieldStyle(RoundedBorderTextFieldStyle())
//                        .autocapitalization(.none)
//                }
//
//                Section(header: Text("Scanned Documents")) {
//                    if scannedImages.isEmpty {
//                        Text("No documents scanned.")
//                            .foregroundColor(.gray)
//                    } else {
//                        ScrollView {
//                            ForEach(scannedImages, id: \.self) { image in
//                                Image(uiImage: image)
//                                    .resizable()
//                                    .scaledToFit()
//                                    .frame(maxHeight: 200)
//                                    .padding()
//                            }
//                        }
//                    }
//
//                    Button(action: {
//                        isScannerPresented = true
//                    }) {
//                        Label("Scan Document", systemImage: "doc.text.viewfinder")
//                            .font(.headline)
//                            .padding()
//                            .background(Color.blue)
//                            .foregroundColor(.white)
//                            .cornerRadius(8)
//                    }
//                }
//
//                Section {
//                    Button("Save") {
//                        saveScannedDocument()
//                    }
//                    .disabled(documentName.isEmpty || scannedImages.isEmpty)
//
//                    Button("Cancel") {
//                        presentationMode.wrappedValue.dismiss()
//                    }
//                    .foregroundColor(.red)
//                }
//            }
//            .navigationTitle("Document Scanner")
//            .sheet(isPresented: $isScannerPresented) {
//                if isMacCatalyst() {
//                    ContinuityCameraView(scannedImages: $scannedImages, isPresented: $isScannerPresented)
//                } else {
//                    DocumentScannerView(scannedImages: $scannedImages, isPresented: $isScannerPresented)
//                }
//            }
//        }
//    }
//
//    private func saveScannedDocument() {
//        guard !documentName.isEmpty, !scannedImages.isEmpty else { return }
//        
//        saveLocally(scannedImages: scannedImages, name: documentName)
//        
//        uploadToGoogleDrive(scannedImages: scannedImages, name: documentName) { result in
//            switch result {
//            case .success(let sharingLink):
//                print("Document uploaded successfully. Link: \(sharingLink)")
//            case .failure(let error):
//                print("Failed to upload document: \(error.localizedDescription)")
//            }
//        }
//        
//        presentationMode.wrappedValue.dismiss()
//    }
//
//    private func saveLocally(scannedImages: [UIImage], name: String) {
//        print("Document '\(name)' saved locally with \(scannedImages.count) pages.")
//    }
//
//    private func uploadToGoogleDrive(scannedImages: [UIImage], name: String, completion: @escaping (Result<String, Error>) -> Void) {
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//            completion(.success("https://drive.google.com/file/dummy-link"))
//        }
//    }
//
////    private func isMacCatalyst() -> Bool {
////        #if targetEnvironment(macCatalyst)
////        return true
////        #else
////        return false
////        #endif
////    }
//    
//    
//    private func isMacCatalyst() -> Bool {
//        if ProcessInfo.processInfo.isiOSAppOnMac {
//            return true
//        }
//        return false
//    }
//}
//
//
//struct ContinuityCameraView: View {
//    @Binding var scannedImages: [UIImage]
//    @Binding var isPresented: Bool
//
//    var body: some View {
//        VStack {
//            Text("Continuity Camera")
//                .font(.title)
//                .padding()
//
//            Button("Capture Photo or Scan Document") {
//                showContinuityCamera()
//            }
//            .padding()
//            .background(Color.blue)
//            .foregroundColor(.white)
//            .cornerRadius(8)
//
//            Spacer()
//
//            Button("Close") {
//                isPresented = false
//            }
//            .padding(.top)
//        }
//        .frame(width: 400, height: 300)
//    }
//
//    private func showContinuityCamera() {
//        let openPanel = NSOpenPanel()
//
//        // Configure the Open Panel for Continuity Camera
//        openPanel.canChooseFiles = true
//        openPanel.canChooseDirectories = false
//        openPanel.allowsMultipleSelection = false
//        openPanel.allowedContentTypes = [.image, .pdf]
//
//        // Enable Continuity Camera
//        openPanel.isAccessoryViewDisclosed = true
//        openPanel.title = "Scan Document or Take Photo"
//        openPanel.prompt = "Use Camera"
//
//        // Show the panel
//        if openPanel.runModal() == .OK {
//            if let url = openPanel.url {
//                processSelectedFile(url: url)
//            }
//        }
//    }
//
//    private func processSelectedFile(url: URL) {
//        guard let data = try? Data(contentsOf: url) else { return }
//
//        if let image = NSImage(data: data) {
//            // Convert NSImage to UIImage for compatibility with SwiftUI
//            let uiImage = UIImage(cgImage: image.cgImage(forProposedRect: nil, context: nil, hints: nil)!)
//            scannedImages.append(uiImage)
//        } else if url.pathExtension.lowercased() == "pdf" {
//            // Handle PDF files if needed
//            print("PDF file selected at: \(url)")
//        }
//    }
//}
