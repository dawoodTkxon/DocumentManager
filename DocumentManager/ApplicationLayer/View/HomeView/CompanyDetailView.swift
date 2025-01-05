//
//  CompanyDetailView.swift
//  DocumentManager
//
//  Created by TKXON on 05/01/2025.
//

import SwiftUI
import MapKit

@available(iOS 17, *)
struct CompanyDetailView: View {
    var company: Company
    
    @State private var documents = [
        Document(name: "Invoice.pdf", type: .pdf),
        Document(name: "Contract.png", type: .image)
    ]
    
    @State private var isScannerPresented = false
    @State private var scannedImages: [UIImage] = []
    
    var body: some View {
        Form {
            Section(header: Text("Company Details")) {
                Text("Name: \(company.name)")
                Text("SIRET: \(company.siret)")
            }
            
            Section(header: Text("Documents")) {
                List(documents, id: \.name) { document in
                    NavigationLink {
                        DocumentView(document: document)
                    } label: {
                        Text(document.name)
                    }
                }
                
                Button(action: addDocument) {
                    Label("Add Document", systemImage: "plus")
                }
            }
            
            Section {
                NavigationLink(destination: MapView(
                    primaryLocation: company.primaryLocation,
                    secondaryLocation: company.secondaryLocation
                )) {
                    Text("View Location")
                }
                
                Button("Share Company") {
                    
                }
                
                NavigationLink(destination: ScannedImageView()) {
                    Text("Scanne Image")
                }
                
            }
        }
        .navigationTitle("Company Details")
    }
    
    private func addDocument() {
        
    }
}

//struct Document: Identifiable {
//    var id: String { name }
//    var name: String
//    var type: FileType
//}
//
//enum FileType {
//    case pdf
//    case image
//}
