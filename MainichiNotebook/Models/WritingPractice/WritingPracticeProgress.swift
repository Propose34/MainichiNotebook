import Foundation

struct WritingPracticeProgress: Codable, Identifiable, Hashable {
    var id: String // Same as characterId
    var characterId: String
    var mode: WritingPracticeMode
    var practiceCount: Int
    var lastPracticedAt: Date?
    var createdAt: Date
    var updatedAt: Date
}
