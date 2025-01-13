//
//  CloudSharingView.swift
//  DocumentManager
//
//  Created by TKXON on 09/01/2025.
//

import Foundation
import Foundation
import SwiftUI

#if os(macOS)
import AppKit
#endif

#if os(iOS)
import UIKit
#endif

import CloudKit

#if os(iOS)
/// This struct wraps a `UICloudSharingController` for use in SwiftUI.
struct CloudSharingView: UIViewControllerRepresentable {

    // MARK: - Properties

    @Environment(\.presentationMode) var presentationMode
    let container: CKContainer
    let share: CKShare

    // MARK: - UIViewControllerRepresentable

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}

    func makeUIViewController(context: Context) -> some UIViewController {
        let sharingController = UICloudSharingController(share: share, container: container)
        sharingController.availablePermissions = [.allowReadWrite, .allowPrivate]
        sharingController.delegate = context.coordinator
        sharingController.modalPresentationStyle = .currentContext
    
        return sharingController
    }

    func makeCoordinator() -> CloudSharingView.Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, UICloudSharingControllerDelegate {
        func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
            debugPrint("Error saving share: \(error)")
        }

        func itemTitle(for csc: UICloudSharingController) -> String? {
            "Record"
        }
    }
}
#endif



import SwiftUI
import CloudKit
#if os(macOS)
struct CloudSharingView: NSViewRepresentable {

    // MARK: - Properties
    let container: CKContainer
    let share: CKShare?

    // MARK: - NSViewRepresentable

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        
        let itemProvider = NSItemProvider()

        if let existingShare = share {
            // Register the existing CKShare with the item provider
            itemProvider.registerCKShare(existingShare, container: container)
        } else {
            // Register a new CKShare with a preparation handler
            itemProvider.registerCKShare(container: container, preparationHandler: {
                try await createAndSaveNewCKShare()
            })
        }

        // Create the activity item for the picker
        let activityItem = NSPreviewRepresentingActivityItem(
            item: itemProvider,
            title: "Share Content",
            imageProvider: nil, // Optional: Add a Quick Look preview image
            iconProvider: .init(object: NSApp.applicationIconImage)
        )

        // Configure the sharing service picker
        let sharingServicePicker = NSSharingServicePicker(items: [activityItem])
        sharingServicePicker.delegate = context.coordinator
        sharingServicePicker.show(relativeTo: .zero, of: view, preferredEdge: .minY)

        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        // No updates needed for the view itself
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(container: container, share: share, showAlert: { serviceTitle in
            let alert = NSAlert()
            alert.messageText = "Selected Sharing Service"
            alert.informativeText = "You selected the service: \(serviceTitle)"
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
        })
    }

    // MARK: - CKShare Creation

    private func createAndSaveNewCKShare() async throws -> CKShare {
        // Create a new record for sharing
        let record = CKRecord(recordType: "SharedRecord")
        let database = container.privateCloudDatabase

        // Save the record
        try await database.save(record)

        // Create a new share for the record
        let newShare = CKShare(rootRecord: record)
        newShare[CKShare.SystemFieldKey.title] = "Shared Content" as CKRecordValue

        // Save the share to the database
        try await database.save(newShare)
        return newShare
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, NSSharingServicePickerDelegate {
        let container: CKContainer
        let share: CKShare?
        let showAlert: (String) -> Void

        init(container: CKContainer, share: CKShare?, showAlert: @escaping (String) -> Void) {
            self.container = container
            self.share = share
            self.showAlert = showAlert
        }

        func sharingServicePicker(_ sharingServicePicker: NSSharingServicePicker, didChoose service: NSSharingService?) {
            let serviceTitle = service?.title ?? "None"
            debugPrint("Selected sharing service: \(serviceTitle)")
            showAlert(serviceTitle)
        }
    }
}


struct SharingView: NSViewRepresentable {
    let fileURL: URL

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            let sharingServicePicker = NSSharingServicePicker(items: [fileURL])
            sharingServicePicker.show(relativeTo: .zero, of: view, preferredEdge: .minY)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}


#endif
 


