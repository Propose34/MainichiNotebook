import Foundation

struct DailyActivitySnapshot {
    var date: Date
    var reviewedFlashcards: Int
    var againCount: Int
    var hardCount: Int
    var goodCount: Int
    var easyCount: Int
    
    var vocabularyAddedToFavorites: Int
    var vocabularyAddedToMyList: Int
    var vocabularyAddedToFlashCards: Int
    var customVocabularyCreated: Int
    
    var writingCharactersPracticed: Int
    var simpleVocabularyPacksStudied: Int
    
    var dueCardsRemaining: Int
    var newCardsRemaining: Int
}
