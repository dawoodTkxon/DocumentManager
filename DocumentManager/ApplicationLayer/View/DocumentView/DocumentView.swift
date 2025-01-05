//
//  DocumentView.swift
//  DocumentManager
//
//  Created by TKXON on 05/01/2025.
//

import Foundation
import SwiftUI

@available(iOS 17, *)
struct DocumentView: View {
    var document: Document
    @Environment(\.presentationMode) var presentationMode
    var body: some View {
        VStack {
            if document.type == .pdf {
                Text("PDF Preview: \(document.name)")
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 300)
            }
            Spacer()
            
            Button("Close") {
                presentationMode.wrappedValue.dismiss() // Dismiss the current view
            }
        }
        .padding()
        .navigationTitle(document.name)
    }
}


