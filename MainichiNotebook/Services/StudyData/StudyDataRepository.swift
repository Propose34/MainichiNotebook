import Foundation

@MainActor
final class StudyDataRepository {
    private let service: StudyDataService

    init(service: StudyDataService) {
        self.service = service
    }

    // MARK: - List Helpers
    
    func allVocabularyItems() -> [VocabularyItem] {
        return service.vocabularyItems
    }

    func allKanjiItems() -> [KanjiItem] {
        return service.kanjiItems
    }

    func allGrammarPatterns() -> [GrammarPattern] {
        return service.grammarPatterns
    }

    func allFlashcardPrompts() -> [FlashcardPrompt] {
        return service.flashcardPrompts
    }

    func allDecks() -> [StudyDeck] {
        return service.decks
    }

    func allCategories(includeVirtual: Bool = true) -> [StudyCategory] {
        if includeVirtual {
            return service.categories
        } else {
            return service.categories.filter { !$0.isVirtual }
        }
    }

    // MARK: - Lookups
    
    func vocabularyItem(id: String) -> VocabularyItem? {
        return service.vocabularyItems.first(where: { $0.id == id })
    }

    func kanjiItem(id: String) -> KanjiItem? {
        return service.kanjiItems.first(where: { $0.id == id })
    }

    func grammarPattern(id: String) -> GrammarPattern? {
        return service.grammarPatterns.first(where: { $0.id == id })
    }

    func flashcardPrompt(id: String) -> FlashcardPrompt? {
        return service.flashcardPrompts.first(where: { $0.id == id })
    }

    func deck(id: String) -> StudyDeck? {
        return service.decks.first(where: { $0.id == id })
    }

    func category(id: String) -> StudyCategory? {
        return service.categories.first(where: { $0.id == id })
    }

    // MARK: - Filtering
    
    func vocabularyItems(inCategory categoryId: String) -> [VocabularyItem] {
        if categoryId == "all-vocabulary" {
            return service.vocabularyItems
        }
        
        // Find category
        guard let category = category(id: categoryId) else { return [] }
        let categoryVocabIds = Set(category.vocabularyItemIds)
        
        // Return vocabulary items whose ID is in the category's vocabularyItemIds list
        // OR who explicitly reference this category ID in their categories array
        return service.vocabularyItems.filter { item in
            categoryVocabIds.contains(item.id) || item.categories.contains(categoryId) || item.primaryCategory == categoryId
        }
    }

    func vocabularyItems(inDeck deckId: String) -> [VocabularyItem] {
        guard let deckObj = deck(id: deckId) else { return [] }
        let deckVocabIds = Set(deckObj.vocabularyItemIds)
        return service.vocabularyItems.filter { item in
            deckVocabIds.contains(item.id) || item.decks.contains(deckId)
        }
    }

    func kanjiItems(inCategory categoryId: String) -> [KanjiItem] {
        guard let category = category(id: categoryId) else { return [] }
        let categoryKanjiIds = Set(category.kanjiIds)
        return service.kanjiItems.filter { item in
            categoryKanjiIds.contains(item.id) || item.categories.contains(categoryId) || item.primaryCategory == categoryId
        }
    }

    func grammarPatterns(inCategory categoryId: String) -> [GrammarPattern] {
        guard let category = category(id: categoryId) else { return [] }
        let categoryGrammarIds = Set(category.grammarPatternIds)
        return service.grammarPatterns.filter { item in
            categoryGrammarIds.contains(item.id) || item.categories.contains(categoryId) || item.primaryCategory == categoryId
        }
    }

    func flashcards(forTargetType targetType: StudyDataTargetType, targetId: String) -> [FlashcardPrompt] {
        return service.flashcardPrompts.filter { prompt in
            prompt.targetType == targetType && prompt.targetId == targetId
        }
    }

    func flashcards(inDeck deckId: String) -> [FlashcardPrompt] {
        guard let deckObj = deck(id: deckId) else { return [] }
        let deckPromptIds = Set(deckObj.flashcardPromptIds)
        return service.flashcardPrompts.filter { prompt in
            deckPromptIds.contains(prompt.id)
        }
    }

    // MARK: - Search
    
    func searchVocabulary(_ query: String) -> [VocabularyItem] {
        let lowerQuery = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if lowerQuery.isEmpty { return [] }

        // Precompute matching deck IDs
        let matchingDeckIds = Set(service.decks.filter { $0.name.lowercased().contains(lowerQuery) }.map { $0.id })

        return service.vocabularyItems.filter { item in
            item.japanese.lowercased().contains(lowerQuery) ||
            item.reading.lowercased().contains(lowerQuery) ||
            item.romaji.lowercased().contains(lowerQuery) ||
            item.meaningTh.lowercased().contains(lowerQuery) ||
            item.tags.contains(where: { $0.lowercased().contains(lowerQuery) }) ||
            item.decks.contains(where: { matchingDeckIds.contains($0) })
        }
    }
}
