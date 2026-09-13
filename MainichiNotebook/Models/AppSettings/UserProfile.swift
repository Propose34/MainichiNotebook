import Foundation

struct UserProfile: Codable, Identifiable, Hashable {
    var id: String
    var displayName: String
    var nickname: String?
    var studyGoal: String?
    var japaneseLevel: String?
    var avatarImageFileName: String? // nil, "avatar.jpg" for custom photo, or custom preset name
    var createdAt: Date
    var updatedAt: Date
}
