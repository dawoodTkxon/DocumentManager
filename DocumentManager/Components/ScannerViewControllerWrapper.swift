//
//  ScannerViewControllerWrapper.swift
//  DocumentManager
//
//  Created by TKXON on 12/01/2025.
//

import SwiftUI
import UIKit
import CloudKit
import VisionKit


@available(iOS 13.0, *)
struct ScannerViewControllerWrapper: UIViewControllerRepresentable {
    @Binding var scannedImages: [UIImage]

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let viewController = VNDocumentCameraViewController()
        viewController.delegate = context.coordinator
        return viewController
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    // Create a Coordinator to handle delegate methods
    func makeCoordinator() -> Coordinator {
        return Coordinator(scannedImages: $scannedImages)
    }

    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        @Binding var scannedImages: [UIImage]

        init(scannedImages: Binding<[UIImage]>) {
            _scannedImages = scannedImages
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            for pageIndex in 0..<scan.pageCount {
                let image = scan.imageOfPage(at: pageIndex)
                scannedImages.append(image)
            }
            controller.dismiss(animated: true, completion: nil)
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            controller.dismiss(animated: true, completion: nil)
        }
    }
}
