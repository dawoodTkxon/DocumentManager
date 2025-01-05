//
//  FilePicker.swift
//  DocumentManager
//
//  Created by TKXON on 04/01/2025.
//


import SwiftUI
import UniformTypeIdentifiers

struct FilePicker: UIViewControllerRepresentable {
    var onPicked: (URL?) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onPicked: onPicked)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.data, UTType.content, UTType.item])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var onPicked: (URL?) -> Void

        init(onPicked: @escaping (URL?) -> Void) {
            self.onPicked = onPicked
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            onPicked(urls.first) // Select the first file
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            onPicked(nil) // Handle cancellation
        }
    }
}
