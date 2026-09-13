import Foundation

enum WritingPracticeMode: String, Codable, CaseIterable, Identifiable {
    case hiragana = "Hiragana"
    case katakana = "Katakana"
    case kanji = "Kanji"
    
    var id: String { self.rawValue }
    
    var labelTh: String {
        switch self {
        case .hiragana: return "ฮิรางานะ"
        case .katakana: return "คาตาคานะ"
        case .kanji: return "คันจิ"
        }
    }
}

struct WritingPracticeCharacter: Codable, Identifiable, Hashable {
    var id: String
    var character: String
    var reading: String
    var meaning: String?
    var mode: WritingPracticeMode
    var group: String // "A-Row", "Ka-Row", "N5" etc.
    var exampleJp: String?
    var exampleTh: String?
    var notes: String?
}
