import Foundation

enum SRSCardStatus: String, Codable, CaseIterable {
    case new
    case learning
    case review
    case relearning
    
    var label: String {
        switch self {
        case .new: return "New"
        case .learning: return "Learning"
        case .review: return "Review"
        case .relearning: return "Relearning"
        }
    }
}
