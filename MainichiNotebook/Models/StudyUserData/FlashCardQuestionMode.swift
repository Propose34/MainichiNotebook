import Foundation

enum FlashCardQuestionMode: String, Codable, CaseIterable, Identifiable {
    case seedMultipleChoice = "Seed Prompts"
    case japaneseToThai = "Japanese to Thai"
    case thaiToJapanese = "Thai to Japanese"
    case readingToMeaning = "Reading to Meaning"
    case meaningToReading = "Meaning to Reading"
    case mixed = "Mixed Practice"
    
    var id: String { self.rawValue }
    
    var labelTh: String {
        switch self {
        case .seedMultipleChoice: return "โจทย์จากระบบ (Seed)"
        case .japaneseToThai: return "ภาษาญี่ปุ่น ➔ คำแปลไทย"
        case .thaiToJapanese: return "คำแปลไทย ➔ ภาษาญี่ปุ่น"
        case .readingToMeaning: return "คำอ่าน (Kana/Romaji) ➔ คำแปลไทย"
        case .meaningToReading: return "คำแปลไทย ➔ คำอ่าน"
        case .mixed: return "แบบสุ่มฝึกคละหมวด"
        }
    }
}
