//
//  DocumentScannerView.swift
//  DocumentManagerMacos
//
//  Created by TKXON on 05/01/2025.
//

import Foundation
import SwiftUI
import VisionKit
import AppKit



import Foundation
import SwiftUI
import AppKit

struct DocumentScannerView: View {
    @Binding var scannedImage: NSImage?  // Now it's a single image
    @Binding var isPresented: Bool

    var body: some View {
        VStack {
            Text("Select Document")
                .font(.headline)
                .padding()

            Button("Choose File") {
                selectFile()
            }
            .padding()
        }
        .frame(maxWidth: 400, maxHeight: 200)
    }

    private func selectFile() {
        let panel = NSOpenPanel()
        panel.allowedFileTypes = ["png", "jpg", "jpeg", "tiff", "pdf"] // Allow image and PDF types
        panel.allowsMultipleSelection = false  // Only allow single selection
        panel.canChooseDirectories = false
        panel.canCreateDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            if let image = NSImage(contentsOf: url) {
                scannedImage = image  // Set the single scanned image
            } else {
                print("Failed to load image from URL: \(url)")
            }
            isPresented = false
        } else {
            isPresented = false
        }
    }
}

//struct DocumentScannerView: View {
//    @Binding var scannedImages: [NSImage] // Use NSImage for macOS
//    @Binding var isPresented: Bool
//
//    var body: some View {
//        VStack {
//            Text("Select Documents")
//                .font(.headline)
//                .padding()
//
//            Button("Choose Files") {
//                selectFiles()
//            }
//            .padding()
//        }
//        .frame(maxWidth: 400, maxHeight: 200)
//    }
//
//    private func selectFiles() {
//        let panel = NSOpenPanel()
//        panel.allowedFileTypes = ["png", "jpg", "jpeg", "tiff", "pdf"] // Allow image and PDF types
//        panel.allowsMultipleSelection = true
//        panel.canChooseDirectories = false
//        panel.canCreateDirectories = false
//
//        if panel.runModal() == .OK {
//            for url in panel.urls {
//                if let image = NSImage(contentsOf: url) {
//                    scannedImages.append(image)
//                } else {
//                    print("Failed to load image from URL: \(url)")
//                }
//            }
//            isPresented = false
//        } else {
//            isPresented = false
//        }
//    }
//}



//struct DocumentScannerView: View {
//    @Binding var scannedImages: [UIImage]
//    @Binding var isPresented: Bool
//
//    var body: some View {
//        DocumentScannerCoordinator(scannedImages: $scannedImages, isPresented: $isPresented)
//            .edgesIgnoringSafeArea(.all)
//    }
//}

import SwiftUI
import AppKit

struct DocumentScannerCoordinator: NSViewRepresentable {
    @Binding var scannedImages: [NSImage]
    @Binding var isPresented: Bool

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            openFilePicker()
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        // No updates needed
    }

    private func openFilePicker() {
        let panel = NSOpenPanel()
        panel.allowedFileTypes = ["png", "jpg", "jpeg", "tiff", "pdf"] // Supported file types
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canCreateDirectories = false

        if panel.runModal() == .OK {
            for url in panel.urls {
                if let image = NSImage(contentsOf: url) {
                    scannedImages.append(image)
                } else {
                    print("Failed to load image from URL: \(url)")
                }
            }
            isPresented = false
        } else {
            isPresented = false
        }
    }
}
