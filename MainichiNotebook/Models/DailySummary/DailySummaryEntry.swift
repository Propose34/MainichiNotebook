import Foundation

struct DailySummaryEntry: Codable, Identifiable, Hashable {
    var id: String // matches dateKey
    var dateKey: String // yyyy-MM-dd
    
    var mood: DailyMood?
    var manualStudyMinutes: Int
    var dailyNote: String
    
    var completedTaskIds: [String]
    
    var createdAt: Date
    var updatedAt: Date
}
