import Foundation

@MainActor
final class DailyActivityAggregator {
    private let srsService: SRSService
    private let userLibraryService: StudyUserLibraryService
    private let userVocabularyService: UserVocabularyService
    private let writingProgressService: WritingPracticeProgressService
    private let simpleVocabProgressService: SimpleVocabularyProgressService
    
    init(
        srsService: SRSService,
        userLibraryService: StudyUserLibraryService,
        userVocabularyService: UserVocabularyService,
        writingProgressService: WritingPracticeProgressService,
        simpleVocabProgressService: SimpleVocabularyProgressService
    ) {
        self.srsService = srsService
        self.userLibraryService = userLibraryService
        self.userVocabularyService = userVocabularyService
        self.writingProgressService = writingProgressService
        self.simpleVocabProgressService = simpleVocabProgressService
    }
    
    func buildSnapshot(for date: Date) -> DailyActivitySnapshot {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        // 1. Flashcards Reviewed & Rating counts
        let reviewsToday = srsService.historyRecords.filter {
            $0.reviewedAt >= startOfDay && $0.reviewedAt < endOfDay
        }
        
        let reviewedFlashcards = reviewsToday.count
        let againCount = reviewsToday.filter { $0.rating == .again }.count
        let hardCount = reviewsToday.filter { $0.rating == .hard }.count
        let goodCount = reviewsToday.filter { $0.rating == .good }.count
        let easyCount = reviewsToday.filter { $0.rating == .easy }.count
        
        // 2. Vocabulary collections added today
        let favoritesToday = userLibraryService.state.favoriteTargets.filter {
            $0.targetType == .vocabulary && $0.dateAdded >= startOfDay && $0.dateAdded < endOfDay
        }.count
        
        let myListToday = userLibraryService.state.myListTargets.filter {
            $0.targetType == .vocabulary && $0.dateAdded >= startOfDay && $0.dateAdded < endOfDay
        }.count
        
        let flashcardsToday = userLibraryService.state.flashcardTargets.filter {
            $0.targetType == .vocabulary && $0.dateAdded >= startOfDay && $0.dateAdded < endOfDay
        }.count
        
        // 3. Custom Vocab created today
        let customVocabToday = userVocabularyService.userItems.filter {
            $0.createdAt >= startOfDay && $0.createdAt < endOfDay
        }.count
        
        // 4. Writing Practice completed today
        let writingToday = writingProgressService.progressItems.values.filter { progress in
            if let date = progress.lastPracticedAt {
                return date >= startOfDay && date < endOfDay
            }
            return false
        }.count
        
        // 5. Simple Vocab packs studied/viewed today
        let simpleVocabToday = simpleVocabProgressService.progressList.filter { packProgress in
            if let studied = packProgress.lastStudiedAt, studied >= startOfDay, studied < endOfDay {
                return true
            }
            if let opened = packProgress.openedAt, opened >= startOfDay, opened < endOfDay {
                return true
            }
            return false
        }.count
        
        // 6. Remaining queues (live overall metrics)
        let queueSummary = srsService.queueSummary(now: Date())
        
        return DailyActivitySnapshot(
            date: date,
            reviewedFlashcards: reviewedFlashcards,
            againCount: againCount,
            hardCount: hardCount,
            goodCount: goodCount,
            easyCount: easyCount,
            vocabularyAddedToFavorites: favoritesToday,
            vocabularyAddedToMyList: myListToday,
            vocabularyAddedToFlashCards: flashcardsToday,
            customVocabularyCreated: customVocabToday,
            writingCharactersPracticed: writingToday,
            simpleVocabularyPacksStudied: simpleVocabToday,
            dueCardsRemaining: queueSummary.dueCount,
            newCardsRemaining: queueSummary.newCount
        )
    }
}
