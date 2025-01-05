//
//  ContentView.swift
//  SignInUsingGoogle
//
//  Created by Swee Kwang Chua on 12/5/22.
//

import SwiftUI
import GoogleSignIn
import GoogleAPIClientForREST
import GTMSessionFetcher
import MobileCoreServices

struct LoginScreen: View {
    @StateObject private var viewModel = GoogleDriveViewModel()
    @State private var folderName = "my-folder"
    @State private var isFilePickerPresented = false
    @State private var selectedFileURL: URL?

    var body: some View {
        VStack(spacing: 20) {
            if viewModel.isSignedIn {
                Text("Welcome, \(viewModel.googleUser?.profile?.name ?? "User")!")
                    .font(.headline)
                
                Button("Populate Folder ID") {
                    viewModel.populateFolderID(folderName: folderName) {
                        print("Folder ID: \(viewModel.uploadFolderID ?? "None")")
                    }
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                
                ScannedImageView()

                
                
                Button("Pick a File") {
                    isFilePickerPresented = true
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
                
                Button("Upload File") {
                    guard let fileURL = selectedFileURL else {
                        print("No file selected.")
                        return
                    }
                    viewModel.uploadFile(name: fileURL.lastPathComponent, fileURL: fileURL, mimeType: "application/octet-stream") { success in
                        if success {
                            print("File uploaded successfully.")
                        } else {
                            print("File upload failed.")
                        }
                    }
                }
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(8)
                
                Button("Sign Out") {
                    viewModel.signOut()
                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(8)
            } else {
                Button("Sign in with Google") {
                    if let rootVC = UIApplication.shared.windows.first?.rootViewController {
                        viewModel.signIn(presenting: rootVC)
                    }
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                
                
                Button("Upload File") {
                    guard let fileURL = selectedFileURL else {
                        print("No file selected.")
                        return
                    }
                    viewModel.uploadFile(name: fileURL.lastPathComponent, fileURL: fileURL, mimeType: "application/octet-stream") { success in
                        if success {
                            print("File uploaded successfully.")
                        } else {
                            print("File upload failed.")
                        }
                    }
                }
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .onAppear {
            viewModel.signInSilently()
        }
        .sheet(isPresented: $isFilePickerPresented) {
            FilePicker { fileURL in
                selectedFileURL = fileURL
                if let url = fileURL {
                    print("File selected: \(url.lastPathComponent)")
                } else {
                    print("No file selected.")
                }
                isFilePickerPresented = false
            }
            
        }
        .padding()
    }
}



import SwiftUI
import VisionKit

struct DocumentScannerView: UIViewControllerRepresentable {
    @Binding var scannedImages: [UIImage]
    @Binding var isPresented: Bool
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scannerViewController = VNDocumentCameraViewController()
        scannerViewController.delegate = context.coordinator
        return scannerViewController
    }
    
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
    
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        var parent: DocumentScannerView
        
        init(_ parent: DocumentScannerView) {
            self.parent = parent
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            controller.dismiss(animated: true) {
                self.parent.isPresented = false
            }
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            print("Document scanning failed with error: \(error.localizedDescription)")
            controller.dismiss(animated: true) {
                self.parent.isPresented = false
            }
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            var images: [UIImage] = []
            for pageIndex in 0..<scan.pageCount {
                images.append(scan.imageOfPage(at: pageIndex))
            }
            parent.scannedImages = images
            controller.dismiss(animated: true) {
                self.parent.isPresented = false
            }
        }
    }
}

struct ContentView: View {
    @State private var isScannerPresented = false
    @State private var scannedImages: [UIImage] = []
    
    var body: some View {
        VStack {
            if !scannedImages.isEmpty {
                ScrollView {
                    ForEach(scannedImages, id: \.self) { image in
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .padding()
                    }
                }
            } else {
                Text("No documents scanned.")
                    .foregroundColor(.gray)
            }
            
            Button(action: {
                isScannerPresented = true
            }) {
                Text("Scan Document")
                    .font(.headline)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .sheet(isPresented: $isScannerPresented) {
            DocumentScannerView(scannedImages: $scannedImages, isPresented: $isScannerPresented)
        }
    }
}
