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

#if os(iOS)
enum Config {
    /// iCloud container identifier.
    /// Update this if you wish to use your own iCloud container.
    static let containerIdentifier = "iCloud.com.DocumentManager.mubeen"
}
#endif


#if os(macOS)
enum Config {
    /// iCloud container identifier.
    /// Update this if you wish to use your own iCloud container.
//    static let containerIdentifier = "iCloud.com.DocumentManager.mubeen.macos"
    static let containerIdentifier = "iCloud.com.DocumentManager.mubeen"
}
#endif

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
            let (privateCompany, sharedCompany) = try await fetchPrivateAndSharedCompanies()
            state = .loaded(private: privateCompany, shared: sharedCompany)
        } catch {
            state = .error(error)
        }
    }

    /// Fetches both private and shared company in parallel.
    /// - Returns: A tuple containing separated private and shared contacts.
    func fetchPrivateAndSharedCompanies() async throws -> (private: [CompanayRemoteModel], shared: [CompanayRemoteModel]) {
        // This will run each of these operations in parallel.
        async let privateCompany = fetchCompany(scope: .private, in: [recordZone])
        async let sharedCompany = fetchSharedCompany()

        return (private: try await privateCompany, shared: try await sharedCompany)
    }

    /// Adds a new Company to the database.
    /// - Parameters:
    ///   - name: Name of the Company.
    ///   - phoneNumber: Phone number of the company.
    func addCompnay(name: String, siret: String,primaryLocationLatitude: Double, primaryLocationLongitude: Double,secondaryLocationLatitude: Double, secondaryLocationLongitude: Double, folderID: String) async throws {
        let id = CKRecord.ID(zoneID: recordZone.zoneID)
        let companyRecord = CKRecord(recordType: "SharedRecord", recordID: id)
        companyRecord["name"] = name
        companyRecord["siret"] = siret
        companyRecord["primaryLocationLatitude"] = primaryLocationLatitude
        companyRecord["primaryLocationLongitude"] = primaryLocationLongitude
        companyRecord["secondaryLocationLatitude"] = secondaryLocationLatitude
        companyRecord["secondaryLocationLongitude"] = secondaryLocationLongitude
        companyRecord["folderID"] = folderID
        
        do {
            try await database.save(companyRecord)
        } catch {
            debugPrint("ERROR: Failed to save new Company: \(error)")
            throw error
        }
    }
    
    /// Updates an existing Company in the database.
    /// - Parameters:
    ///   - contact: The Company to update.
    ///   - updatedName: The updated name for the Contact.
    ///   - updatedPhoneNumber: The updated phone number for the Company.
    func updateCompany(name: String, siret: String,primaryLocationLatitude: Double, primaryLocationLongitude: Double,secondaryLocationLatitude: Double, secondaryLocationLongitude: Double, folderID: String) async throws {
            
        let id = CKRecord.ID(zoneID: recordZone.zoneID)
        let companyRecord = CKRecord(recordType: "SharedRecord", recordID: id)
        companyRecord["name"] = name
        companyRecord["siret"] = siret
        companyRecord["primaryLocationLatitude"] = primaryLocationLatitude
        companyRecord["primaryLocationLongitude"] = primaryLocationLongitude
        companyRecord["secondaryLocationLatitude"] = secondaryLocationLatitude
        companyRecord["secondaryLocationLongitude"] = secondaryLocationLongitude
        companyRecord["folderID"] = folderID

        do {
            try await database.save(companyRecord)
        } catch {
            debugPrint("ERROR: Failed to update Company: \(error.localizedDescription)")
            throw error
        }
    }

    
    /// Adds a new Contact to the database.
    /// - Parameters:
    ///   - name: Name of the Contact.
    ///   - phoneNumber: Phone number of the contact.
    func addNewCompnay(name: String, siret: String,primaryLocationLatitude: Double, primaryLocationLongitude: Double,secondaryLocationLatitude: Double, secondaryLocationLongitude: Double, folderID: String) async throws -> (Bool) {
        let id = CKRecord.ID(zoneID: recordZone.zoneID)
        let companyRecord = CKRecord(recordType: "SharedRecord", recordID: id)
        companyRecord["name"] = name
        companyRecord["siret"] = siret
        companyRecord["primaryLocationLatitude"] = primaryLocationLatitude
        companyRecord["primaryLocationLongitude"] = primaryLocationLongitude
        companyRecord["secondaryLocationLatitude"] = secondaryLocationLatitude
        companyRecord["secondaryLocationLongitude"] = secondaryLocationLongitude
        companyRecord["folderID"] = folderID
        
        do {
            try await database.save(companyRecord)
            return true
        } catch {
            debugPrint("ERROR: Failed to save new Company: \(error)")
            throw error
        }
        return false
    }
    
    
    
    
    /// Fetches an existing `CKShare` on a Company record, or creates a new one in preparation to share a Company with another user.
    /// - Parameters:
    ///   - contact: Contact to share.
    ///   - completionHandler: Handler to process a `success` or `failure` result.
    func fetchOrCreateShare(company: CompanayRemoteModel) async throws -> (CKShare, CKContainer) {
        // Debug log
        if let existingShare = company.associatedRecord.share {
            print("Found existing share for company: \(company.name)")
            guard let share = try await database.record(for: existingShare.recordID) as? CKShare else {
                throw ViewModelError.invalidRemoteShare
            }
            return (share, container)
        }

        // If no existing share, create a new one
        let share = CKShare(rootRecord: company.associatedRecord)
        share[CKShare.SystemFieldKey.title] = "Record: \(company.name)"
        share.publicPermission = .readWrite
        _ = try await database.modifyRecords(saving: [company.associatedRecord, share], deleting: [])

        return (share, container)
    }
    
    
    
    func updateCompanyModelData(company: CompanayRemoteModel) async throws {
        do {
            // Record ko fetch karein
            let fetchedRecord = try await database.record(for: company.associatedRecord.recordID)

            // Fetched record ko modify karein
            fetchedRecord["name"] = company.name
            fetchedRecord["siret"] = company.siret
            fetchedRecord["primaryLocationLatitude"] = company.primaryLocationLatitude
            fetchedRecord["primaryLocationLongitude"] = company.primaryLocationLongitude
            fetchedRecord["secondaryLocationLatitude"] = company.secondaryLocationLatitude
            fetchedRecord["secondaryLocationLongitude"] = company.secondaryLocationLongitude

            try await database.modifyRecords(saving: [fetchedRecord], deleting: [])
        } catch {
            debugPrint("ERROR: Failed to update company: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Private

    /// Fetches contacts for a given set of zones in a given database scope.
    /// - Parameters:
    ///   - scope: Database scope to fetch from.
    ///   - zones: Record zones to fetch contacts from.
    /// - Returns: Combined set of contacts across all given zones.
    private func fetchCompany(
        scope: CKDatabase.Scope,
        in zones: [CKRecordZone]
    ) async throws -> [CompanayRemoteModel] {
        let database = container.database(with: scope)
        var allCompany: [CompanayRemoteModel] = []

        // Inner function retrieving and converting all Contact records for a single zone.
        @Sendable func companyInZone(_ zone: CKRecordZone) async throws -> [CompanayRemoteModel] {
            var allCompany: [CompanayRemoteModel] = []

            /// `recordZoneChanges` can return multiple consecutive changesets before completing, so
            /// we use a loop to process multiple results if needed, indicated by the `moreComing` flag.
            var awaitingChanges = true
            /// After each loop, if more changes are coming, they are retrieved by using the `changeToken` property.
            var nextChangeToken: CKServerChangeToken? = nil

            while awaitingChanges {
                let zoneChanges = try await database.recordZoneChanges(inZoneWith: zone.zoneID, since: nextChangeToken)
                let company = zoneChanges.modificationResultsByID.values
                    .compactMap { try? $0.get().record }
                    .compactMap { CompanayRemoteModel(record: $0) }
                allCompany.append(contentsOf: company)

                awaitingChanges = zoneChanges.moreComing
                nextChangeToken = zoneChanges.changeToken
            }

            return allCompany
        }

        try await withThrowingTaskGroup(of: [CompanayRemoteModel].self) { group in
            for zone in zones {
                group.addTask {
                    try await companyInZone(zone)
                }
            }

            // As each result comes back, append it to a combined array to finally return.
            for try await companyResult in group {
                allCompany.append(contentsOf: companyResult)
            }
        }

        return allCompany
    }

    /// Fetches all shared company from all available record zones.
    private func fetchSharedCompany() async throws -> [CompanayRemoteModel] {
        let sharedZones = try await container.sharedCloudDatabase.allRecordZones()
        guard !sharedZones.isEmpty else {
            return []
        }

        return try await fetchCompany(scope: .shared, in: sharedZones)
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
    
    /// Deletes all data from iCloud, including private and shared databases.
    func deleteAllData() async throws {
        do {
            // Delete all records from the private database.
            try await deleteAllRecordsFromDatabase(database)

            // Delete all records from the shared database.
            let sharedDatabase = container.sharedCloudDatabase
            try await deleteAllRecordsFromDatabase(sharedDatabase)

            // Optionally, delete custom zones if required (uncomment if needed).
            // try await deleteAllZones()
            debugPrint("Successfully deleted all data from iCloud.")
        } catch {
            debugPrint("ERROR: Failed to delete all data: \(error.localizedDescription)")
            throw error
        }
    }

    /// Deletes all records from the specified database.
    /// - Parameter database: The CloudKit database to delete records from.
    private func deleteAllRecordsFromDatabase(_ database: CKDatabase) async throws {
        let query = CKQuery(recordType: "SharedRecord", predicate: NSPredicate(value: true))
        let operation = CKQueryOperation(query: query)

        var recordIDsToDelete: [CKRecord.ID] = []

        // Collect all record IDs.
        operation.recordFetchedBlock = { record in
            recordIDsToDelete.append(record.recordID)
        }

        operation.queryCompletionBlock = { _, error in
            if let error = error {
                debugPrint("ERROR: Query failed: \(error.localizedDescription)")
            }
        }

        try await database.add(operation)

        // Delete all collected records.
        if !recordIDsToDelete.isEmpty {
            let deleteOperation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: recordIDsToDelete)
            deleteOperation.savePolicy = .ifServerRecordUnchanged

            try await database.modifyRecords(saving: [], deleting: recordIDsToDelete)
        }
    }

    /// Deletes all custom zones (optional).
    /// Uncomment this method if you also want to delete the custom zones.
    /// - Throws: Any errors encountered during deletion.
    private func deleteAllZones() async throws {
        let zones = try await database.allRecordZones()
        if !zones.isEmpty {
            let zoneIDs = zones.map { $0.zoneID }
            try await database.modifyRecordZones(saving: [], deleting: zoneIDs)
            UserDefaults.standard.setValue(false, forKey: "isZoneCreated")
        }
    }
}
