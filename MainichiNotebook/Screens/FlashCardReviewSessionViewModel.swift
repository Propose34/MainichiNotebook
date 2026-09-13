import Foundation

@MainActor
final class FlashCardReviewSessionViewModel: ObservableObject, Identifiable {
    nonisolated public let id = UUID()
    let source: ReviewSource
    let cards: [ReviewCard]
    let options: FlashCardReviewOptions
    private let srsService: SRSService
    
    @Published var currentIndex: Int = 0
    @Published var isAnswerRevealed: Bool = false
    @Published var selectedChoice: String? = nil
    @Published var isCorrect: Bool? = nil
    
    @Published var correctCount: Int = 0
    @Published var incorrectCount: Int = 0
    @Published var isFinished: Bool = false
    
    @Published var reviewedCards: [ReviewCard] = []
    @Published var sessionRecords: [SRSReviewRecord] = []
    
    init(source: ReviewSource, cards: [ReviewCard], options: FlashCardReviewOptions, srsService: SRSService) {
        self.source = source
        self.cards = cards
        self.options = options
        self.srsService = srsService
    }
    
    var currentCard: ReviewCard? {
        guard currentIndex >= 0 && currentIndex < cards.count else { return nil }
        return cards[currentIndex]
    }
    
    var progress: Double {
        guard !cards.isEmpty else { return 0 }
        return Double(currentIndex) / Double(cards.count)
    }
    
    func revealAnswer() {
        isAnswerRevealed = true
    }
    
    func selectChoice(_ choiceId: String) {
        guard let card = currentCard else { return }
        guard selectedChoice == nil else { return } // block multiple selections
        
        selectedChoice = choiceId
        let correct = (choiceId == card.correctChoiceId)
        isCorrect = correct
        isAnswerRevealed = true
        
        if correct {
            correctCount += 1
        } else {
            incorrectCount += 1
        }
    }
    
    func rateCard(_ rating: SRSRating) {
        guard let card = currentCard else { return }
        
        let record = srsService.review(
            targetType: card.targetType,
            targetId: card.targetId,
            promptId: card.promptId,
            rating: rating,
            wasCorrect: isCorrect,
            questionMode: card.mode
        )
        
        sessionRecords.append(record)
        reviewedCards.append(card)
        advanceCursor()
    }
    
    func nextCardWithoutRating() {
        guard let card = currentCard else { return }
        
        let defaultRating: SRSRating = (isCorrect == false) ? .again : .good
        
        let record = srsService.review(
            targetType: card.targetType,
            targetId: card.targetId,
            promptId: card.promptId,
            rating: defaultRating,
            wasCorrect: isCorrect,
            questionMode: card.mode
        )
        
        sessionRecords.append(record)
        reviewedCards.append(card)
        advanceCursor()
    }
    
    private func advanceCursor() {
        if currentIndex + 1 < cards.count {
            currentIndex += 1
            // Reset card variables
            isAnswerRevealed = false
            selectedChoice = nil
            isCorrect = nil
        } else {
            finishSession()
        }
    }
    
    private func finishSession() {
        let gradedCount = correctCount + incorrectCount
        let correctRate = gradedCount > 0 ? Double(correctCount) / Double(gradedCount) : 1.0
        
        srsService.logSessionFinished(correctRate: correctRate)
        isFinished = true
    }
}

