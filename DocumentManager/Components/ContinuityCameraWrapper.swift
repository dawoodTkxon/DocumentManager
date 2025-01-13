//
//  ContinuityCameraWrapper.swift
//  DocumentManager
//
//  Created by TKXON on 12/01/2025.
//

import Foundation
import SwiftUI


// A SwiftUI view that wraps Continuity Camera on macOS/Mac Catalyst
@available(iOS 13.0, *)
struct ContinuityCameraView: View {
    @Binding var scannedImages: [UIImage]
    @Binding var isPresented: Bool
    
    var body: some View {
        ContinuityCameraWrapper(scannedImages: $scannedImages, isPresented: $isPresented)
    }
}

@available(iOS 13.0, *)
struct ContinuityCameraWrapper: UIViewControllerRepresentable {
    @Binding var scannedImages: [UIImage]
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let pickerController = UIImagePickerController()
        pickerController.sourceType = .camera
        pickerController.cameraDevice = .front
        pickerController.delegate = context.coordinator
        return pickerController
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(scannedImages: $scannedImages, isPresented: $isPresented)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        @Binding var scannedImages: [UIImage]
        @Binding var isPresented: Bool
        
        init(scannedImages: Binding<[UIImage]>, isPresented: Binding<Bool>) {
            _scannedImages = scannedImages
            _isPresented = isPresented
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                scannedImages.append(image)
            }
            isPresented = false
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            isPresented = false
        }
    }
}



