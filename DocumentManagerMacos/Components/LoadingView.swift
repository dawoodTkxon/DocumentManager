//
//  LoadingView.swift
//  DocumentManager
//
//  Created by TKXON on 07/01/2025.
//

import SwiftUI

struct LoadingView: View {
    var message: String = "Plesase wait..."
    
    var body: some View {
        VStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5) 
                .padding()
            
            Text(message)
                .font(.headline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.4)) // Semi-transparent background
        .edgesIgnoringSafeArea(.all)
    }
}
