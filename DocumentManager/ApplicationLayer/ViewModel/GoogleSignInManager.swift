//
//  GoogleSignInManager.swift
//  DocumentManager
//
//  Created by TKXON on 03/01/2025.
//

import SwiftUI
import SwiftData
import GoogleSignIn
import GoogleAPIClientForREST
import GTMSessionFetcher
import MobileCoreServices


class GoogleDriveSingletonClass {
    var googleDriveService = GTLRDriveService()
    var googleUser: GIDGoogleUser?
    var isSignedIn = false
    var uploadFolderID: String = ""
    var userName: String?
    var id: String = "1303LQ5wjvJAvz0s2ccdUJoJyUWK0Ajxq"
    var folderCreated = false
    private let signInConfig = GIDConfiguration(clientID: "1008713916759-a9aph1jlqi5infr26sf7ub3vs428nfji.apps.googleusercontent.com")
    
    // Singleton instance
    static let shared = GoogleDriveSingletonClass()

    private init() {
        //        GIDSignIn.sharedInstance.scopes = [kGTLRAuthScopeDrive]
        //        GIDSignIn.sharedInstance
    }
    
    
    func addScope(presenting viewController: UIViewController){
        //        GIDSignIn.sharedInstance.addScopes([kGTLRAuthScopeDrive], presenting: viewController)
    }
        
    func signIn(presenting viewController: UIViewController) {
        GIDSignIn.sharedInstance.signIn(with: signInConfig, presenting: viewController) { [weak self] user, error in
            if let error = error {
                print("Sign-in failed: \(error.localizedDescription)")
                self?.googleUser = nil
                self?.isSignedIn = false
            } else if let user = user {
                GIDSignIn.sharedInstance.addScopes([kGTLRAuthScopeDrive], presenting: viewController) { newUser, newError in
                    
                    let service = GTLRDriveService()
                    if let user = GIDSignIn.sharedInstance.currentUser {
                        service.authorizer = user.authentication.fetcherAuthorizer()
                    }
                    self?.googleDriveService = service
                    self?.googleUser = newUser
                    self?.isSignedIn = true
                    self?.userName = newUser?.profile?.name
                    
                    
                    print("Google ID: \(user.userID ?? "No ID")")
                    print("User Name: \(user.profile?.name ?? "No Name")")
                    print("New Google ID: \(newUser?.userID ?? "No ID")")
                    print("New User Name: \(newUser?.profile?.name ?? "No Name")")
                }
            }
        }
    }
    
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        googleUser = nil
        isSignedIn = false
        uploadFolderID = ""
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
        query.q = "name = '\(name)' and mimeType = 'application/vnd.google-apps.folder'"
        
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
    
    func createFolder(name: String, completion: @escaping (String?) -> Void) {
        //        guard let googleDriveService = self.googleDriveService else {
        //            completion(nil)
        //            return
        //        }
        
        let folder = GTLRDrive_File()
        folder.mimeType = "application/vnd.google-apps.folder"
        folder.name = name
        
        let query = GTLRDriveQuery_FilesCreate.query(withObject: folder, uploadParameters: nil)
        query.fields = "id"
        
        googleDriveService.executeQuery(query) { (ticket, file, error) in
            if let error = error {
                print("Error creating folder: \(error.localizedDescription)")
                completion(nil)
            } else if let folder = file as? GTLRDrive_File, let folderId = folder.identifier {
                self.uploadFolderID = folderId // Save the folder ID to the singleton
                print("Folder created with ID: \(folderId)")
                
                completion(folderId)
            } else {
                completion(nil)
            }
        }
    }
    
    func uploadFile( name: String, folderID: String, fileURL: URL, mimeType: String,completion: @escaping (Bool) -> Void
    ) {
        // Create a Google Drive file object
        let file = GTLRDrive_File()
        file.name = name
        file.parents = [folderID] // Use the provided folder ID
//        file.parents = [uploadFolderID] // Use the provided folder ID
        
        // Define upload parameters
        let uploadParameters = GTLRUploadParameters(fileURL: fileURL, mimeType: mimeType)
        
        // Create the upload query
        let query = GTLRDriveQuery_FilesCreate.query(withObject: file, uploadParameters: uploadParameters)
        
        // Execute the upload
        
        googleDriveService.executeQuery(query) { (ticket, file, error) in
            if let error = error {
                print("Error creating folder: \(error.localizedDescription)")
                completion(false)
            } else if let folder = file as? GTLRDrive_File, let folderId = folder.identifier {
                self.uploadFolderID = folderId
                completion(true)
            } else {
                completion(true)
            }
        }
    }
}


//        googleDriveService.executeQuery(query) { (_, result, error) in
//            if let error = error {
//                print("Error creating folder: \(error.localizedDescription)")
//                completion(nil)
//            } else if let createdFolder = result as? GTLRDrive_File {
//                print("Folder created with ID: \(createdFolder.identifier ?? "No ID")")
//                completion(createdFolder.identifier)
//            } else {
//                print("Folder creation response was empty.")
//                completion(nil)
//            }
//        }


//    func populateFolderID(folderName: String, completion: @escaping () -> Void) {
//        print("Starting to populate folder ID for folder: \(folderName)")
//
//        // Get the user's name
//        if let userName = googleUser?.profile?.name {
//            print("Logged in as: \(userName)") // Print the user's name
//        } else {
//            print("No user signed in.")
//        }
//
//        getFolderID(name: folderName) { [weak self] folderID in
//            if let folderID = folderID {
//                print("Folder found with ID: \(folderID)")
//                self?.uploadFolderID = folderID
//                completion()
//            } else {
//                print("Folder not found. Attempting to create folder.")
//                self?.createFolder(name: folderName) { createdFolderID in
//                    if let createdFolderID = createdFolderID, createdFolderID.isEmpty == false {
//                        print("Folder created with ID: \(createdFolderID) by user: \(self?.googleUser?.profile?.name ?? "Unknown")")
//                        self?.uploadFolderID = createdFolderID
//                    } else {
//                        print("Failed to create folder.")
//                    }
//                    completion()
//                }
//            }
//        }
//    }


//    func uploadFile(
//        name: String,
//        folderID: String,
//        fileURL: URL,
//        mimeType: String,
//        service: GTLRDriveService,  completion: @escaping (Bool) -> Void) {
//
//        guard let folderID = uploadFolderID else {
//            print("Folder ID is not available.")
//            completion(false)
//            return
//        }
//
//        let file = GTLRDrive_File()
//        file.name = name
//        file.parents = [folderID]
//
//        let uploadParameters = GTLRUploadParameters(fileURL: fileURL, mimeType: mimeType)
//        let query = GTLRDriveQuery_FilesCreate.query(withObject: file, uploadParameters: uploadParameters)
//
//        googleDriveService.executeQuery(query) { (_, _, error) in
//            if let error = error {
//                print("Error uploading file: \(error.localizedDescription)")
//                completion(false)
//            } else {
//                print("File uploaded successfully.")
//                completion(true)
//            }
//        }
//    }


//        googleDriveService.executeQuery(query) { (ticket, file, error) in
//            if let error = error {
//                print("Error creating folder: \(error.localizedDescription)")
//                completion(nil)
//                return
//            }
//
//            if let folder = file as? GTLRDrive_File, let folderId = folder.identifier {
//                completion(folderId)
//            } else {
//                completion(nil)
//            }
//        }
