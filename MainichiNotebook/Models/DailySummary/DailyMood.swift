import Foundation

enum DailyMood: String, Codable, CaseIterable, Identifiable {
    case happy = "happy"
    case focused = "focused"
    case tired = "tired"
    case confused = "confused"
    case proud = "proud"
    case neutral = "neutral"
    
    var id: String { self.rawValue }
    
    var emoji: String {
        switch self {
        case .happy: return "😊"
        case .focused: return "😇"
        case .tired: return "😴"
        case .confused: return "😔"
        case .proud: return "😎"
        case .neutral: return "😐"
        }
    }
    
    var labelEn: String {
        switch self {
        case .happy: return "Happy"
        case .focused: return "Focused"
        case .tired: return "Tired"
        case .confused: return "Confused"
        case .proud: return "Proud"
        case .neutral: return "Neutral"
        }
    }
    
    var labelTh: String {
        switch self {
        case .happy: return "มีความสุข"
        case .focused: return "มีสมาธิ"
        case .tired: return "เหนื่อยล้า"
        case .confused: return "สับสน/กังวล"
        case .proud: return "ภูมิใจ"
        case .neutral: return "เฉยๆ"
        }
    }
}
