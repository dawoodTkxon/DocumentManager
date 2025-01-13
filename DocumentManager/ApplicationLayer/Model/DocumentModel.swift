//
//  DocumentModel.swift
//  DocumentManager
//
//  Created by TKXON on 06/01/2025.
//

import Foundation
import SwiftData

#if os(macOS)
import AppKit
#endif

#if os(iOS)
import UIKit
#endif


#if os(iOS)
@available(iOS 17, *)
@Model
class DocumentModel {
    var id = UUID()
    var name: String? = ""
    var typeRawValue: String? = ""
    var company: CompanyModel? = CompanyModel()
    var imageData: Data? = Data() // Store the image as Data
    var imageName: String? = ""// Store the image's name
    
    init(name: String, type: FileType, company: CompanyModel, image: UIImage, imageName: String) {
        self.id = UUID()
        self.name = name
        self.typeRawValue = type.rawValue
        self.company = company
        self.imageData = image.jpegData(compressionQuality: 0.8) ?? Data() // Save the image as JPEG data
        self.imageName = imageName
    }
    
    
      var type: FileType {
          get {return FileType(rawValue: typeRawValue ?? FileType.unknown.rawValue) ?? .unknown}
          set {typeRawValue = newValue.rawValue}
      }
    
    func generateImageURL() -> URL? {
            guard let imageName = imageName else {
                print("Image name is nil")
                return nil
            }

            let tempDirectory = FileManager.default.temporaryDirectory
            let fileURL = tempDirectory.appendingPathComponent(imageName)

            do {
                try imageData?.write(to: fileURL)
                return fileURL
            } catch {
                print("Failed to write image data to URL: \(error)")
                return nil
            }
        }
    func compareImageURLs(existingImageURL: URL?, currentImageURL: URL?) -> Bool {
        guard
            let existingURL = existingImageURL,
            let currentURL = currentImageURL
        else {
            print("One or both URLs are nil.")
            return false
        }

        do {
            // Fetch the image data from the URLs
            let existingImageData = try Data(contentsOf: existingURL)
            let currentImageData = try Data(contentsOf: currentURL)

            // Compare the data
            if existingImageData == currentImageData {
                print("The images are identical.")
                return true
            } else {
                print("The images are different.")
                return false
            }
        } catch {
            print("Error fetching image data: \(error)")
            return false
        }
    }

}
#endif


#if os(macOS)
import SwiftUI
import AppKit
import Foundation

@available(macOS 13.0, *)
@Model
class DocumentModel: Identifiable {
    var id = UUID()
    var name: String? 
    var typeRawValue: String?
    var company: CompanyModel?
    var imageData: Data?
    var imageName: String?
    
    init(name: String?, type: FileType?, company: CompanyModel?, image: NSImage?, imageName: String?) {
        self.id = UUID()
        self.name = name
        self.typeRawValue = type?.rawValue
        self.company = company
        self.imageData = image?.jpegData(compressionQuality: 0.8) ?? nil // Safely convert NSImage to JPEG Data
        self.imageName = imageName
    }
    
    var type: FileType {
        get { FileType(rawValue: typeRawValue ?? "") ?? .unknown }
        set { typeRawValue = newValue.rawValue }
    }
    
    func generateImageURL() -> URL? {
        guard let imageName = imageName, let imageData = imageData else {
            print("Image name or data is missing.")
            return nil
        }
        
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(imageName)
        
        do {
            try imageData.write(to: fileURL)
            return fileURL
        } catch {
            print("Failed to write image data to URL: \(error)")
            return nil
        }
    }
}

extension NSImage {
    /// Converts `NSImage` to JPEG `Data` with specified compression quality.
    func jpegData(compressionQuality: CGFloat) -> Data? {
        guard let tiffRepresentation = self.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffRepresentation) else {
            print("Failed to create bitmap representation.")
            return nil
        }
        return bitmap.representation(using: .jpeg, properties: [.compressionFactor: compressionQuality])
    }
}
#endif


enum FileType: String {
    case pdf
    case word
    case excel
    case image
    case unknown
}

