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
        NavigationStack {
            List(companies, id: \.siret) { company in
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
                    Button(action: addCompany) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
    
    private func addCompany() {
        
    }
}

struct Company: Identifiable {
    var id: String { siret }
    var name: String
    var siret: String
    var primaryLocation: CLLocationCoordinate2D
    var secondaryLocation: CLLocationCoordinate2D

}
