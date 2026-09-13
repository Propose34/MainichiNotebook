import Foundation

struct SavedStudyTarget: Codable, Hashable, Identifiable {
    var id: String {
        return targetType.rawValue + "_" + targetId
    }
    let targetType: StudyDataTargetType
    let targetId: String
    let dateAdded: Date
}
