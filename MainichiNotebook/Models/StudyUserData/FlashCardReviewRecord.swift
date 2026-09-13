import Foundation

struct FlashCardReviewRecord: Codable, Identifiable, Hashable {
    var id: UUID
    var targetType: StudyDataTargetType
    var targetId: String
    var promptId: String?
    var rating: FlashCardReviewRating
    var wasCorrect: Bool?
    var reviewedAt: Date
    var questionMode: FlashCardQuestionMode?
}
