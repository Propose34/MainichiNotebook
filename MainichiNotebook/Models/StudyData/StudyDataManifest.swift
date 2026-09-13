import Foundation

struct StudyDataManifest: Codable {
    let datasetName: String
    let version: String
    let language: String
    let files: ManifestFiles
    let schemaNotes: [String]

    enum CodingKeys: String, CodingKey {
        case datasetName = "dataset_name"
        case version
        case language
        case files
        case schemaNotes = "schema_notes"
    }
}

struct ManifestFiles: Codable {
    let vocabulary: String
    let kanji: String
    let grammarPatterns: String
    let flashcardPrompts: String
    let decks: String
    let categories: String

    enum CodingKeys: String, CodingKey {
        case vocabulary
        case kanji
        case grammarPatterns = "grammar_patterns"
        case flashcardPrompts = "flashcard_prompts"
        case decks
        case categories
    }
}
