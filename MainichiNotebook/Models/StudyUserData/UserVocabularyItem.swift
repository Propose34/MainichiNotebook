import Foundation

struct UserVocabularyItem: Codable, Identifiable, Hashable {
    var id: String
    var japanese: String
    var reading: String
    var romaji: String
    var meaningTh: String
    var partOfSpeech: String
    var level: String?
    var primaryCategory: String
    var categories: [String]
    var tags: [String]
    var exampleJp: String?
    var exampleTh: String?
    var notes: String?
    var wordParts: [String]
    var builderPattern: String?
    var createdAt: Date
    var updatedAt: Date

    func toVocabularyItem() -> VocabularyItem {
        return VocabularyItem(
            id: id,
            japanese: japanese,
            reading: reading,
            romaji: romaji,
            meaningTh: meaningTh,
            partOfSpeech: partOfSpeech,
            level: level,
            studyLevel: level,
            primaryCategory: primaryCategory,
            categories: categories,
            decks: [],
            tags: tags,
            exampleJp: exampleJp,
            exampleTh: exampleTh,
            notes: notes,
            wordParts: wordParts,
            builderPattern: builderPattern,
            sourceFiles: [],
            status: "custom"
        )
    }
}
