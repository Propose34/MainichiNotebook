import Foundation

struct SRSReviewRecord: Codable, Identifiable, Hashable {
    var id: UUID
    var targetType: StudyDataTargetType
    var targetId: String
    var promptId: String?

    var rating: SRSRating
    var wasCorrect: Bool?
    var reviewedAt: Date

    var previousDueDate: Date?
    var nextDueDate: Date?
    var previousIntervalDays: Double?
    var nextIntervalDays: Double?
    var previousEaseFactor: Double?
    var nextEaseFactor: Double?
    
    var questionMode: FlashCardQuestionMode?
}
