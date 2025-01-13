//
//  AddNewCompanyView.swift
//  DocumentManager
//
//  Created by TKXON on 05/01/2025.
//

import Foundation
import SwiftUI
import SwiftData
import MapKit
import AppKit

@available(macOS 14, *)
struct AddCompanyView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var vm: CloudKitViewModel

    @State private var name = ""
    @State private var siret = ""
    @State private var primaryLatitude = ""
    @State private var primaryLongitude = ""
    @State private var secondaryLatitude = ""
    @State private var secondaryLongitude = ""

    @State private var isSaving = false

    var body: some View {
        HStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    companyInfoSection
                    primaryLocationSection
                    secondaryLocationSection
                    actionButtons
                }
                .navigationTitle("Add Company")
                .padding(20)
            }
            .frame(maxHeight: .infinity, alignment: .top)

            Spacer()
        }
        .disabled(isSaving)
        .background(Group { if isSaving{LoaderView()}})
    }

    // MARK: - Sections

    private var companyInfoSection: some View {
        Section(header: Text("Company Info")) {
            VStack(alignment: .leading, spacing: 10) {
                labeledTextField(title: "Name", text: $name)
                labeledTextField(title: "Siret", text: $siret)
            }
        }
    }

    private var primaryLocationSection: some View {
        Section(header: Text("Primary Location")) {
            VStack(alignment: .leading, spacing: 10) {
                labeledTextField(title: "Latitude", text: $primaryLatitude)
                labeledTextField(title: "Longitude", text: $primaryLongitude)
            }
        }
    }

    private var secondaryLocationSection: some View {
        Section(header: Text("Secondary Location")) {
            VStack(alignment: .leading, spacing: 10) {
                labeledTextField(title: "Latitude", text: $secondaryLatitude)
                labeledTextField(title: "Longitude", text: $secondaryLongitude)
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 10) {
            Button("Cancel") {
                dismiss()
            }

            Button("Save") {
                saveCompany()
            }
        }
    }

    // MARK: - Helper Views
    private func labeledTextField(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.headline)
            TextField("", text: text)
                .frame(maxWidth: 300)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }

    // MARK: - Save Logic
    private func saveCompany() {
        isSaving = true
        guard let primaryLat = Double(primaryLatitude),
              let primaryLon = Double(primaryLongitude),
              let secondaryLat = Double(secondaryLatitude),
              let secondaryLon = Double(secondaryLongitude) else {
            print("Invalid coordinates")
            return
        }

        isSaving = true

        let newCompany = CompanyModel(
            name: name,
            siret: siret,
            primaryLocation: CLLocationCoordinate2D(latitude: primaryLat, longitude: primaryLon),
            secondaryLocation: CLLocationCoordinate2D(latitude: secondaryLat, longitude: secondaryLon), folderID: ""
        )

        modelContext.insert(newCompany)

        do {
            try modelContext.save()
            print("Company saved successfully.")

             if !GoogleSignInManager.shared.folderCreated {
                GoogleSignInManager.shared.createFolder(name: name) { folderID in
                    DispatchQueue.main.async {
                        if let folderID = folderID {
                            newCompany.folderID = folderID
                            do {
                                try modelContext.save()
                                print("Company saved successfully with folderID: \(folderID).")

                                Task {
                                    try await vm.addCompnay(
                                        name: name,
                                        siret: siret,
                                        primaryLocationLatitude: primaryLat,
                                        primaryLocationLongitude: primaryLon,
                                        secondaryLocationLatitude: secondaryLat,
                                        secondaryLocationLongitude: secondaryLon, folderID:  newCompany.folderID
                                   
                                    )
                                }
                                dismiss()

                            } catch {
                                print("Failed to save company: \(error)")
                                isSaving = false
                            }
                        } else {
                            print("Failed to create folder.")
                            isSaving = false
                        }
                    }
                }
            } else {
                isSaving = false
            }
        } catch {
            print("Failed to save company: \(error)")
            isSaving = false
        }
    }
}
