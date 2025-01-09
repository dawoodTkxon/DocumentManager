//
//  SceneDelegate.swift
//  DocumentManager
//
//  Created by TKXON on 09/01/2025.
//

import UIKit
import SwiftUI
import CloudKit
import SwiftUI
import SwiftData

import GoogleSignIn
import GoogleAPIClientForREST
import SwiftUI

@available(iOS 17, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        guard let scene = (scene as? UIWindowScene) else { return }

    }

    func windowScene(_ windowScene: UIWindowScene, userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata) {
        guard cloudKitShareMetadata.containerIdentifier == Config.containerIdentifier else {
            print("Shared container identifier \(cloudKitShareMetadata.containerIdentifier) did not match known identifier.")
            return
        }

        // Create an operation to accept the share, running in the app's CKContainer.
        let container = CKContainer(identifier: Config.containerIdentifier)
        let operation = CKAcceptSharesOperation(shareMetadatas: [cloudKitShareMetadata])

        debugPrint("Accepting CloudKit Share with metadata: \(cloudKitShareMetadata)")

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
