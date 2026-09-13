import Foundation

struct ReviewCard: Identifiable, Hashable {
    var id: String
    var targetType: StudyDataTargetType
    var targetId: String
    var promptId: String?
    var mode: FlashCardQuestionMode
    var promptText: String
    var promptSubtext: String?
    var choices: [ReviewChoice]
    var correctChoiceId: String
    var explanationTh: String?
    var vocabularyItem: VocabularyItem
    
    var isMultipleChoice: Bool {
        !choices.isEmpty
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ReviewCard, rhs: ReviewCard) -> Bool {
        lhs.id == rhs.id
    }
}
