import Foundation

struct StudyUserLibraryState: Codable {
    var favoriteTargets: [SavedStudyTarget]
    var myListTargets: [SavedStudyTarget]
    var flashcardTargets: [SavedStudyTarget]
    var lastUpdated: Date
}
