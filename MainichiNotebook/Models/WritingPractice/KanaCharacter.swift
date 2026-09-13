import Foundation

struct KanaCharacter: Codable, Identifiable, Hashable {
    var id: String
    var character: String
    var romaji: String
    var row: String
    var type: KanaType
    
    enum KanaType: String, Codable {
        case hiragana
        case katakana
    }
}
