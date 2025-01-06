//
//  DocumentModel.swift
//  DocumentManager
//
//  Created by TKXON on 06/01/2025.
//

import Foundation
import SwiftData
import UIKit


@available(iOS 17, *)
@Model
class DocumentModel {
    @Attribute(.unique) var id: UUID
    var name: String
    var typeRawValue: String
    var company: CompanyModel?
    var imageData: Data // Store the image as Data
    var imageName: String // Store the image's name
    
    init(name: String, type: FileType, company: CompanyModel, image: UIImage, imageName: String) {
        self.id = UUID()
        self.name = name
        self.typeRawValue = type.rawValue
        self.company = company
        self.imageData = image.jpegData(compressionQuality: 0.8) ?? Data() // Save the image as JPEG data
        self.imageName = imageName
    }
    
    var type: FileType {
        get { FileType(rawValue: typeRawValue) ?? .unknown }
        set { typeRawValue = newValue.rawValue }
    }
    
    func generateImageURL() -> URL? {
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
enum FileType: String {
    case pdf
    case word
    case excel
    case image
    case unknown
}

