import Foundation

struct DailyTaskItem: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let titleTh: String
    let description: String
}
