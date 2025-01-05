//
//  ScannedImageView.swift
//  DocumentManager
//
//  Created by TKXON on 05/01/2025.
//

import Foundation
import SwiftUI

struct ScannedImageView: View {
    @State private var isScannerPresented = false
    @State private var scannedImages: [UIImage] = []
    
    var body: some View {
        VStack {
            if !scannedImages.isEmpty {
                ScrollView {
                    ForEach(scannedImages, id: \.self) { image in
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .padding()
                    }
                }
            } else {
                Text("No documents scanned.")
                    .foregroundColor(.gray)
            }
            
            Button(action: {
                isScannerPresented = true
            }) {
                Text("Scan Document")
                    .font(.headline)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .sheet(isPresented: $isScannerPresented) {
            DocumentScannerView(scannedImages: $scannedImages, isPresented: $isScannerPresented)
        }
    }
}
