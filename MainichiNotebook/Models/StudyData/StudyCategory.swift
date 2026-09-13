import Foundation

struct StudyCategory: Codable, Identifiable, Hashable {
    let id: String
    let nameEn: String
    let nameTh: String
    let descriptionTh: String?
    let icon: String?
    let color: String?
    let isVirtual: Bool
    let vocabularyItemIds: [String]
    let kanjiIds: [String]
    let grammarPatternIds: [String]
    let totalCount: Int

    enum CodingKeys: String, CodingKey {
        case id
        case nameEn = "name_en"
        case nameTh = "name_th"
        case descriptionTh = "description_th"
        case icon
        case color
        case isVirtual = "is_virtual"
        case vocabularyItemIds = "vocabulary_item_ids"
        case kanjiIds = "kanji_ids"
        case grammarPatternIds = "grammar_pattern_ids"
        case totalCount = "total_count"
    }
}
