import Foundation

struct StudyDataCounts: Codable, Hashable {
    var vocabularyCount: Int = 0
    var kanjiCount: Int = 0
    var grammarPatternCount: Int = 0
    var flashcardPromptCount: Int = 0
    var deckCount: Int = 0
    var categoryCount: Int = 0
    var virtualCategoryCount: Int = 0
}

struct StudyDataValidationResult: Codable, Hashable {
    let passed: Bool
    let errors: [String]
    let warnings: [String]
    let counts: StudyDataCounts
}

enum StudyDataValidation {
    static func validate(
        vocabularyItems: [VocabularyItem],
        kanjiItems: [KanjiItem],
        grammarPatterns: [GrammarPattern],
        flashcardPrompts: [FlashcardPrompt],
        decks: [StudyDeck],
        categories: [StudyCategory]
    ) -> StudyDataValidationResult {
        var errors: [String] = []
        var warnings: [String] = []
        
        // 1. Setup ID sets for fast lookup
        let vocabIds = Set(vocabularyItems.map { $0.id })
        let kanjiIds = Set(kanjiItems.map { $0.id })
        let grammarIds = Set(grammarPatterns.map { $0.id })
        let promptIds = Set(flashcardPrompts.map { $0.id })
        let categoryIds = Set(categories.map { $0.id })
        
        // 2. Uniqueness Checks
        if vocabIds.count < vocabularyItems.count {
            let duplicates = findDuplicates(vocabularyItems.map { $0.id })
            errors.append("Duplicate vocabulary IDs found: \(duplicates.joined(separator: ", "))")
        }
        if kanjiIds.count < kanjiItems.count {
            let duplicates = findDuplicates(kanjiItems.map { $0.id })
            errors.append("Duplicate kanji IDs found: \(duplicates.joined(separator: ", "))")
        }
        if grammarIds.count < grammarPatterns.count {
            let duplicates = findDuplicates(grammarPatterns.map { $0.id })
            errors.append("Duplicate grammar pattern IDs found: \(duplicates.joined(separator: ", "))")
        }
        if promptIds.count < flashcardPrompts.count {
            let duplicates = findDuplicates(flashcardPrompts.map { $0.id })
            errors.append("Duplicate flashcard prompt IDs found: \(duplicates.joined(separator: ", "))")
        }
        
        // 3. Deck Reference Checks
        for deck in decks {
            for vId in deck.vocabularyItemIds {
                if !vocabIds.contains(vId) {
                    errors.append("Deck '\(deck.id)' references missing vocabulary ID '\(vId)'")
                }
            }
            for kId in deck.kanjiIds {
                if !kanjiIds.contains(kId) {
                    errors.append("Deck '\(deck.id)' references missing kanji ID '\(kId)'")
                }
            }
            for gId in deck.grammarPatternIds {
                if !grammarIds.contains(gId) {
                    errors.append("Deck '\(deck.id)' references missing grammar pattern ID '\(gId)'")
                }
            }
            for pId in deck.flashcardPromptIds {
                if !promptIds.contains(pId) {
                    errors.append("Deck '\(deck.id)' references missing flashcard prompt ID '\(pId)'")
                }
            }
        }
        
        // 4. Category Reference Checks
        for category in categories {
            for vId in category.vocabularyItemIds {
                if !vocabIds.contains(vId) {
                    errors.append("Category '\(category.id)' references missing vocabulary ID '\(vId)'")
                }
            }
            for kId in category.kanjiIds {
                if !kanjiIds.contains(kId) {
                    errors.append("Category '\(category.id)' references missing kanji ID '\(kId)'")
                }
            }
            for gId in category.grammarPatternIds {
                if !grammarIds.contains(gId) {
                    errors.append("Category '\(category.id)' references missing grammar pattern ID '\(gId)'")
                }
            }
        }
        
        // 5. Flashcard Reference & Format Checks
        for prompt in flashcardPrompts {
            switch prompt.targetType {
            case .vocabulary:
                if !vocabIds.contains(prompt.targetId) {
                    errors.append("Flashcard prompt '\(prompt.id)' references missing vocabulary target ID '\(prompt.targetId)'")
                }
            case .kanji:
                if !kanjiIds.contains(prompt.targetId) {
                    errors.append("Flashcard prompt '\(prompt.id)' references missing kanji target ID '\(prompt.targetId)'")
                }
            case .grammar:
                if !grammarIds.contains(prompt.targetId) {
                    errors.append("Flashcard prompt '\(prompt.id)' references missing grammar target ID '\(prompt.targetId)'")
                }
            }
            
            if !prompt.choices.contains(prompt.correctAnswer) {
                errors.append("Flashcard prompt '\(prompt.id)' correctAnswer '\(prompt.correctAnswer)' is not one of the choices: \(prompt.choices)")
            }
        }
        
        // 6. Vocabulary Category Checks
        for vocab in vocabularyItems {
            if !categoryIds.contains(vocab.primaryCategory) {
                errors.append("Vocabulary item '\(vocab.id)' references missing primary category '\(vocab.primaryCategory)'")
            }
            for catId in vocab.categories {
                if !categoryIds.contains(catId) {
                    errors.append("Vocabulary item '\(vocab.id)' references missing category '\(catId)'")
                }
                if catId == "all-vocabulary" {
                    errors.append("Vocabulary item '\(vocab.id)' contains virtual category 'all-vocabulary' in its categories list.")
                }
            }
        }
        
        // 7. Virtual Category Validation
        if let allVocabCategory = categories.first(where: { $0.id == "all-vocabulary" }) {
            if !allVocabCategory.isVirtual {
                errors.append("Category 'all-vocabulary' is present but not marked as isVirtual = true")
            }
            // Check that it contains all vocabulary IDs
            let allVocabCatSet = Set(allVocabCategory.vocabularyItemIds)
            if allVocabCatSet != vocabIds {
                warnings.append("Virtual category 'all-vocabulary' contains \(allVocabCatSet.count) items, but there are \(vocabIds.count) vocabulary items in total.")
            }
        } else {
            warnings.append("Virtual category 'all-vocabulary' not found in categories.")
        }
        
        // 8. Daily Life Count Validation
        if let dailyLife = categories.first(where: { $0.id == "daily-life" }) {
            if dailyLife.vocabularyItemIds.count == vocabularyItems.count {
                errors.append("daily-life category vocabulary count is equal to all vocabulary count (\(vocabularyItems.count)). daily-life should be a real category, not all vocabulary.")
            } else if dailyLife.vocabularyItemIds.isEmpty {
                warnings.append("daily-life category has 0 vocabulary items. Expected around 131 items.")
            }
        }
        
        // Counts
        let realCategories = categories.filter { !$0.isVirtual }
        let virtualCategories = categories.filter { $0.isVirtual }
        let counts = StudyDataCounts(
            vocabularyCount: vocabularyItems.count,
            kanjiCount: kanjiItems.count,
            grammarPatternCount: grammarPatterns.count,
            flashcardPromptCount: flashcardPrompts.count,
            deckCount: decks.count,
            categoryCount: realCategories.count,
            virtualCategoryCount: virtualCategories.count
        )
        
        return StudyDataValidationResult(
            passed: errors.isEmpty,
            errors: errors,
            warnings: warnings,
            counts: counts
        )
    }
    
    private static func findDuplicates(_ ids: [String]) -> [String] {
        var seen = Set<String>()
        var duplicates = Set<String>()
        for id in ids {
            if seen.contains(id) {
                duplicates.insert(id)
            } else {
                seen.insert(id)
            }
        }
        return Array(duplicates)
    }
}
