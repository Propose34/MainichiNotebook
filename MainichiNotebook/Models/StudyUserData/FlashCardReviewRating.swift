import Foundation

enum FlashCardReviewRating: String, Codable, CaseIterable, Identifiable {
    case again = "Again"
    case hard = "Hard"
    case good = "Good"
    case easy = "Easy"
    
    var id: String { self.rawValue }
    
    var labelTh: String {
        switch self {
        case .again: return "อีกครั้ง"
        case .hard: return "ยาก"
        case .good: return "พอดี"
        case .easy: return "ง่าย"
        }
    }
}
