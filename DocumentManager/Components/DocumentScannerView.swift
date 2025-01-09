//
//  DocumentScannerView.swift
//  DocumentManager
//
//  Created by TKXON on 05/01/2025.
//

import Foundation
import SwiftUI
import VisionKit

struct DocumentScannerView: View {
    @Binding var scannedImages: [UIImage]
    @Binding var isPresented: Bool

    var body: some View {
        DocumentScannerCoordinator(scannedImages: $scannedImages, isPresented: $isPresented)
            .edgesIgnoringSafeArea(.all)
    }
}

struct DocumentScannerCoordinator: UIViewControllerRepresentable {
    @Binding var scannedImages: [UIImage]
    @Binding var isPresented: Bool

    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        var scannedImages: Binding<[UIImage]>
        var isPresented: Binding<Bool>

        init(scannedImages: Binding<[UIImage]>, isPresented: Binding<Bool>) {
            self.scannedImages = scannedImages
            self.isPresented = isPresented
        }

        func documentCameraViewControllerDidCancel(_ viewController: VNDocumentCameraViewController) {
            isPresented.wrappedValue = false
        }

        func documentCameraViewController(_ viewController: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            var images: [UIImage] = []
            for i in 0..<scan.pageCount {
                images.append(scan.imageOfPage(at: i))
            }
            scannedImages.wrappedValue = images
            isPresented.wrappedValue = false
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(scannedImages: $scannedImages, isPresented: $isPresented)
    }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let viewController = VNDocumentCameraViewController()
        viewController.delegate = context.coordinator
        return viewController
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {
        // No updates needed
    }
}
