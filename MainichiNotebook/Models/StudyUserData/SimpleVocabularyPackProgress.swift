import Foundation

struct SimpleVocabularyPackProgress: Codable, Identifiable, Hashable {
    var id: String
    var packId: String
    var openedAt: Date?
    var lastStudiedAt: Date?
    var viewedWordIds: [String]
    var completedWordIds: [String]
    var studyCount: Int
    var updatedAt: Date
}
