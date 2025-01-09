//
//  DocumentManagerMacosApp.swift
//  DocumentManagerMacos
//
//  Created by TKXON on 09/01/2025.
//

import SwiftUI
import SwiftData

@main
struct DocumentManagerMacosApp: App {
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
            HomeView()
        }
        .modelContainer(sharedModelContainer)
    }
}
