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

#if os(iOS)
import UIKit
import MobileCoreServices
#endif


#if os(macOS)
import AppKit
#endif


class GoogleDriveSingletonClass {
    var googleDriveService = GTLRDriveService()
    var googleUser: GIDGoogleUser?
    var isSignedIn = false
    var uploadFolderID: String = ""
    var userName: String?
    var folderCreated = false
    private let signInConfig = GIDConfiguration(clientID: "1008713916759-a9aph1jlqi5infr26sf7ub3vs428nfji.apps.googleusercontent.com")
    private let signInConfigMacos = GIDConfiguration(clientID: "1008713916759-g5giuoegaerd5efad3h72158a2vmpa6d.apps.googleusercontent.com")
    
    // Singleton instance
    static let shared = GoogleDriveSingletonClass()
    
    private init() {
        //        GIDSignIn.sharedInstance.scopes = [kGTLRAuthScopeDrive]
        //        GIDSignIn.sharedInstance
    }
    
    
    
    
#if os(iOS)
    func addScope(presenting viewController: UIViewController){
        //        GIDSignIn.sharedInstance.addScopes([kGTLRAuthScopeDrive], presenting: viewController)
    }
#endif
    
    
    
    
#if os(macOS)
    func signIn(presenting window: NSWindow) {
        GIDSignIn.sharedInstance.signIn(with: signInConfigMacos, presenting: window) { [weak self] user, error in
            if let error = error {
                print("Sign-in failed: \(error.localizedDescription)")
                self?.googleUser = nil
                self?.isSignedIn = false
            } else if let user = user {
                GIDSignIn.sharedInstance.addScopes([kGTLRAuthScopeDrive], presenting: window) { newUser, newError in
                    
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
    
#endif
#if os(iOS)
    func signIn(presenting viewController: UIViewController, completion: @escaping () -> Void) {
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
                    completion()
                    
                    print("Google ID: \(user.userID ?? "No ID")")
                    print("User Name: \(user.profile?.name ?? "No Name")")
                    print("User Name: \(user.profile?.email ?? "No Name")")
                    print("New Google ID: \(newUser?.userID ?? "No ID")")
                    print("New User Name: \(newUser?.profile?.name ?? "No Name")")
                }
            }
        }
    }
#endif
    
    
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
