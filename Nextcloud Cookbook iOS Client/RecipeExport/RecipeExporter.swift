//
//  RecipeExporter.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 08.01.24.
//
//  Exports a recipe as PDF, plain text, Markdown or schema.org JSON. Each format
//  is a `Transferable`, so a `ShareLink` only creates the file when the user
//  picks that format.
//

import Foundation
import SwiftUI
import TPPDF
import UniformTypeIdentifiers


// MARK: - Export formats

struct RecipePDFExport: Transferable {
    let recipe: RecipeDetail
    let image: UIImage?

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .pdf) { export in
            SentTransferredFile(try RecipeExporter.pdfFile(recipe: export.recipe, image: export.image))
        }
    }
}

struct RecipeMarkdownExport: Transferable {
    let recipe: RecipeDetail

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .markdownFile) { export in
            SentTransferredFile(try RecipeExporter.write(
                RecipeExporter.markdown(recipe: export.recipe),
                name: export.recipe.name, fileExtension: "md"
            ))
        }
    }
}

struct RecipeJSONExport: Transferable {
    let recipe: RecipeDetail

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .json) { export in
            SentTransferredFile(try RecipeExporter.write(
                RecipeExporter.schemaOrgJSON(recipe: export.recipe),
                name: export.recipe.name, fileExtension: "json"
            ))
        }
    }
}

extension UTType {
    /// Markdown files (.md); declared as plain text so every app can open them.
    static let markdownFile = UTType(filenameExtension: "md", conformingTo: .plainText) ?? .plainText
}


// MARK: - Exporter

enum RecipeExporter {

    // MARK: Plain text

    /// Readable text for messages and notes. Markdown formatting is removed.
    static func text(recipe: RecipeDetail) -> String {
        var lines: [String] = [plain(recipe.name)]
        if !recipe.description.isEmpty { lines += ["", plain(recipe.description)] }
        let facts = facts(of: recipe).map { "\($0.label): \($0.value)" }
        if !facts.isEmpty { lines += [""] + facts }

        if !recipe.recipeIngredient.isEmpty {
            lines += ["", label("Ingredients")] + listLines(recipe.recipeIngredient, heading: plain) { _, item in "• " + plain(item) }
        }
        if !recipe.tool.isEmpty {
            lines += ["", label("Tools")] + listLines(recipe.tool, heading: plain) { _, item in "• " + plain(item) }
        }
        if !recipe.recipeInstructions.isEmpty {
            lines += ["", label("Instructions")] + listLines(recipe.recipeInstructions, heading: plain) { number, item in "\(number). " + plain(item) }
        }
        if let source = sourceURL(of: recipe) { lines += ["", source.absoluteString] }
        return lines.joined(separator: "\n")
    }

    // MARK: Markdown

    /// A Markdown document; the recipe's own Markdown formatting is kept.
    static func markdown(recipe: RecipeDetail) -> String {
        var lines: [String] = ["# \(recipe.name)"]
        if let image = recipe.image, image.hasPrefix("http") { lines += ["", "![\(recipe.name)](\(image))"] }
        if !recipe.description.isEmpty { lines += ["", recipe.description] }
        let facts = facts(of: recipe).map { "- **\($0.label):** \($0.value)" }
        if !facts.isEmpty { lines += [""] + facts }

        if !recipe.recipeIngredient.isEmpty {
            lines += ["", "## \(label("Ingredients"))", ""] + listLines(recipe.recipeIngredient) { _, item in "- \(item)" }
        }
        if !recipe.tool.isEmpty {
            lines += ["", "## \(label("Tools"))", ""] + listLines(recipe.tool) { _, item in "- \(item)" }
        }
        if !recipe.recipeInstructions.isEmpty {
            lines += ["", "## \(label("Instructions"))", ""] + listLines(recipe.recipeInstructions) { number, item in "\(number). \(item)" }
        }
        let nutrition = nutritionRows(of: recipe)
        if !nutrition.isEmpty {
            lines += ["", "## \(label("Nutrition"))", "", "| | |", "|---|---|"]
            lines += nutrition.map { "| \($0.label) | \($0.value) |" }
        }
        if let source = sourceURL(of: recipe) { lines += ["", "[\(source.host() ?? source.absoluteString)](\(source.absoluteString))"] }
        return lines.joined(separator: "\n") + "\n"
    }

    // MARK: schema.org JSON

    /// The schema.org Recipe format used by Nextcloud Cookbook and most recipe
    /// apps and websites, so the file can be imported elsewhere.
    static func schemaOrgJSON(recipe: RecipeDetail) -> String {
        var json: [String: Any] = [
            "@context": "https://schema.org",
            "@type": "Recipe",
            "name": recipe.name,
            "recipeIngredient": recipe.recipeIngredient,
            "recipeInstructions": recipe.recipeInstructions.map { ["@type": "HowToStep", "text": $0] },
            "recipeYield": recipe.recipeYield,
        ]
        func set(_ key: String, _ value: String?) {
            if let value, !value.isEmpty { json[key] = value }
        }
        set("description", recipe.description)
        set("recipeCategory", recipe.recipeCategory)
        set("keywords", recipe.keywords)
        set("prepTime", recipe.prepTime)
        set("cookTime", recipe.cookTime)
        set("totalTime", recipe.totalTime)
        set("url", recipe.url)
        if let image = recipe.image, image.hasPrefix("http") { json["image"] = image }
        if !recipe.tool.isEmpty { json["tool"] = recipe.tool }
        if !recipe.nutrition.isEmpty {
            json["nutrition"] = recipe.nutrition.merging(["@type": "NutritionInformation"]) { current, _ in current }
        }
        let data = (try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])) ?? Data()
        return String(decoding: data, as: UTF8.self)
    }

    // MARK: PDF

    /// Renders the recipe as a PDF file and returns its URL.
    static func pdfFile(recipe: RecipeDetail, image: UIImage?) throws -> URL {
        let format: PDFPageFormat = Locale.current.measurementSystem == .us ? .usLetter : .a4
        let document = PDFDocument(format: format)
        document.info.title = recipe.name
        document.info.author = ""
        document.info.subject = String(localized: "Recipe")
        let width = document.layout.width - document.layout.margin.left - document.layout.margin.right

        // Photo, full width
        if let image, let photo = cropped(image, toAspectRatio: 16 / 9, width: width * 2) {
            document.add(image: PDFImage(
                image: photo,
                size: CGSize(width: width, height: width * 9 / 16),
                options: [.rounded, .compress],
                cornerRadius: 12
            ))
            document.add(space: 16)
        }

        // Title and description
        document.add(attributedText: styled(recipe.name, size: 26, weight: .bold))
        if !recipe.description.isEmpty {
            document.add(space: 6)
            document.add(attributedText: styled(recipe.description, size: 11, color: .darkGray))
        }

        // Category
        if !recipe.recipeCategory.isEmpty {
            document.add(space: 6)
            document.add(attributedText: styled(recipe.recipeCategory, size: 9, color: .gray))
        }

        // Servings and times
        let facts = facts(of: recipe)
        if !facts.isEmpty {
            document.add(space: 14)
            document.add(table: factsTable(facts))
        }

        // Ingredients, tools, instructions
        addListSection(label("Ingredients"), items: recipe.recipeIngredient, to: document)
        addListSection(label("Tools"), items: recipe.tool, to: document)
        addListSection(label("Instructions"), items: recipe.recipeInstructions, numbered: true, to: document)

        // Nutrition
        let nutrition = nutritionRows(of: recipe)
        if !nutrition.isEmpty {
            document.add(space: 18)
            let group = PDFGroup(allowsBreaks: false)
            addHeading(label("Nutrition"), to: group)
            group.add(table: nutritionTable(nutrition))
            document.add(group: group)
        }

        // Footer: source and page numbers
        let footer: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 8), .foregroundColor: UIColor.gray]
        if let source = sourceURL(of: recipe) {
            document.add(.footerLeft, attributedText: NSAttributedString(string: source.absoluteString, attributes: footer))
        }
        document.pagination = PDFPagination(
            container: .footerRight,
            style: .customClosure { page, total in "\(page) / \(total)" },
            textAttributes: footer
        )

        return try PDFGenerator(document: document).generateURL(filename: fileName(recipe.name, fileExtension: "pdf"))
    }

    // MARK: - PDF building blocks

    private static let accent = (UIColor(named: "ncblue") ?? .systemBlue)
        .resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))

    private static func addHeading(_ title: String, to group: PDFGroup) {
        group.add(attributedText: styled(title.uppercased(), size: 11, weight: .bold, color: accent, kern: 1))
        group.add(space: 3)
        group.addLineSeparator(style: PDFLineStyle(type: .full, color: accent.withAlphaComponent(0.4), width: 0.75))
        group.add(space: 8)
    }

    /// A titled list: bullets, or step numbers when `numbered`. Each entry is kept
    /// on one page, and the title stays with the first entry. Group headings
    /// ("For the sauce:") are shown in bold without a marker.
    private static func addListSection(_ title: String, items: [String], numbered: Bool = false, to document: PDFDocument) {
        guard !items.isEmpty else { return }
        document.add(space: 18)
        var number = 0
        for (index, item) in items.enumerated() {
            let group = PDFGroup(allowsBreaks: false)
            if index == 0 { addHeading(title, to: group) }
            if isGroupHeading(item) {
                if index > 0 { group.add(space: 4) }
                group.add(attributedText: styled(item, size: 11, weight: .semibold))
            } else {
                number += 1
                group.add(attributedText: listItem(item, marker: numbered ? "\(number)" : "•"))
            }
            document.add(group: group)
            document.add(space: numbered ? 9 : 4)
        }
    }

    /// One list entry with a hanging indent, so wrapped lines align with the
    /// text rather than the marker.
    private static func listItem(_ item: String, marker: String) -> NSAttributedString {
        let indent: CGFloat = 20
        let paragraph = NSMutableParagraphStyle()
        paragraph.headIndent = indent
        paragraph.tabStops = [NSTextTab(textAlignment: .left, location: indent)]
        paragraph.lineSpacing = 1.5

        let result = NSMutableAttributedString(string: marker + "\t", attributes: [
            .font: UIFont.systemFont(ofSize: 11, weight: .bold),
            .foregroundColor: accent,
        ])
        result.append(styled(item, size: 11))
        result.addAttribute(.paragraphStyle, value: paragraph, range: NSRange(location: 0, length: result.length))
        return result
    }

    private static func factsTable(_ facts: [(label: String, value: String)]) -> PDFTable {
        let table = PDFTable(rows: 1, columns: facts.count)
        table.content = [facts.map { fact -> NSAttributedString in
            let cell = NSMutableAttributedString(attributedString: styled(fact.label.uppercased() + "\n", size: 7.5, weight: .semibold, color: .gray, kern: 0.6))
            cell.append(styled(fact.value, size: 12, weight: .semibold))
            return cell
        }]
        table.alignment = [Array(repeating: .center, count: facts.count)]
        table.widths = Array(repeating: 1 / CGFloat(facts.count), count: facts.count)
        table.padding = 8
        table.style = PDFTableStyle(
            rowHeaderCount: 0, columnHeaderCount: 0, footerCount: 0,
            outline: PDFLineStyle(type: .none),
            contentStyle: PDFTableCellStyle(
                colors: (fill: accent.withAlphaComponent(0.08), text: .black),
                borders: PDFTableCellBorders(right: PDFLineStyle(type: .full, color: .white, width: 2))
            )
        )
        return table
    }

    private static func nutritionTable(_ rows: [(label: String, value: String)]) -> PDFTable {
        let table = PDFTable(rows: rows.count, columns: 2)
        table.content = rows.map { [styled($0.label, size: 10, color: .darkGray), styled($0.value, size: 10, weight: .semibold)] }
        table.alignment = rows.map { _ in [.left, .right] }
        table.widths = [0.65, 0.35]
        table.padding = 5
        table.style = PDFTableStyle(
            rowHeaderCount: 0, columnHeaderCount: 0, footerCount: 0,
            outline: PDFLineStyle(type: .none),
            contentStyle: PDFTableCellStyle(colors: (fill: .white, text: .black)),
            alternatingContentStyle: PDFTableCellStyle(colors: (fill: UIColor(white: 0.96, alpha: 1), text: .black))
        )
        return table
    }

    /// Text in the given style, with the recipe's inline Markdown (bold, italic)
    /// rendered as fonts.
    private static func styled(
        _ text: String,
        size: CGFloat,
        weight: UIFont.Weight = .regular,
        color: UIColor = .black,
        kern: CGFloat = 0
    ) -> NSAttributedString {
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        let options = AttributedString.MarkdownParsingOptions(
            interpretedSyntax: .inlineOnlyPreservingWhitespace,
            failurePolicy: .returnPartiallyParsedIfPossible
        )
        let parsed = (try? AttributedString(markdown: text, options: options)) ?? AttributedString(text)
        let result = NSMutableAttributedString()
        for run in parsed.runs {
            var traits: UIFontDescriptor.SymbolicTraits = []
            if run.inlinePresentationIntent?.contains(.stronglyEmphasized) == true { traits.insert(.traitBold) }
            if run.inlinePresentationIntent?.contains(.emphasized) == true { traits.insert(.traitItalic) }
            let font = base.fontDescriptor.withSymbolicTraits(base.fontDescriptor.symbolicTraits.union(traits))
                .map { UIFont(descriptor: $0, size: size) } ?? base
            result.append(NSAttributedString(
                string: String(parsed[run.range].characters),
                attributes: [.font: font, .foregroundColor: color, .kern: kern]
            ))
        }
        return result
    }

    /// Crops to the aspect ratio (centered) and scales to `width` pixels.
    private static func cropped(_ image: UIImage, toAspectRatio ratio: CGFloat, width: CGFloat) -> UIImage? {
        let size = image.size
        guard size.width > 0, size.height > 0 else { return nil }
        let crop = size.width / size.height > ratio
            ? CGRect(x: (size.width - size.height * ratio) / 2, y: 0, width: size.height * ratio, height: size.height)
            : CGRect(x: 0, y: (size.height - size.width / ratio) / 2, width: size.width, height: size.width / ratio)
        let target = CGSize(width: width, height: width / ratio)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            let scale = target.width / crop.width
            image.draw(in: CGRect(
                x: -crop.minX * scale, y: -crop.minY * scale,
                width: size.width * scale, height: size.height * scale
            ))
        }
    }

    // MARK: - Shared content

    /// A short line ending in a colon, like "For the sauce:", introduces a group of
    /// ingredients or steps rather than being one itself.
    static func isGroupHeading(_ item: String) -> Bool {
        let text = plain(item).trimmingCharacters(in: .whitespaces)
        return text.hasSuffix(":") && text.count <= 60
    }

    /// List lines for text formats: entries via `format` (with their number, which
    /// skips group headings), group headings as a separate line without a marker.
    private static func listLines(_ items: [String], heading: (String) -> String = { $0 }, format: (Int, String) -> String) -> [String] {
        var number = 0
        var lines: [String] = []
        for item in items {
            if isGroupHeading(item) {
                if !lines.isEmpty { lines.append("") }
                lines.append(heading(item))
            } else {
                number += 1
                lines.append(format(number, item))
            }
        }
        return lines
    }

    /// Servings and times that are set, with localized labels.
    private static func facts(of recipe: RecipeDetail) -> [(label: String, value: String)] {
        var facts: [(String, String)] = []
        if recipe.recipeYield > 0 { facts.append((label("Servings"), "\(recipe.recipeYield)")) }
        let times: [(String.LocalizationValue, String?)] = [
            ("Preparation", recipe.prepTime), ("Cooking", recipe.cookTime), ("Total time", recipe.totalTime),
        ]
        for (title, value) in times {
            if let value, let text = DurationComponents.ptToText(value) { facts.append((label(title), text)) }
        }
        return facts
    }

    private static func nutritionRows(of recipe: RecipeDetail) -> [(label: String, value: String)] {
        Nutrition.allCases.compactMap { item in
            guard let value = recipe.nutrition[item.dictKey], !value.isEmpty else { return nil }
            return (item.localizedDescription, value)
        }
    }

    private static func sourceURL(of recipe: RecipeDetail) -> URL? {
        guard let string = recipe.url, string.hasPrefix("http") else { return nil }
        return URL(string: string)
    }

    private static func label(_ key: String.LocalizationValue) -> String {
        String(localized: key)
    }

    /// Text without Markdown syntax ("**Dough:** Knead" → "Dough: Knead").
    private static func plain(_ text: String) -> String {
        let options = AttributedString.MarkdownParsingOptions(
            interpretedSyntax: .inlineOnlyPreservingWhitespace,
            failurePolicy: .returnPartiallyParsedIfPossible
        )
        return (try? AttributedString(markdown: text, options: options)).map { String($0.characters) } ?? text
    }

    // MARK: - Files

    static func write(_ text: String, name: String, fileExtension: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appending(path: fileName(name, fileExtension: fileExtension))
        try text.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    /// A file name from the recipe name, without characters file systems reject.
    static func fileName(_ name: String, fileExtension: String) -> String {
        let cleaned = name.components(separatedBy: CharacterSet(charactersIn: "/\\:?%*|\"<>")).joined(separator: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return (cleaned.isEmpty ? String(localized: "Recipe") : cleaned) + "." + fileExtension
    }
}
