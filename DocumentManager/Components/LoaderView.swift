//
//  LoaderView.swift
//  DocumentManager
//
//  Created by TKXON on 12/01/2025.
//

import SwiftUI

struct LoaderView: View {
    var message: String = "Loading..."
       
    var body: some View {
        VStack(spacing: 10) {
            ProgressView(message)
                .progressViewStyle(CircularProgressViewStyle())
                .padding()
                .background(Color.black)
                .cornerRadius(10)
                .foregroundStyle(.white)
        }

        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.4))
        .cornerRadius(10)
        .ignoresSafeArea()
    }
}
