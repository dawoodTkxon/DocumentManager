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
import PhotosUI

struct LoginScreen: View {
    @StateObject private var viewModel = GoogleDriveViewModel()
    @State private var folderName = "my-folder"
    @State private var isFilePickerPresented = false
    @State private var selectedFileURL: URL?
    @State private var selectedItem: PhotosPickerItem?
    
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
                
                Button("Pick a File from Gallery") {
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
                    viewModel.populateFolderID(folderName: folderName) {
                        guard let folderID = viewModel.uploadFolderID else {
                            print("Failed to retrieve or create folder ID.")
                            return
                        }
                        print("Folder ID ready: \(folderID). Proceeding with file upload.")
                        // Upload the file
                        viewModel.uploadFile(name: fileURL.lastPathComponent, fileURL: fileURL, mimeType: "application/octet-stream") { success in
                            if success {
                                print("File uploaded successfully.")
                            } else {
                                print("File upload failed.")
                            }
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
            }
        }
        .onAppear {
            viewModel.signInSilently()
        }
        .sheet(isPresented: $isFilePickerPresented) {
            PhotosPicker(
                selection: $selectedItem,
                matching: .any(of: [.images, .videos]),
                preferredItemEncoding: .current
            ) {
                Text("Pick a File from Gallery")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .onChange(of: selectedItem) { newItem in
                guard let newItem = newItem else {
                    print("Item selection failed.")
                    return
                }
                print("Item selected: \(newItem)")
                Task {
                    // Retrieve selected item from Photos Library
                    if let selectedAsset = try? await newItem.loadTransferable(type: Data.self),
                       let fileURL = saveToFileSystem(data: selectedAsset) {
                        selectedFileURL = fileURL
                        print("File selected: \(fileURL.lastPathComponent)")
                    }
                }
            }
        }
        .padding()
    }
    
    func saveToFileSystem(data: Data) -> URL? {
        let fileManager = FileManager.default
        let tempURL = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".jpg")
        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
            print("Error saving file: \(error.localizedDescription)")
            return nil
        }
    }
}

