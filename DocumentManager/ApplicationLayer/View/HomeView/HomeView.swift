//
//  HomeView.swift
//  DocumentManager
//
//  Created by TKXON on 05/01/2025.
//

import Foundation
import SwiftUI
import MapKit


struct HomeView: View {
    @State private var companies = [
        Company(
            name: "Tech Solutions Ltd.",
            siret: "123 456 789 00012",
            primaryLocation: CLLocationCoordinate2D(latitude: 48.720338, longitude: 4.148706),
            secondaryLocation: CLLocationCoordinate2D(latitude: 48.721338, longitude: 4.149706)
        ),
        Company(
            name: "Innovative Solutions",
            siret: "987 654 321 00056",
            primaryLocation: CLLocationCoordinate2D(latitude: 48.830338, longitude: 4.248706),
            secondaryLocation: CLLocationCoordinate2D(latitude: 48.831338, longitude: 4.249706)
        )
    ]
    
    var body: some View {
        NavigationSplitView {
            List(companies, id: \.siret) { company in
                NavigationLink {
                    if #available(iOS 17, *) {
                        CompanyDetailView(company: company)
                    } else {
                        // Fallback on earlier versions
                    }
                } label: {
                    Text(company.name)
                        .font(.headline)
                }
            }
            .navigationTitle("Companies")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        AddCompanyView { newCompany in
                            companies.append(newCompany)
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.headline)
                    }
                }
            }
        } detail: {
            // Default view when no company is selected (right side for iPad)
            Text("Select a company to view details.")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
}

struct Company: Identifiable {
    var id: String { siret }
    var name: String
    var siret: String
    var primaryLocation: CLLocationCoordinate2D
    var secondaryLocation: CLLocationCoordinate2D
}



