import Foundation

struct ReviewChoice: Identifiable, Hashable {
    var id: String
    var primaryText: String
    var secondaryText: String?
    var tertiaryText: String?
    var isCorrect: Bool
}
