import Foundation

struct KanjiItem: Codable, Identifiable, Hashable {
    let id: String
    let kanji: String
    let reading: String
    let romaji: String
    let meaningTh: String
    let level: String?
    let primaryCategory: String
    let categories: [String]
    let tags: [String]
    let exampleJp: String?
    let exampleTh: String?
    let wordParts: [String]
    let builderPattern: String?
    let sourceFiles: [String]
    let status: String

    enum CodingKeys: String, CodingKey {
        case id
        case kanji
        case reading
        case romaji
        case meaningTh = "meaning_th"
        case level
        case primaryCategory = "primary_category"
        case categories
        case tags
        case exampleJp = "example_jp"
        case exampleTh = "example_th"
        case wordParts = "word_parts"
        case builderPattern = "builder_pattern"
        case sourceFiles = "source_files"
        case status
    }
}
