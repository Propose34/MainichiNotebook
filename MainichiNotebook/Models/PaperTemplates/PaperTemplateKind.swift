import Foundation

enum PaperTemplateKind: String, Codable, CaseIterable {
    case builtIn = "Built-in"
    case importedImage = "Imported Image"
    case importedPDF = "Imported PDF"
}
