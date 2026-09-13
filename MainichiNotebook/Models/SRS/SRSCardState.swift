import Foundation

struct SRSCardState: Codable, Identifiable, Hashable {
    var id: String
    var targetType: StudyDataTargetType
    var targetId: String

    var status: SRSCardStatus
    var dueDate: Date?
    var lastReviewedAt: Date?
    var firstReviewedAt: Date?

    var intervalDays: Double
    var easeFactor: Double
    var reviewCount: Int
    var lapseCount: Int

    var createdAt: Date
    var updatedAt: Date
}
