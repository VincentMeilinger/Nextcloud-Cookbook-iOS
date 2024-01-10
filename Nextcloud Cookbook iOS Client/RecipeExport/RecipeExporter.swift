//
//  RecipeToPDF.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 08.01.24.
//

import Foundation
import TPPDF
import SwiftUI

class RecipeExporter {

    func createPDF(recipe: RecipeDetail, image: UIImage?) -> URL? {
        let document = PDFDocument(format: .a4)
        
        let titleStyle = PDFTextStyle(name: "title", font: UIFont.boldSystemFont(ofSize: 18), color: .black)
        let headerStyle = PDFTextStyle(name: "header", font: UIFont.boldSystemFont(ofSize: 16), color: .darkGray)
        let textStyle = PDFTextStyle(name: "text", font: UIFont.systemFont(ofSize: 14), color: .black)

        let titleSection = PDFSection(columnWidths: [0.5, 0.5])
        if let image = image, let resizedImage = cropAndResizeImage(image: image, targetHeight: 150) {
            let pdfImg = PDFImage(
                image: resizedImage,
                size: resizedImage.size,
                options: [.rounded],
                cornerRadius: 5
            )
            titleSection.columns[0].add(image: pdfImg)
        }
        
        // Title
        titleSection.columns[1].add(textObject: PDFSimpleText(text: recipe.name, style: titleStyle))
        
        // Description
        if !recipe.description.isEmpty {
            titleSection.columns[1].add(space: 10)
            titleSection.columns[1].add(textObject: PDFSimpleText(text: recipe.description, style: textStyle))
        }
        
        // Time
        if let prepTime = recipe.prepTime, let prepTimeString = DurationComponents.ptToText(prepTime) {
            let prepString = "Preparation time: \(prepTimeString)"
            titleSection.columns[1].add(space: 10)
            titleSection.columns[1].add(textObject: PDFSimpleText(text: prepString, style: textStyle))
        }
        
        if let cookTime = recipe.cookTime, let cookTimeString = DurationComponents.ptToText(cookTime) {
            let cookString = "Cooking time: \(cookTimeString)"
            titleSection.columns[1].add(space: 10)
            titleSection.columns[1].add(textObject: PDFSimpleText(text: cookString, style: textStyle))
        }
        
        document.add(section: titleSection)
        
        // Ingredients
        var ingr = ""
        for ingredient in recipe.recipeIngredient {
            ingr.append("• \(ingredient)\n")
        }
                
        let section = PDFSection(columnWidths: [0.5, 0.5])
        section.columns[0].add(textObject: PDFSimpleText(text: ingr, style: textStyle))
        document.add(space: 20)
        document.add(section: section)
        
        // Instructions
        var instr = ""
        for instruction in recipe.recipeInstructions {
            instr += instruction + "\n\n"
        }
        document.add(space: 10)
        document.add(textObject: PDFSimpleText(text: instr, style: textStyle))
        
        // Generate PDF
        let generator = PDFGenerator(document: document)
        
        do {
            return try generator.generateURL(filename: "\(recipe.name).pdf")
        } catch {
            return nil
        }
    }
    
    func createText(recipe: RecipeDetail) -> String {
        var recipeString = ""
        recipeString.append("☛ " + recipe.name + "\n")
        recipeString.append(recipe.description + "\n\n")
        
        for ingredient in recipe.recipeIngredient {
            recipeString.append("•" + ingredient + "\n")
        }
        recipeString.append("\n")
        var counter = 1
        for instruction in recipe.recipeInstructions {
            recipeString.append("\(counter). " + instruction + "\n")
            counter += 1
        }
        return recipeString
    }
    
    func createJson(recipe: RecipeDetail) -> Data? {
        return JSONEncoder.safeEncode(recipe)
    }
}


private extension RecipeExporter {
    func resizeImage(image: UIImage, targetHeight: CGFloat) -> UIImage? {
        let size = image.size

        let heightRatio = targetHeight / size.height
        let newSize = CGSize(width: size.width * heightRatio, height: targetHeight)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resizedImage = renderer.image { (context) in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }

        return resizedImage
    }
    
    func cropAndResizeImage(image: UIImage, targetHeight: CGFloat) -> UIImage? {
        let originalSize = image.size
        let targetAspectRatio = 4.0 / 3.0
        var cropRect: CGRect

        // Calculate the rect to crop to 4:3
        if originalSize.width / originalSize.height > targetAspectRatio {
            // Image is wider than 4:3, crop width
            let croppedWidth = originalSize.height * targetAspectRatio
            let cropX = (originalSize.width - croppedWidth) / 2.0
            cropRect = CGRect(x: cropX, y: 0, width: croppedWidth, height: originalSize.height)
        } else {
            // Image is narrower than 4:3, crop height
            let croppedHeight = originalSize.width / targetAspectRatio
            let cropY = (originalSize.height - croppedHeight) / 2.0
            cropRect = CGRect(x: 0, y: cropY, width: originalSize.width, height: croppedHeight)
        }

        // Crop the image
        guard let croppedCGImage = image.cgImage?.cropping(to: cropRect) else { return nil }
        let croppedImage = UIImage(cgImage: croppedCGImage)

        // Resize the cropped image
        let resizeRatio = targetHeight / croppedImage.size.height
        let resizedSize = CGSize(width: croppedImage.size.width * resizeRatio, height: targetHeight)

        let renderer = UIGraphicsImageRenderer(size: resizedSize)
        let resizedImage = renderer.image { (context) in
            croppedImage.draw(in: CGRect(origin: .zero, size: resizedSize))
        }

        return resizedImage
    }
}
