//
//  CKShareManager.swift
//  DocumentManager
//
//  Created by TKXON on 07/01/2025.
//

import Foundation
import CloudKit

class CKShareManager {
    
    static let shared = CKShareManager()
    
    private let container: CKContainer
    private let database: CKDatabase
    
    private init() {
        container = CKContainer.default()
        database = container.privateCloudDatabase
    }
    
    /// Creates a share for the given record.
    /// - Parameters:
    ///   - record: The CKRecord to share.
    ///   - completion: Completion handler returning a CKShare or an error.
    func createShare(for record: CKRecord, completion: @escaping (CKShare?, Error?) -> Void) {
        let share = CKShare(rootRecord: record)
        
        // Configure permissions
        share[CKShare.SystemFieldKey.title] = "Shared Company Record" as CKRecordValue
        share.publicPermission = .none
        
        // Save the record and the share to the database
        let operation = CKModifyRecordsOperation(recordsToSave: [record, share])
        operation.savePolicy = .ifServerRecordUnchanged
        
        operation.modifyRecordsCompletionBlock = { _, _, error in
            if let error = error {
                completion(nil, error)
            } else {
                completion(share, nil)
            }
        }
        
        database.add(operation)
    }
    
    /// Adds a participant to a share.
    /// - Parameters:
    ///   - share: The CKShare to update.
    ///   - email: The email address of the participant.
    ///   - completion: Completion handler with an updated CKShare or an error.
//    func addParticipant(to share: CKShare, email: String, completion: @escaping (CKShare?, Error?) -> Void) {
//        container.discoverUserIdentity(withEmailAddress: email) { identity, error in
//            guard let identity = identity, let userRecordID = identity.userRecordID, error == nil else {
//                completion(nil, error)
//                return
//            }
//            
//            if let participant = CKShare.Participant(userIdentity: identity) {
//                participant.permission = .readWrite
//                participant.role = .editor
//                
//                share.addParticipant(participant)
//                
//                // Save the updated share
//                let operation = CKModifyRecordsOperation(recordsToSave: [share])
//                operation.modifyRecordsCompletionBlock = { _, _, error in
//                    if let error = error {
//                        completion(nil, error)
//                    } else {
//                        completion(share, nil)
//                    }
//                }
//                
//                self.database.add(operation)
//            } else {
//                completion(nil, NSError(domain: "CKShareManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create participant."]))
//            }
//        }
//    }

    /// Resolves conflicts and applies the most recent changes.
    /// - Parameters:
    ///   - records: The conflicting CKRecords.
    ///   - completion: Completion handler with resolved CKRecord or an error.
    func resolveConflicts(records: [CKRecord], completion: @escaping (CKRecord?, Error?) -> Void) {
        guard let mostRecentRecord = records.max(by: { $0.modificationDate ?? Date.distantPast < $1.modificationDate ?? Date.distantPast }) else {
            completion(nil, NSError(domain: "ConflictResolution", code: 1, userInfo: [NSLocalizedDescriptionKey: "No records to resolve."]))
            return
        }
        
        let operation = CKModifyRecordsOperation(recordsToSave: [mostRecentRecord])
        operation.modifyRecordsCompletionBlock = { savedRecords, _, error in
            if let error = error {
                completion(nil, error)
            } else {
                completion(savedRecords?.first, nil)
            }
        }
        
        database.add(operation)
    }
    
    /// Fetches a shared record from a given CKShare.
    /// - Parameters:
    ///   - share: The CKShare.
    ///   - completion: Completion handler with the fetched CKRecord or an error.

//    func fetchSharedRecord(from share: CKShare, completion: @escaping (CKRecord?, Error?) -> Void) {
//        // Fetch the root record ID from the CKShare
//        let rootRecordID = share.rootRecordID
//        
//        guard let rootRecordID = rootRecordID else {
//            completion(nil, NSError(domain: "CKShareManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid root record ID."]))
//            return
//        }
//        
//        // Fetch the record from the database using the rootRecordID
//        database.fetch(withRecordID: rootRecordID) { record, error in
//            if let error = error {
//                completion(nil, error)
//            } else {
//                completion(record, nil)
//            }
//        }
//    }

}


//let record = // Your CKRecord (Company record)
//CKShareManager.shared.createShare(for: record) { share, error in
//    if let error = error {
//        print("Error creating share: \(error)")
//    } else if let share = share {
//        print("Share created: \(share)")
//    }
//}
//
//let email = "invitee@example.com"
//CKShareManager.shared.addParticipant(to: share, email: email) { updatedShare, error in
//    if let error = error {
//        print("Error adding participant: \(error)")
//    } else {
//        print("Participant added successfully.")
//    }
//}

