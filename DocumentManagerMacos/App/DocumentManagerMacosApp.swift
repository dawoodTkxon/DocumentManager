//
//  DocumentManagerApp.swift
//  DocumentManager
//
//  Created by TKXON on 04/01/2025.
//

import SwiftUI
import SwiftData
import GoogleSignIn
import GoogleAPIClientForREST
import SwiftUI
import CloudKit
import AppKit

@main
struct DocumentManagerMacosApp: App {
    @StateObject private var vm = CloudKitViewModel()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            CompanyModel.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .none)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            HomeMacOSView()
                .environmentObject(vm)

        }
        .modelContainer(sharedModelContainer)
    }
}



class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("Application did finish launching.")
        
    }
    
    @objc private func application(_ application: NSObject, userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata) {
        //            YourClass.acceptCloudKitShare(cloudKitShareMetadata: cloudKitShareMetadata)
        }
    
    
    func application(_ app: NSApplication, open urls: [URL]) {
        // Handle incoming URLs (e.g., for Google Sign-In redirection)
        for url in urls {
            if GIDSignIn.sharedInstance.handle(url) {
                print("Handled URL: \(url)")
            } else {
                print("Unhandled URL: \(url)")
            }
        }
    }
    func application(_ application: NSApplication, userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata) {
        print("You accepted something: \(cloudKitShareMetadata)")
        
        guard cloudKitShareMetadata.containerIdentifier == Config.containerIdentifier else {
            print("Shared container identifier \(cloudKitShareMetadata.containerIdentifier) did not match known identifier.")
            return
        }
        // Create an operation to accept the share, running in the app's CKContainer.
        let container = CKContainer(identifier: Config.containerIdentifier)
        let operation = CKAcceptSharesOperation(shareMetadatas: [cloudKitShareMetadata])
        
        
        operation.perShareResultBlock = { metadata, result in
            let rootRecordID = metadata.rootRecordID
            
            switch result {
            case .failure(let error):
                debugPrint("Error accepting share with root record ID: \(rootRecordID), \(error)")
                
            case .success:
                debugPrint("Accepted CloudKit share for root record ID: \(rootRecordID)")
            }
        }
        
        operation.acceptSharesResultBlock = { result in
            if case .failure(let error) = result {
                debugPrint("Error accepting CloudKit Share: \(error)")
            }
        }
        
        operation.qualityOfService = .utility
        container.add(operation)
    }
    
}
