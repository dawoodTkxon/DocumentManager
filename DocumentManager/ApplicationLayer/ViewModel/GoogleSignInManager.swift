//
//  GoogleSignInManager.swift
//  DocumentManager
//
//  Created by TKXON on 03/01/2025.
//

import SwiftUI
import GoogleSignIn
import GoogleAPIClientForREST
import GTMSessionFetcher
import MobileCoreServices

class GoogleDriveViewModel: ObservableObject {
    @Published var googleUser: GIDGoogleUser?
    @Published var isSignedIn = false
    @Published var uploadFolderID: String?
    @Published var userName: String?
    
    private let signInConfig = GIDConfiguration(clientID: "1008713916759-8rrrh8ifpt8gu90409pnoghor0j4k5k5.apps.googleusercontent.com")
    let googleDriveService = GTLRDriveService()
    
    
    func signIn(presenting viewController: UIViewController) {
            GIDSignIn.sharedInstance.signIn(with: signInConfig, presenting: viewController) { [weak self] user, error in
                if let error = error {
                    print("Sign-in failed: \(error.localizedDescription)")
                    self?.googleUser = nil
                    self?.isSignedIn = false
                } else if let user = user {
                    self?.googleUser = user
                    self?.googleDriveService.authorizer = user.authentication.fetcherAuthorizer()
                    self?.isSignedIn = true
                    self?.userName = user.profile?.name

                    // Print Google ID and User Name
                    print("Google ID: \(user.userID ?? "No ID")")
                    print("User Name: \(user.profile?.name ?? "No Name")")
                }
            }
        }
    
//    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
//           if error == nil {
//               self.googleDriveService.authorizer = user.authentication.fetcherAuthorizer()
//               self.googleUser = user
//           } else {
//               self.googleDriveService.authorizer = nil
//               self.googleUser = nil
//           }
//       }
    
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        googleUser = nil
        isSignedIn = false
        uploadFolderID = nil
    }
    func signInSilently() {
        GIDSignIn.sharedInstance.restorePreviousSignIn { [weak self] user, error in
            if let user = user {
                self?.googleUser = user
                self?.isSignedIn = true
                self?.userName = user.profile?.name
            } else if let error = error {
                print("Silent Sign-In failed: \(error.localizedDescription)")
            }
        }
    }
    func getFolderID(name: String, completion: @escaping (String?) -> Void) {
        guard let user = googleUser else { return }
        
        let query = GTLRDriveQuery_FilesList.query()
        query.spaces = "drive"
        query.corpora = "user"
        query.q = "name = '\(name)' and mimeType = 'application/vnd.google-apps.folder' and '\(user.profile?.email ?? "")' in owners"
        
        googleDriveService.executeQuery(query) { (_, result, error) in
            if let error = error {
                print("Error retrieving folder ID: \(error.localizedDescription)")
                completion(nil)
            } else {
                let folderList = result as? GTLRDrive_FileList
                completion(folderList?.files?.first?.identifier)
            }
        }
    }
    
    func createFolder(name: String, completion: @escaping (String) -> Void) {
        let folder = GTLRDrive_File()
        folder.name = name
        folder.mimeType = "application/vnd.google-apps.folder"
        
        let query = GTLRDriveQuery_FilesCreate.query(withObject: folder, uploadParameters: nil)
        googleDriveService.executeQuery(query) { (_, result, error) in
            if let error = error {
                print("Error creating folder: \(error.localizedDescription)")
            } else {
                let createdFolder = result as? GTLRDrive_File
                completion(createdFolder?.identifier ?? "")
            }
        }
    }
    
    
    func populateFolderID(folderName: String, completion: @escaping () -> Void) {
        getFolderID(name: folderName) { [weak self] folderID in
            if let folderID = folderID {
                self?.uploadFolderID = folderID
                completion()
            } else {
                self?.createFolder(name: folderName) { createdFolderID in
                    self?.uploadFolderID = createdFolderID
                    completion()
                }
            }
        }
    }
    
    func uploadFile(name: String, fileURL: URL, mimeType: String, completion: @escaping (Bool) -> Void) {
        guard let folderID = uploadFolderID else {
            print("Folder ID is not available.")
            completion(false)
            return
        }
        
        let file = GTLRDrive_File()
        file.name = name
        file.parents = [folderID]
        
        let uploadParameters = GTLRUploadParameters(fileURL: fileURL, mimeType: mimeType)
        let query = GTLRDriveQuery_FilesCreate.query(withObject: file, uploadParameters: uploadParameters)
        
        googleDriveService.executeQuery(query) { (_, _, error) in
            if let error = error {
                print("Error uploading file: \(error.localizedDescription)")
                completion(false)
            } else {
                print("File uploaded successfully.")
                completion(true)
            }
        }
    }
}


//    func signIn(presentingViewController: UIViewController) {
//
//
//        GIDSignIn.sharedInstance.signIn(with: signInConfig, presenting: presentingViewController) { [weak self] user, error in
//            if let user = user {
//                self?.googleUser = user
//                self?.isSignedIn = true
//                self?.googleDriveService.authorizer = user.authentication.fetcherAuthorizer()
//                print("Sign-in successful: \(user.profile?.name ?? "Unknown User")")
//            } else if let error = error {
//                print("Sign-in error: \(error.localizedDescription)")
//            }
//        }
//    }
//
