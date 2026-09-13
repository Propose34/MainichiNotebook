import Foundation
import Combine
import SwiftUI

@MainActor
final class SimpleVocabularyPackDetailViewModel: ObservableObject {
    let pack: SimpleVocabularyPack
    let service: StudyDataService
    let userLibraryService: StudyUserLibraryService
    let userVocabularyService: UserVocabularyService
    let progressService: SimpleVocabularyProgressService
    
    private let repository: StudyDataRepository
    private var cancellables = Set<AnyCancellable>()
    
    @Published var searchText: String = ""
    @Published var selectedFilter: SimpleVocabularyFilter = .all
    @Published var selectedPOS: String? = nil
    
    @Published var selectedItemId: String? = nil
    
    init(
        pack: SimpleVocabularyPack,
        service: StudyDataService,
        userLibraryService: StudyUserLibraryService,
        userVocabularyService: UserVocabularyService,
        progressService: SimpleVocabularyProgressService
    ) {
        self.pack = pack
        self.service = service
        self.userLibraryService = userLibraryService
        self.userVocabularyService = userVocabularyService
        self.progressService = progressService
        self.repository = StudyDataRepository(service: service)
        
        // Track that the pack was opened
        progressService.trackOpened(packId: pack.id)
        
        // Observe user library state
        Publishers.CombineLatest(userLibraryService.$state, userVocabularyService.$userItems)
            .receive(on: RunLoop.main)
            .sink { [weak self] _, _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    enum SimpleVocabularyFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case favorites = "Favorites"
        case flashcards = "In Flash Cards"
        
        var id: String { self.rawValue }
    }
    
    // MARK: - Getters
    
    var allPackWords: [VocabularyItem] {
        switch pack.source {
        case .deck(let deckId):
            return repository.vocabularyItems(inDeck: deckId)
        case .category(let catId):
            return repository.vocabularyItems(inCategory: catId)
        case .customWords:
            return userVocabularyService.userItems.map { $0.toVocabularyItem() }
        }
    }
    
    var filteredWords: [VocabularyItem] {
        let base = allPackWords
        
        // 1. Filter by search query
        let searched: [VocabularyItem]
        if searchText.isEmpty {
            searched = base
        } else {
            let query = searchText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            searched = base.filter { item in
                item.japanese.lowercased().contains(query) ||
                item.reading.lowercased().contains(query) ||
                item.romaji.lowercased().contains(query) ||
                item.meaningTh.lowercased().contains(query)
            }
        }
        
        // 2. Filter by favorites / flashcards state
        let filtered: [VocabularyItem]
        switch selectedFilter {
        case .all:
            filtered = searched
        case .favorites:
            let favs = userLibraryService.favoriteVocabularyIds()
            filtered = searched.filter { favs.contains($0.id) }
        case .flashcards:
            let fcs = userLibraryService.flashcardVocabularyIds()
            filtered = searched.filter { fcs.contains($0.id) }
        }
        
        // 3. Filter by POS
        if let pos = selectedPOS {
            return filtered.filter { $0.partOfSpeech == pos }
        }
        
        return filtered
    }
    
    var availablePOS: [String] {
        let poses = allPackWords.map { $0.partOfSpeech }
        return Array(Set(poses)).sorted()
    }
    
    var selectedItem: VocabularyItem? {
        guard let id = selectedItemId else { return nil }
        return allPackWords.first(where: { $0.id == id })
    }
    
    // MARK: - Actions
    
    func trackWordViewed(wordId: String) {
        progressService.trackWordViewed(packId: pack.id, wordId: wordId)
    }
    
    func addPackToFlashCards() -> String {
        let words = allPackWords
        var addedCount = 0
        
        for word in words {
            if !userLibraryService.isInFlashcards(targetType: .vocabulary, targetId: word.id) {
                userLibraryService.toggleFlashcardCollection(targetType: .vocabulary, targetId: word.id)
                addedCount += 1
            }
        }
        
        if addedCount > 0 {
            return "Added \(addedCount) new words to Flash Cards"
        } else {
            return "All words already in Flash Cards"
        }
    }
    
    func addPackToMyList() -> String {
        let words = allPackWords
        var addedCount = 0
        
        for word in words {
            if !userLibraryService.isInMyList(targetType: .vocabulary, targetId: word.id) {
                userLibraryService.toggleMyList(targetType: .vocabulary, targetId: word.id)
                addedCount += 1
            }
        }
        
        if addedCount > 0 {
            return "Added \(addedCount) new words to My List"
        } else {
            return "All words already in My List"
        }
    }
    
    // MARK: - Build Review Cards for Quick Review
    
    func buildReviewCards(options: FlashCardReviewOptions) -> [ReviewCard] {
        let matchingVocabs = allPackWords
        guard !matchingVocabs.isEmpty else { return [] }
        
        let allSeedVocabs = repository.allVocabularyItems()
        let allUserVocabs = userVocabularyService.userItems.map { $0.toVocabularyItem() }
        let allVocabs = allSeedVocabs + allUserVocabs
        
        let distractorPool = matchingVocabs.count >= 10 ? matchingVocabs : allVocabs
        var generatedCards: [ReviewCard] = []
        
        for correctItem in matchingVocabs {
            if correctItem.status == "custom" {
                let card = ReviewCard(
                    id: "\(correctItem.id)_custom_reveal",
                    targetType: .vocabulary,
                    targetId: correctItem.id,
                    promptId: nil,
                    mode: .mixed,
                    promptText: correctItem.japanese,
                    promptSubtext: options.showReading ? correctItem.reading : nil,
                    choices: [],
                    correctChoiceId: "",
                    explanationTh: nil,
                    vocabularyItem: correctItem
                )
                generatedCards.append(card)
                continue
            }
            
            let cardMode = determineCardMode(for: correctItem, baseMode: options.questionMode)
            
            if cardMode == .seedMultipleChoice {
                let prompts = repository.allFlashcardPrompts().filter { $0.targetType == .vocabulary && $0.targetId == correctItem.id }
                if let prompt = prompts.first {
                    var choicesList: [ReviewChoice] = []
                    for choiceText in prompt.choices {
                        let isCorrect = (choiceText == prompt.correctAnswer)
                        var romajiSub: String? = nil
                        if options.showRomajiInChoices {
                            if let matchedItem = allVocabs.first(where: {
                                $0.japanese == choiceText || $0.meaningTh.lowercased() == choiceText.lowercased() || $0.reading == choiceText
                            }) {
                                romajiSub = matchedItem.romaji
                            }
                        }
                        
                        choicesList.append(ReviewChoice(
                            id: choiceText,
                            primaryText: choiceText,
                            secondaryText: romajiSub,
                            tertiaryText: nil,
                            isCorrect: isCorrect
                        ))
                    }
                    
                    let card = ReviewCard(
                        id: "\(correctItem.id)_seed_\(prompt.id)",
                        targetType: .vocabulary,
                        targetId: correctItem.id,
                        promptId: prompt.id,
                        mode: .seedMultipleChoice,
                        promptText: prompt.prompt,
                        promptSubtext: nil,
                        choices: choicesList,
                        correctChoiceId: prompt.correctAnswer,
                        explanationTh: prompt.explanationTh,
                        vocabularyItem: correctItem
                    )
                    generatedCards.append(card)
                } else {
                    let card = generateCustomCard(correctItem: correctItem, mode: .japaneseToThai, pool: distractorPool, options: options)
                    generatedCards.append(card)
                }
            } else {
                let card = generateCustomCard(correctItem: correctItem, mode: cardMode, pool: distractorPool, options: options)
                generatedCards.append(card)
            }
        }
        
        if options.shuffle {
            generatedCards.shuffle()
        }
        
        if options.cardLimit < generatedCards.count {
            generatedCards = Array(generatedCards.prefix(options.cardLimit))
        }
        
        return generatedCards
    }
    
    private func determineCardMode(for item: VocabularyItem, baseMode: FlashCardQuestionMode) -> FlashCardQuestionMode {
        if baseMode != .mixed {
            return baseMode
        }
        var candidates: [FlashCardQuestionMode] = [.japaneseToThai, .thaiToJapanese, .readingToMeaning, .meaningToReading]
        let prompts = repository.allFlashcardPrompts().filter { $0.targetType == .vocabulary && $0.targetId == item.id }
        if !prompts.isEmpty {
            candidates.append(.seedMultipleChoice)
        }
        return candidates.randomElement() ?? .japaneseToThai
    }
    
    private func generateCustomCard(correctItem: VocabularyItem, mode: FlashCardQuestionMode, pool: [VocabularyItem], options: FlashCardReviewOptions) -> ReviewCard {
        let cardId = "\(correctItem.id)_\(mode.rawValue)"
        
        let getCandidatesText: (VocabularyItem) -> String = { item in
            switch mode {
            case .japaneseToThai, .readingToMeaning: return item.meaningTh
            case .thaiToJapanese: return item.japanese
            case .meaningToReading: return item.reading
            default: return item.japanese
            }
        }
        
        let distractorItems = getDistractors(correctItem: correctItem, candidates: pool, textSelector: getCandidatesText, count: 3)
        
        if distractorItems.count < 3 {
            return ReviewCard(
                id: cardId,
                targetType: .vocabulary,
                targetId: correctItem.id,
                promptId: nil,
                mode: mode,
                promptText: mode == .japaneseToThai ? correctItem.japanese : correctItem.meaningTh,
                promptSubtext: (mode == .japaneseToThai && options.showReading) ? correctItem.reading : nil,
                choices: [],
                correctChoiceId: "",
                explanationTh: nil,
                vocabularyItem: correctItem
            )
        }
        
        var choicesList: [ReviewChoice] = []
        let correctText = getCandidatesText(correctItem)
        choicesList.append(ReviewChoice(id: correctText, primaryText: correctText, secondaryText: nil, tertiaryText: nil, isCorrect: true))
        
        for item in distractorItems {
            let txt = getCandidatesText(item)
            choicesList.append(ReviewChoice(id: txt, primaryText: txt, secondaryText: nil, tertiaryText: nil, isCorrect: false))
        }
        
        choicesList.shuffle()
        
        let promptText: String
        let promptSub: String?
        switch mode {
        case .japaneseToThai:
            promptText = correctItem.japanese
            promptSub = options.showReading ? correctItem.reading : nil
        case .thaiToJapanese:
            promptText = correctItem.meaningTh
            promptSub = nil
        case .readingToMeaning:
            promptText = correctItem.reading
            promptSub = options.showRomaji ? correctItem.romaji : nil
        case .meaningToReading:
            promptText = correctItem.meaningTh
            promptSub = nil
        default:
            promptText = correctItem.japanese
            promptSub = nil
        }
        
        return ReviewCard(
            id: cardId,
            targetType: .vocabulary,
            targetId: correctItem.id,
            promptId: nil,
            mode: mode,
            promptText: promptText,
            promptSubtext: promptSub,
            choices: choicesList,
            correctChoiceId: correctText,
            explanationTh: nil,
            vocabularyItem: correctItem
        )
    }
    
    private func getDistractors(correctItem: VocabularyItem, candidates: [VocabularyItem], textSelector: (VocabularyItem) -> String, count: Int) -> [VocabularyItem] {
        let correctText = textSelector(correctItem).trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        let filteredCandidates = candidates.filter { item in
            item.id != correctItem.id &&
            !textSelector(item).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            textSelector(item).trimmingCharacters(in: .whitespacesAndNewlines).lowercased() != correctText
        }
        
        let shuffled = filteredCandidates.shuffled()
        var selectedDistractors: [VocabularyItem] = []
        var selectedTexts = Set<String>([correctText])
        
        let matchingPriority = shuffled.filter { item in
            item.primaryCategory == correctItem.primaryCategory || item.level == correctItem.level
        }
        
        for item in matchingPriority {
            let txt = textSelector(item).trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if !selectedTexts.contains(txt) {
                selectedDistractors.append(item)
                selectedTexts.insert(txt)
                if selectedDistractors.count == count {
                    return selectedDistractors
                }
            }
        }
        
        for item in shuffled {
            let txt = textSelector(item).trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if !selectedTexts.contains(txt) {
                if !selectedDistractors.contains(where: { $0.id == item.id }) {
                    selectedDistractors.append(item)
                    selectedTexts.insert(txt)
                    if selectedDistractors.count == count {
                        return selectedDistractors
                    }
                }
            }
        }
        
        return selectedDistractors
    }
}
