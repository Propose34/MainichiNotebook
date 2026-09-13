import Foundation

enum SimpleVocabularyPackSource: Hashable, Codable {
    case deck(String)      // References a StudyDeck ID
    case category(String)  // References a StudyCategory ID
    case customWords       // References user-created custom words
    
    private enum CodingKeys: String, CodingKey {
        case type
        case id
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "deck":
            let id = try container.decode(String.self, forKey: .id)
            self = .deck(id)
        case "category":
            let id = try container.decode(String.self, forKey: .id)
            self = .category(id)
        case "customWords":
            self = .customWords
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown source type")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .deck(let id):
            try container.encode("deck", forKey: .type)
            try container.encode(id, forKey: .id)
        case .category(let id):
            try container.encode("category", forKey: .type)
            try container.encode(id, forKey: .id)
        case .customWords:
            try container.encode("customWords", forKey: .type)
        }
    }
}

struct SimpleVocabularyPack: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let description: String
    let emoji: String
    let levelBadge: String
    let source: SimpleVocabularyPackSource
    let section: String // e.g. "Starter Packs", "Daily Japanese", "Classroom Survival", "JLPT N5 Basics", "Review Ready"
}
