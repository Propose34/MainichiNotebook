import Foundation
import Combine
import SwiftUI

@MainActor
final class SimpleVocabularyPacksViewModel: ObservableObject {
    let service: StudyDataService
    let userLibraryService: StudyUserLibraryService
    let userVocabularyService: UserVocabularyService
    let progressService: SimpleVocabularyProgressService
    
    private let repository: StudyDataRepository
    private var cancellables = Set<AnyCancellable>()
    
    @Published var packs: [SimpleVocabularyPack] = []
    
    init(
        service: StudyDataService,
        userLibraryService: StudyUserLibraryService,
        userVocabularyService: UserVocabularyService,
        progressService: SimpleVocabularyProgressService
    ) {
        self.service = service
        self.userLibraryService = userLibraryService
        self.userVocabularyService = userVocabularyService
        self.progressService = progressService
        self.repository = StudyDataRepository(service: service)
        
        // Define Curated Packs
        self.packs = [
            // Starter Packs
            SimpleVocabularyPack(
                id: "500-basic-words",
                title: "500 Basic Words",
                description: "Essential starter vocabulary for beginners",
                emoji: "🌱",
                levelBadge: "N5 Beginner",
                source: .deck("n5-vocabulary"),
                section: "Starter Packs"
            ),
            SimpleVocabularyPack(
                id: "word-builder",
                title: "Word Builder",
                description: "Learn compound Japanese nouns and patterns",
                emoji: "🧱",
                levelBadge: "N5 Beginner",
                source: .deck("word-builder"),
                section: "Starter Packs"
            ),
            SimpleVocabularyPack(
                id: "basic-kanji-vocab",
                title: "Basic Kanji Vocabulary",
                description: "Elementary vocabulary composed of kanji",
                emoji: "💮",
                levelBadge: "N5 Kanji",
                source: .deck("basic-kanji"),
                section: "Starter Packs"
            ),
            
            // Daily Japanese
            SimpleVocabularyPack(
                id: "daily-life",
                title: "Daily Life",
                description: "Objects, verbs, and phrases used in daily routines",
                emoji: "🏡",
                levelBadge: "N5 Beginner",
                source: .deck("daily-life"),
                section: "Daily Japanese"
            ),
            SimpleVocabularyPack(
                id: "greetings-conversation",
                title: "Greetings & Conversation",
                description: "Basic greetings and daily conversation builders",
                emoji: "💬",
                levelBadge: "N5 Beginner",
                source: .deck("daily-conversations"),
                section: "Daily Japanese"
            ),
            SimpleVocabularyPack(
                id: "food-shopping",
                title: "Food & Shopping",
                description: "Items in kitchen, dining out, and shopping centers",
                emoji: "🍣",
                levelBadge: "N5 Beginner",
                source: .category("food-drink"),
                section: "Daily Japanese"
            ),
            
            // Classroom Survival
            SimpleVocabularyPack(
                id: "classroom-words",
                title: "Classroom Words",
                description: "Essential school items, instructions, and nouns",
                emoji: "🎒",
                levelBadge: "N5 School",
                source: .deck("classroom-japanese"),
                section: "Classroom Survival"
            ),
            
            // JLPT N5 Basics
            SimpleVocabularyPack(
                id: "n5-verbs",
                title: "N5 Verbs",
                description: "Action words for basic sentence constructions",
                emoji: "🏃",
                levelBadge: "N5 Verbs",
                source: .deck("essential-verbs"),
                section: "JLPT N5 Basics"
            ),
            SimpleVocabularyPack(
                id: "n5-adjectives",
                title: "N5 Adjectives",
                description: "Cozy describers for places, foods, and feelings",
                emoji: "✨",
                levelBadge: "N5 Adjectives",
                source: .deck("n5-adjectives"),
                section: "JLPT N5 Basics"
            ),
            SimpleVocabularyPack(
                id: "travel-words",
                title: "Travel Words",
                description: "Phrases and words for navigation and transport",
                emoji: "✈️",
                levelBadge: "N5 Travel",
                source: .deck("travel-phrases"),
                section: "JLPT N5 Basics"
            ),
            
            // My Custom Words
            SimpleVocabularyPack(
                id: "my-custom-words",
                title: "My Words",
                description: "Words you created manually in study notebook",
                emoji: "📝",
                levelBadge: "User List",
                source: .customWords,
                section: "Review Ready"
            )
        ]
        
        // Observe dependencies to redraw UI when counts update
        Publishers.CombineLatest4(service.$vocabularyItems, userLibraryService.$state, userVocabularyService.$userItems, progressService.$progressList)
            .receive(on: RunLoop.main)
            .sink { [weak self] _, _, _, _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Helper getters
    
    func vocabularyItems(for pack: SimpleVocabularyPack) -> [VocabularyItem] {
        switch pack.source {
        case .deck(let deckId):
            return repository.vocabularyItems(inDeck: deckId)
        case .category(let catId):
            return repository.vocabularyItems(inCategory: catId)
        case .customWords:
            return userVocabularyService.userItems.map { $0.toVocabularyItem() }
        }
    }
    
    func wordCount(for pack: SimpleVocabularyPack) -> Int {
        return vocabularyItems(for: pack).count
    }
    
    func savedToFlashcardsCount(for pack: SimpleVocabularyPack) -> Int {
        let items = vocabularyItems(for: pack)
        let fcIds = userLibraryService.flashcardVocabularyIds()
        return items.filter { fcIds.contains($0.id) }.count
    }
    
    func favoriteCount(for pack: SimpleVocabularyPack) -> Int {
        let items = vocabularyItems(for: pack)
        let favIds = userLibraryService.favoriteVocabularyIds()
        return items.filter { favIds.contains($0.id) }.count
    }
    
    func progress(for pack: SimpleVocabularyPack) -> SimpleVocabularyPackProgress {
        return progressService.getProgress(for: pack.id)
    }
    
    // Overall Stats
    var totalWordsLearned: Int {
        let viewedSets = progressService.progressList.map { Set($0.viewedWordIds) }
        let allViewed = viewedSets.reduce(Set<String>()) { $0.union($1) }
        return allViewed.count
    }
    
    var totalSavedToFlashcards: Int {
        return userLibraryService.state.flashcardTargets.filter { $0.targetType == .vocabulary }.count
    }
    
    var totalFavorites: Int {
        return userLibraryService.state.favoriteTargets.filter { $0.targetType == .vocabulary }.count
    }
}
