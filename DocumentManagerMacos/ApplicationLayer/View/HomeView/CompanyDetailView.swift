//
//  CompanyDetailView.swift
//
//
//  Created by TKXON on 05/01/2025.
//

import SwiftUI
import MapKit
import SwiftData
import AppKit
import GoogleSignIn
import GoogleAPIClientForREST
import GTMSessionFetcher

@available(macOS 13.0, *)
struct CompanyDetailView: View {
    var company: CompanyModel
    @State private var scannedImages: [NSImage] = []
    @State private var selectedDocument: DocumentModel?
    @State private var isUploading: Bool = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @Environment(\.dismiss) private var dismiss
    @State private var navigate = false // Add this state variable
    var body: some View {
        VStack {
            content
            if isUploading {
                ProgressView("Uploading...")
                    .padding()
            }
        }
        .alert("Confirmation", isPresented: $showAlert) {
            Button("OK") {}
        } message: {
            Text(alertMessage)
        }
        .navigationTitle("Company Details")
    }

    // MARK: - Content

    private var content: some View {
        HStack {
            VStack(alignment: .leading, spacing: 20) {
                companyDetailsSection
                documentsSection
                actionsSection
            }
            .padding()

            Spacer()
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Sections

    private var companyDetailsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Company Details")
                .font(.title2)
                .font(.headline)

            Text("Name: \(company.name ?? "n/a")")
                .font(.callout)

            Text("SIRET: \(company.siret ?? "n/a")")
                .font(.callout)
        }
    }

    private var documentsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Documents")
                .font(.title2)
                .font(.headline)


            if company.documents.isEmpty {
                Text("No documents available.")
                    .foregroundColor(.gray)
                    .font(.headline)
            } else {
                List(company.documents, id: \.id) { document in
                    Text(document.name ?? "n/a")
                        .onTapGesture {
                            handleDocumentTap(document)
                        }
                }
            }

            
                HStack {
                    Text("Add Document")
                    Image(systemName: "plus")
                        
                }
                .font(.headline)
                .padding(10)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(4)
                .onTapGesture {
                    navigate = true
                }
                .background(
                    NavigationLink(
                        destination: ScannedImageView(company: company),
                        isActive: $navigate
                    ) {
                        EmptyView()
                    }
                    .hidden()
                )
            
        }
    }

    private var actionsSection: some View {
        HStack(spacing: 20) {
            NavigationLink(destination: MapView(
                primaryLocation: CLLocationCoordinate2D(
                    latitude: company.primaryLocationLatitude ?? 0.0,
                    longitude: company.primaryLocationLongitude ?? 0.0
                ),
                secondaryLocation: CLLocationCoordinate2D(
                    latitude: company.secondaryLocationLatitude ?? 0.0,
                    longitude: company.secondaryLocationLongitude ?? 0.0
                )
            )) {
                Text("View Location")
                    .padding(10)
            }

            Button(action: shareCompany) {
                Text("Share Company")
                    .padding(10)
            }

            Spacer()

            Button(action: { dismiss() }) {
                Text("Back")
                    .font(.headline)
            }
        }
    }

    // MARK: - Actions

    private func shareCompany() {
        alertMessage = "Share company logic here."
        showAlert = true
    }

    private func handleDocumentTap(_ document: DocumentModel) {
        guard let imageURL = document.generateImageURL() else {
            alertMessage = "Failed to generate image URL."
            showAlert = true
            return
        }

        isUploading = true
        GoogleDriveSingletonClass.shared.uploadFile(
            name: document.name ?? "n/a",
            folderID: company.folderID,
            fileURL: imageURL,
            mimeType: "image/jpeg"
        ) { success in
            DispatchQueue.main.async {
                isUploading = false
                alertMessage = success ? "File uploaded successfully." : "Failed to upload file."
                showAlert = true
            }
        }
    }
}
