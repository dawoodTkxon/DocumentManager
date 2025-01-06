//
//  HomeView.swift
//  DocumentManager
//
//  Created by TKXON on 05/01/2025.
//

import Foundation
import SwiftUI
import MapKit
import SwiftData

@available(iOS 17, *)
struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var CompanyModels: [CompanyModel]
    @State private var isSignedIn: Bool = GoogleDriveSingletonClass.shared.isSignedIn

    var body: some View {
        NavigationSplitView {
            List(CompanyModels, id: \.id) { company in
                NavigationLink {
                        CompanyDetailView(company: company)
                } label: {
                    Text(company.name)
                        .font(.headline)
                }
            }
            .navigationTitle("Companies")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        AddCompanyView()
                        
                    } label: {
                        Image(systemName: "plus")
                            .font(.headline)
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                                 handleAuthentication()
                    }) {
                        Text(isSignedIn ? "Logout" : "Login")
                            .font(.headline)
                    }
                }
            }
            .onAppear {
                isSignedIn = GoogleDriveSingletonClass.shared.isSignedIn
            }
        } detail: {
            Text("Select a company to view details.")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }

    func addSample() {
        // Sample companies
        let company1 = CompanyModel(
            name: "Tech Innovations",
            siret: "12345678901234",
            primaryLocation: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            secondaryLocation: CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437)
        )
        let company2 = CompanyModel(
            name: "Global Enterprises",
            siret: "98765432109876",
            primaryLocation: CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278),
            secondaryLocation: CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522)
        )
        let company3 = CompanyModel(
            name: "Future Solutions",
            siret: "56789012345678",
            primaryLocation: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
            secondaryLocation: CLLocationCoordinate2D(latitude: 41.8781, longitude: -87.6298)
        )
        modelContext.insert(company1)
        modelContext.insert(company2)
        modelContext.insert(company3)
        
        do {
            try modelContext.save()
            print("Data saved successfully.")
        } catch {
            print("Failed to save data: \(error)")
        }
    }
    private func handleAuthentication() {
        if isSignedIn {
            // Perform logout
            GoogleDriveSingletonClass.shared.signOut()
            isSignedIn = false
        } else {
            // Perform login
            if let rootVC = UIApplication.shared.windows.first?.rootViewController {
                GoogleDriveSingletonClass.shared.signIn(presenting: rootVC)
                isSignedIn = GoogleDriveSingletonClass.shared.isSignedIn
            }
        }
    }
}
