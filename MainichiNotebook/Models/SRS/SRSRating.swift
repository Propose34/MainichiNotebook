import Foundation

enum SRSRating: String, Codable, CaseIterable, Identifiable {
    case again
    case hard
    case good
    case easy
    
    var id: String { self.rawValue }
    
    var labelTh: String {
        switch self {
        case .again: return "อีกครั้ง"
        case .hard: return "ยาก"
        case .good: return "พอดี"
        case .easy: return "ง่าย"
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let val = try container.decode(String.self).lowercased()
        switch val {
        case "again": self = .again
        case "hard": self = .hard
        case "good": self = .good
        case "easy": self = .easy
        default:
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid rating value: \(val)")
        }
    }
}
