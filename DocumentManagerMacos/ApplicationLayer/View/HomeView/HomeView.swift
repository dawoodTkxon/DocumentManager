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
import AppKit

@available(macOS 13.0, *)
struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var CompanyModels: [CompanyModel]
    @Environment(\.dismiss) private var dismiss

    @State private var isSignedIn: Bool = GoogleDriveSingletonClass.shared.isSignedIn
    var body: some View {
        NavigationSplitView {
            List(CompanyModels, id: \.id) { company in
                NavigationLink {
                    CompanyDetailView(company: company)
                } label: {
                    Text(company.name ?? "n/a")
                }
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
            .navigationTitle("Companies")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    NavigationLink {
                        AddCompanyView()
                    } label: {
                        Image(systemName: "plus")
                            .font(.headline)
                    }
                }
                
                ToolbarItem(placement: .navigation) { 
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
    
    private func handleAuthentication() {
        if isSignedIn {
            // Perform logout
            GoogleDriveSingletonClass.shared.signOut()
            isSignedIn = false
        } else {
            // Perform login
            if let window = NSApplication.shared.windows.first {
                GoogleDriveSingletonClass.shared.signIn(presenting: window)
                isSignedIn = GoogleDriveSingletonClass.shared.isSignedIn
            }
        }
    }
}

