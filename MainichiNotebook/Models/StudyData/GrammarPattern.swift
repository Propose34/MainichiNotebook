import Foundation

struct GrammarPattern: Codable, Identifiable, Hashable {
    let id: String
    let pattern: String
    let meaningTh: String
    let level: String?
    let primaryCategory: String
    let categories: [String]
    let deck: String
    let tags: [String]
    let exampleJp: String?
    let exampleTh: String?
    let structure: String?
    let builderPattern: String?
    let sourceFiles: [String]
    let status: String

    enum CodingKeys: String, CodingKey {
        case id
        case pattern
        case meaningTh = "meaning_th"
        case level
        case primaryCategory = "primary_category"
        case categories
        case deck
        case tags
        case exampleJp = "example_jp"
        case exampleTh = "example_th"
        case structure
        case builderPattern = "builder_pattern"
        case sourceFiles = "source_files"
        case status
    }
}
