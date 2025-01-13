//
//  ContinuityCameraView.swift
//  DocumentManagerMacos
//
//  Created by TKXON on 13/01/2025.
//

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
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.image, .pdf]

        panel.begin { response in
            if response == .OK, let url = panel.url {
                if let image = NSImage(contentsOf: url) {
                    scannedImage = image
                }
            }
            isPresented = false
        }
    }
}

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
