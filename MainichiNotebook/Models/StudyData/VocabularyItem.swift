import Foundation

struct VocabularyItem: Codable, Identifiable, Hashable {
    let id: String
    let japanese: String
    let reading: String
    let romaji: String
    let meaningTh: String
    let partOfSpeech: String
    let level: String?
    let studyLevel: String?
    let primaryCategory: String
    let categories: [String]
    let decks: [String]
    let tags: [String]
    let exampleJp: String?
    let exampleTh: String?
    let notes: String?
    let wordParts: [String]
    let builderPattern: String?
    let sourceFiles: [String]
    let status: String

    enum CodingKeys: String, CodingKey {
        case id
        case japanese
        case reading
        case romaji
        case meaningTh = "meaning_th"
        case partOfSpeech = "part_of_speech"
        case level
        case studyLevel = "study_level"
        case primaryCategory = "primary_category"
        case categories
        case decks
        case tags
        case exampleJp = "example_jp"
        case exampleTh = "example_th"
        case notes
        case wordParts = "word_parts"
        case builderPattern = "builder_pattern"
        case sourceFiles = "source_files"
        case status
    }
}
