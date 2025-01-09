//
//  CloudKitViewModel.swift
//  DocumentManager
//
//  Created by TKXON on 09/01/2025.
//


import Foundation
import CloudKit
import OSLog
import SwiftUI

enum Config {
    /// iCloud container identifier.
    /// Update this if you wish to use your own iCloud container.
    static let containerIdentifier = "iCloud.com.DocumentManager.mubeen"
}

@available(iOS 17, *)
@MainActor
final class CloudKitViewModel: ObservableObject {

    // MARK: - Error

    enum ViewModelError: Error {
        case invalidRemoteShare
    }

    // MARK: - State

    enum State {
        case loading
        case loaded(private: [CompanayRemoteModel], shared: [CompanayRemoteModel])
        case error(Error)
    }

    // MARK: - Properties

    /// State directly observable by our view.
    @Published private(set) var state: State = .loading
    /// Use the specified iCloud container ID, which should also be present in the entitlements file.
    lazy var container = CKContainer(identifier: Config.containerIdentifier)
    /// This project uses the user's private database.
    public lazy var database = container.privateCloudDatabase
    /// Sharing requires using a custom record zone.
    let recordZone = CKRecordZone(zoneName: "Records")

    // MARK: - Init

    nonisolated init() {}

    /// Initializer to provide explicit state (e.g. for previews).
    init(state: State) {
        self.state = state
    }

    // MARK: - API

    /// Prepares container by creating custom zone if needed.
    func initialize() async throws {
        do {
            try await createZoneIfNeeded()
        } catch {
            state = .error(error)
        }
    }

    /// Fetches contacts from the remote databases and updates local state.
    func refresh() async throws {
        state = .loading
        do {
            let (privateContacts, sharedContacts) = try await fetchPrivateAndSharedCompanies()
            state = .loaded(private: privateContacts, shared: sharedContacts)
        } catch {
            state = .error(error)
        }
    }

    /// Fetches both private and shared contacts in parallel.
    /// - Returns: A tuple containing separated private and shared contacts.
    func fetchPrivateAndSharedCompanies() async throws -> (private: [CompanayRemoteModel], shared: [CompanayRemoteModel]) {
        // This will run each of these operations in parallel.
        async let privateContacts = fetchContacts(scope: .private, in: [recordZone])
        async let sharedContacts = fetchSharedContacts()

        return (private: try await privateContacts, shared: try await sharedContacts)
    }

    /// Adds a new Contact to the database.
    /// - Parameters:
    ///   - name: Name of the Contact.
    ///   - phoneNumber: Phone number of the contact.
    func addCompnay(name: String, siret: String,primaryLocationLatitude: Double, primaryLocationLongitude: Double,secondaryLocationLatitude: Double, secondaryLocationLongitude: Double, folderID: String) async throws {
        let id = CKRecord.ID(zoneID: recordZone.zoneID)
        let contactRecord = CKRecord(recordType: "SharedRecord", recordID: id)
        contactRecord["name"] = name
        contactRecord["siret"] = siret
        contactRecord["primaryLocationLatitude"] = primaryLocationLatitude
        contactRecord["primaryLocationLongitude"] = primaryLocationLongitude
        contactRecord["secondaryLocationLatitude"] = secondaryLocationLatitude
        contactRecord["secondaryLocationLongitude"] = secondaryLocationLongitude
        contactRecord["folderID"] = folderID
        
        do {
            try await database.save(contactRecord)
        } catch {
            debugPrint("ERROR: Failed to save new Contact: \(error)")
            throw error
        }
    }

    /// Fetches an existing `CKShare` on a Contact record, or creates a new one in preparation to share a Contact with another user.
    /// - Parameters:
    ///   - contact: Contact to share.
    ///   - completionHandler: Handler to process a `success` or `failure` result.
    func fetchOrCreateShare(contact: CompanayRemoteModel) async throws -> (CKShare, CKContainer) {
        // Debug log
        print("Fetching or creating share for contact: \(contact.name)")

        // Check if there is an existing share on the associated record
        if let existingShare = contact.associatedRecord.share {
            print("Found existing share for contact: \(contact.name)")
            guard let share = try await database.record(for: existingShare.recordID) as? CKShare else {
                throw ViewModelError.invalidRemoteShare
            }
            return (share, container)
        }

        // If no existing share, create a new one
        print("Creating new share for contact: \(contact.name)")
        let share = CKShare(rootRecord: contact.associatedRecord)
        share[CKShare.SystemFieldKey.title] = "Record: \(contact.name)"
        _ = try await database.modifyRecords(saving: [contact.associatedRecord, share], deleting: [])

        return (share, container)
    }


    // MARK: - Private

    /// Fetches contacts for a given set of zones in a given database scope.
    /// - Parameters:
    ///   - scope: Database scope to fetch from.
    ///   - zones: Record zones to fetch contacts from.
    /// - Returns: Combined set of contacts across all given zones.
    private func fetchContacts(
        scope: CKDatabase.Scope,
        in zones: [CKRecordZone]
    ) async throws -> [CompanayRemoteModel] {
        let database = container.database(with: scope)
        var allContacts: [CompanayRemoteModel] = []

        // Inner function retrieving and converting all Contact records for a single zone.
        @Sendable func contactsInZone(_ zone: CKRecordZone) async throws -> [CompanayRemoteModel] {
            var allContacts: [CompanayRemoteModel] = []

            /// `recordZoneChanges` can return multiple consecutive changesets before completing, so
            /// we use a loop to process multiple results if needed, indicated by the `moreComing` flag.
            var awaitingChanges = true
            /// After each loop, if more changes are coming, they are retrieved by using the `changeToken` property.
            var nextChangeToken: CKServerChangeToken? = nil

            while awaitingChanges {
                let zoneChanges = try await database.recordZoneChanges(inZoneWith: zone.zoneID, since: nextChangeToken)
                let contacts = zoneChanges.modificationResultsByID.values
                    .compactMap { try? $0.get().record }
                    .compactMap { CompanayRemoteModel(record: $0) }
                allContacts.append(contentsOf: contacts)

                awaitingChanges = zoneChanges.moreComing
                nextChangeToken = zoneChanges.changeToken
            }

            return allContacts
        }

        // Using this task group, fetch each zone's contacts in parallel.
        try await withThrowingTaskGroup(of: [CompanayRemoteModel].self) { group in
            for zone in zones {
                group.addTask {
                    try await contactsInZone(zone)
                }
            }

            // As each result comes back, append it to a combined array to finally return.
            for try await contactsResult in group {
                allContacts.append(contentsOf: contactsResult)
            }
        }

        return allContacts
    }

    /// Fetches all shared Contacts from all available record zones.
    private func fetchSharedContacts() async throws -> [CompanayRemoteModel] {
        let sharedZones = try await container.sharedCloudDatabase.allRecordZones()
        guard !sharedZones.isEmpty else {
            return []
        }

        return try await fetchContacts(scope: .shared, in: sharedZones)
    }

    /// Creates the custom zone in use if needed.
    private func createZoneIfNeeded() async throws {
        // Avoid the operation if this has already been done.
        guard !UserDefaults.standard.bool(forKey: "isZoneCreated") else {
            return
        }

        do {
            _ = try await database.modifyRecordZones(saving: [recordZone], deleting: [])
        } catch {
            print("ERROR: Failed to create custom zone: \(error.localizedDescription)")
            throw error
        }

        UserDefaults.standard.setValue(true, forKey: "isZoneCreated")
    }
}
