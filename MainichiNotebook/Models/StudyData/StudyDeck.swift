import Foundation

struct StudyDeck: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let type: String
    let descriptionTh: String?
    let level: String?
    let tags: [String]
    let vocabularyItemIds: [String]
    let kanjiIds: [String]
    let grammarPatternIds: [String]
    let flashcardPromptIds: [String]

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case type
        case descriptionTh = "description_th"
        case level
        case tags
        case vocabularyItemIds = "vocabulary_item_ids"
        case kanjiIds = "kanji_ids"
        case grammarPatternIds = "grammar_pattern_ids"
        case flashcardPromptIds = "flashcard_prompt_ids"
    }
}
