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

class GoogleSignInManager {
    var googleDriveService = GTLRDriveService()
    var googleUser: GIDGoogleUser?
    var isSignedIn = false
    var uploadFolderID: String = ""
    var userName: String?
    var folderCreated = false
    private let signInConfig = GIDConfiguration(clientID: "1008713916759-a9aph1jlqi5infr26sf7ub3vs428nfji.apps.googleusercontent.com")
    private let signInConfigMacos = GIDConfiguration(clientID: "1008713916759-g5giuoegaerd5efad3h72158a2vmpa6d.apps.googleusercontent.com")
    
    // Singleton instance
    static let shared = GoogleSignInManager()
    
    private init() {
    }
    
    
    
    
#if os(iOS)
    func addScope(presenting viewController: UIViewController){
        //        GIDSignIn.sharedInstance.addScopes([kGTLRAuthScopeDrive], presenting: viewController)
    }
#endif
    
    
    
    
#if os(macOS)
    func signIn(presenting window: NSWindow, completion: @escaping () -> Void) {
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
                    self?.googleUser = user
                    self?.isSignedIn = true
                    self?.userName = user.profile?.name
                    completion()
                    
                    print("Google ID: \(user.userID ?? "No ID")")
                    print("User Name: \(user.profile?.name ?? "No Name")")
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
                    self?.googleUser = user
                    self?.isSignedIn = true
                    self?.userName = user.profile?.name
                    completion()
                    
                    print("Google ID: \(user.userID ?? "No ID")")
                    print("User Name: \(user.profile?.name ?? "No Name")")
                    
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
    
    
    func signInSilently(completion: @escaping () -> Void) {
        GIDSignIn.sharedInstance.restorePreviousSignIn { [weak self] user, error in
            if let user = user {
                print("===================")
                print("had signin")
                
                
                let service = GTLRDriveService()
                
                if let user = GIDSignIn.sharedInstance.currentUser {
                    service.authorizer = user.authentication.fetcherAuthorizer()
                }
                self?.googleDriveService = service
                self?.googleUser = user
                self?.isSignedIn = true
                self?.userName = user.profile?.name
                completion()
            } else if let error = error {
                print("===================")
                print("Signed out")
                print("Silent Sign-In failed: \(error.localizedDescription)")
                completion()
            }
        }
    }
    
    func getFolderID(name: String, completion: @escaping (String?) -> Void) {
        guard googleUser != nil else { return }
        
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
                print("Folder created with ID: \(folderId)")
                
                // Add public access permission
                let permission = GTLRDrive_Permission()
                permission.type = "anyone"
                permission.role = "reader"
                
                let permissionQuery = GTLRDriveQuery_PermissionsCreate.query(withObject: permission, fileId: folderId)
                self.googleDriveService.executeQuery(permissionQuery) { (permissionTicket, _, permissionError) in
                    if let permissionError = permissionError {
                        print("Error setting public permissions: \(permissionError.localizedDescription)")
                        completion(nil)
                    } else {
                        print("Folder set to public access")
                        completion(folderId)
                    }
                }
            } else {
                completion(nil)
            }
        }
    }
    
    func uploadFile( name: String, folderID: String, fileURL: URL, mimeType: String,completion: @escaping (Bool) -> Void) {
        let file = GTLRDrive_File()
        file.name = name
        file.parents = [folderID]
        
        // Define upload parameters
        let uploadParameters = GTLRUploadParameters(fileURL: fileURL, mimeType: mimeType)
        
        // Create the upload query
        let query = GTLRDriveQuery_FilesCreate.query(withObject: file, uploadParameters: uploadParameters)
        
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
    
    func checkForAlreadyLogin(completion: @escaping () -> Void){
        if GIDSignIn.sharedInstance.hasPreviousSignIn() {
            print("===================")
            print("had signin")
            signInSilently {
                completion()
            }
            
        } else {
            completion()
            print("===================")
            print("Signed out")
        }
    }
    
    func downloadFile(fileID: String, completion: @escaping (URL?) -> Void) {
        let query = GTLRDriveQuery_FilesGet.queryForMedia(withFileId: fileID)
        
        googleDriveService.executeQuery(query) { (_, file, error) in
            if let error = error {
                print("Error downloading file: \(error.localizedDescription)")
                completion(nil)
            } else if let file = file as? GTLRDataObject {
                do {
                    let tempURL = try self.writeToTemporaryDirectory(data: file.data, fileName: fileID)
                    completion(tempURL)
                } catch {
                    print("Error writing to temporary directory: \(error.localizedDescription)")
                    completion(nil)
                }
            } else {
                completion(nil)
            }
        }
    }
    
    private func writeToTemporaryDirectory(data: Data, fileName: String) throws -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        try data.write(to: fileURL)
        return fileURL
    }
    func listFiles(inFolder folderID: String, completion: @escaping ([GTLRDrive_File]?) -> Void) {
        guard isSignedIn else {
            print("User is not signed in.")
            completion(nil)
            return
        }
        
        let query = GTLRDriveQuery_FilesList.query()
        query.q = "'\(folderID)' in parents and trashed = false"
        query.fields = "files(id, name, mimeType, modifiedTime)"
        
        googleDriveService.executeQuery(query) { (_, result, error) in
            if let error = error {
                print("Error fetching files: \(error.localizedDescription)")
                completion(nil)
            } else if let fileList = result as? GTLRDrive_FileList {
                completion(fileList.files)
            } else {
                completion(nil)
            }
        }
    }
    
}
