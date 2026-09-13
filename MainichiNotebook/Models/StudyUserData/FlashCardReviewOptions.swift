import Foundation

struct FlashCardReviewOptions: Codable, Equatable {
    var source: ReviewSource
    var questionMode: FlashCardQuestionMode
    var showReading: Bool
    var showRomaji: Bool
    var showRomajiInChoices: Bool
    var showExampleAfterAnswer: Bool
    var enablePronunciation: Bool
    var cardLimit: Int // e.g. 5, 10, 20, 9999 (all)
    var shuffle: Bool
    
    static var `default`: FlashCardReviewOptions {
        FlashCardReviewOptions(
            source: .myFlashCards,
            questionMode: .seedMultipleChoice,
            showReading: true,
            showRomaji: true,
            showRomajiInChoices: true,
            showExampleAfterAnswer: true,
            enablePronunciation: true,
            cardLimit: 10,
            shuffle: true
        )
    }
}
