import Foundation

struct SRSQueueSummary: Codable, Hashable {
    var dueCount: Int
    var newCount: Int
    var learningCount: Int
    var reviewCount: Int
    var totalActiveCount: Int
    var reviewedTodayCount: Int
}
