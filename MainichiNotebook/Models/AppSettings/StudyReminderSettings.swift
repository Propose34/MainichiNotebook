import Foundation

struct StudyReminderSettings: Codable, Hashable {
    var isEnabled: Bool
    var hour: Int
    var minute: Int
    var selectedWeekdays: [Int] // 1 = Sunday, 2 = Monday, etc.
    var reminderMessage: String
}
