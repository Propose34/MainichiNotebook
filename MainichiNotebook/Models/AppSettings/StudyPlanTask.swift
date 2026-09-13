import Foundation

struct StudyPlanTask: Codable, Identifiable, Hashable {
    var id: String
    var title: String
    var timeString: String // e.g. "15 min", "30 min", "17:00"
    var isCompleted: Bool
    var dateKey: String // yyyy-MM-dd
}
