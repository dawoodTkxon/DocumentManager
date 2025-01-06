//
//  DocumentView.swift
//  DocumentManager
//
//  Created by TKXON on 05/01/2025.
//

import Foundation
import SwiftUI
import SwiftData

@available(iOS 17, *)
struct DocumentView: View {
    var document: DocumentModel
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack {
            if let imageData = UIImage(data: document.imageData){
                Image(uiImage: imageData)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
                    .onTapGesture {
                        dismiss()
                    }
            }
        }
        .padding()
        .navigationTitle(document.name)
        .navigationBarTitleDisplayMode(.large)
        .onAppear{
  
        }
    }
}


