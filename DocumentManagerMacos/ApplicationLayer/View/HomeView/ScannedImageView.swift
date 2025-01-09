//
//  ScannedImageView.swift
//  DocumentManagerMacOS
//
//  Created by TKXON on 05/01/2025.
//

import Foundation
import SwiftUI
import VisionKit

#if os(macOS)
import AppKit
#endif

@available(iOS 17, *)

struct ScannedImageView: View {
    @State private var isScannerPresented = false
//    @State private var scannedImages: [NSImage] = []
    @State private var documentName: String = ""
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dismiss) private var dismiss

    let company: CompanyModel
    @Environment(\.modelContext) private var modelContext
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    @State private var image: NSImage?
    @State private var icon: NSImage?
    @State private var fileType: UTType?
    @State private var fileName: String?
    @State private var message: String?
    @State private var hovering = false

    var body: some View {
        VStack {
            HStack{
                
                VStack(alignment: .leading, spacing: 20) {
                    Text("Policastro Service")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Boréale Project")
                        .font(.subheadline)
        
                    labeledTextField(title: "Enter document name", text: $documentName)
             
                
                    Section(header: Text("Scanned Documents")) {
                        if image == nil {
                            Text("No documents scanned.")
                                .foregroundColor(.gray)
                        } else {
                            
                            if let image = self.image {
                                Image(nsImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 200)
                                    .padding()
                            }
                        }
                    }
                    
                    Section {
                        
               
                        Text("Right Click to add Document")
                            .font(.headline)
                            .padding(10)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                            .allowsHitTesting(false)
                            .background(
                                ContinuityCameraStartView(placeholder: "") { data, fileType in
                                    print("ContinuityCamera is sending \(fileType): \(data)")
                                    self.showImage(data: data, fileType: fileType)
                                    return true
                                }
                            )
                        
                        
        
                        
                        
                        HStack{
                            
                            
                            Button("Save") {
                                saveScannedDocument()
                            }
                            
                            
                            Button("Cancel") {
                                presentationMode.wrappedValue.dismiss()
                            }
                            .foregroundColor(.red)
                            
                            Spacer()
                            
                            Button("Back") {
                                presentationMode.wrappedValue.dismiss()
                            }
                            .foregroundColor(.red)
                        }
                    }
                    
                }
                
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .padding()
            .onDrop(of: [.fileURL], isTargeted: $hovering, perform: { (itemProviders, targetPosition) -> Bool in
                let urlIdentifier = UTType.fileURL.identifier
                for itemProvider in itemProviders {
                    if itemProvider.hasItemConformingToTypeIdentifier(urlIdentifier) {
                        itemProvider.loadItem(forTypeIdentifier: urlIdentifier, options: nil, completionHandler: { (item, error) in
                            if let error = error {
                                print(error)
                            }
                            if let item = item,
                               let data = item as? Data,
                               let url = URL(dataRepresentation: data, relativeTo: nil),
                               let data = try? Data(contentsOf: url),
                               let fileType = UTType(filenameExtension: url.pathExtension)
                            {
                                self.showImage(data: data, fileType: fileType, fileName: url.lastPathComponent)
                            }
                            else {
                                print("Something is wrong with the data: \(String(describing: item))")
                            }
                        })
                        return true
                    }
                }
                return false
            })
            .sheet(isPresented: $isScannerPresented) {
                
                if !isMac() {
                    DocumentScannerView(scannedImage: $image, isPresented: $isScannerPresented)
                    
                } else {
                    ContinuityCameraView(scannedImage: $image, isPresented: $isScannerPresented)
                    
                    
                }
                
            }
        }
        
    }
    private func showImage(data: Data, fileType: UTType, fileName: String = "No Name") {
        let nsImage = NSImage(data: data)
        DispatchQueue.main.async {
            self.image = nsImage
            self.fileType = fileType
            self.icon = NSWorkspace.shared.icon(for: fileType)
            self.fileName = fileName
            self.message = nsImage == nil ? "Not a valid image" : nil
        }
    }
    private func saveScannedDocument() {
        guard !documentName.isEmpty, let scannedImage = image else {
              return
          }
        let imageName = "\(documentName)_image.jpg"  
        
        guard let imageData = scannedImage.jpegData(compressionQuality: 0.8) else { return }
        
        let newDocument = DocumentModel(
            name: documentName,
            type: .image,
            company: company,
            image: scannedImage,
            imageName: imageName
        )
        
        modelContext.insert(newDocument)
        
        // Save the context
        do {
            try modelContext.save()
            print("Document saved successfully.")
            alertMessage = "Document saved successfully."
            showAlert = true
        } catch {
            print("Failed to save document: \(error)")
            alertMessage = "Failed to save document. Please try again."
            showAlert = true
        }
    }
    private func uploadToGoogleDrive(scannedImages: [NSImage], name: String, completion: @escaping (Result<String, Error>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            completion(.success("https://drive.google.com/file/dummy-link"))
        }
    }
    
    
    private func labeledTextField(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.headline)
            TextField("", text: text)
                .frame(maxWidth: 300)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }

    
    private func isMac() -> Bool {
        if ProcessInfo.processInfo.isiOSAppOnMac {
            return true
        }
        return false
    }
}


// Extension to convert NSImage to UIImage on macOS
#if os(macOS)
//extension NSImage {
//    func toUIImage() -> NSImage? {
//        let data = self.tiffRepresentation
//        guard let bitmapImageRep = NSBitmapImageRep(data: data!),
//              let cgImage = bitmapImageRep.cgImage else { return nil }
//        return NSImage(cgImage: cgImage, size: 40)
//    }
//}
#endif


//// A SwiftUI view that wraps Continuity Camera on macOS/Mac Catalyst
import SwiftUI
import AppKit
import UniformTypeIdentifiers

@available(macOS 13.0, *)
struct ContinuityCameraView: View {
    @Binding var scannedImage: NSImage?  // Now it's a single image
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack {
            Button(action: openContinuityCamera) {
                Label("Use Continuity Camera", systemImage: "camera")
            }
            .padding()
        }
    }

    private func openContinuityCamera() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false  // Allow only single file selection
        panel.allowedContentTypes = [.image, .pdf] // Allow images or PDFs

        panel.begin { response in
            if response == .OK, let url = panel.url {
                if let image = NSImage(contentsOf: url) {
                    scannedImage = image  // Set the single scanned image
                }
            }
            isPresented = false // Close the presentation
        }
    }
}






import SwiftUI
import AppKit

@available(macOS 13.0, iOS 13.0, *)
struct ContinuityCameraWrapper: View {
    @Binding var scannedImages: [NSImage]
    @Binding var isPresented: Bool

    var body: some View {
        Button(action: openContinuityCamera) {
            Label("Use Continuity Camera", systemImage: "camera")
        }
    }

    private func openContinuityCamera() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.image, .pdf]

        panel.begin { response in
            if response == .OK, let url = panel.url {
                if let image = NSImage(contentsOf: url) {
                    scannedImages.append(image)
                }
            }
            isPresented = false
        }
    }
}


struct ContinuityCameraStartView: NSViewRepresentable {
    
    let placeholder: String
    let handler: (Data, UTType) -> Bool

    typealias NSViewType = MyTextView
    
    func makeNSView(context: Context) -> MyTextView {
        let view = MyTextView()
        view.string = placeholder
        view.drawsBackground = false
        view.insertionPointColor = NSColor.textBackgroundColor
        view.autoresizingMask = [.width, .height]
        view.delegate = context.coordinator

        return view
    }
    
    func updateNSView(_ nsViewController: MyTextView, context: Context) {
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate, NSServicesMenuRequestor {
        var parent: ContinuityCameraStartView

        init(_ parent: ContinuityCameraStartView) {
            self.parent = parent
            super.init()
        }
        
        required init?(coder: NSCoder) {
            fatalError()
        }
        
        func readSelection(from pasteboard: NSPasteboard) -> Bool {
            // Verify that the pasteboard contains image data.
            guard pasteboard.canReadItem(withDataConformingToTypes: NSImage.imageTypes) else {
                return false
            }

            let validImageTypes = Set(NSImage.imageTypes)
            let availableTypes = (pasteboard.types ?? []).map(\.rawValue)
            let availableImageTypes = validImageTypes.intersection(availableTypes)

            // If multiple formats are available, try looking for jpeg first
            let jpegIdentifier = UTType.jpeg.identifier
            if availableImageTypes.contains(jpegIdentifier) {
                if let data = pasteboard.data(forType: NSPasteboard.PasteboardType(jpegIdentifier)) {
                    if parent.handler(data, .jpeg) {
                        return true
                    }
                }
            }
            
            var result = false
            availableTypes.forEach { type in
                if !result,
                   let utType = UTType(type),
                   let data = pasteboard.data(forType: NSPasteboard.PasteboardType(type))
                {
                    if parent.handler(data, utType) {
                        result = true
                    }
                }
            }

            return result
        }

        func textView(_ view: NSTextView, menu: NSMenu, for event: NSEvent, at charIndex: Int) -> NSMenu? {
            // Return an empty context menu
            return NSMenu(title: menu.title)
        }

        func textView(_ textView: NSTextView, willChangeSelectionFromCharacterRange oldSelectedCharRange: NSRange, toCharacterRange newSelectedCharRange: NSRange) -> NSRange {
            // Ignore user selection
            NSMakeRange(0, 0)
        }
    }

    final class MyTextView: NSTextView {
        override func validRequestor(forSendType sendType: NSPasteboard.PasteboardType?, returnType: NSPasteboard.PasteboardType?) -> Any? {
            if let pasteboardType = returnType,
                // Service is image related.
                NSImage.imageTypes.contains(pasteboardType.rawValue) {
                return self.delegate
            } else {
                // Let objects in the responder chain handle the message.
                return super.validRequestor(forSendType: sendType, returnType: returnType)
            }
        }
    }
}
