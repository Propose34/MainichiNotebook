import Foundation
import SwiftUI

enum ReviewSource: String, Codable, CaseIterable, Identifiable {
    case myFlashCards = "My Flash Cards"
    case favorites = "Favorites"
    case myList = "My List"
    case allN5 = "All N5 Vocabulary"
    
    var id: String { self.rawValue }
    
    var description: String {
        switch self {
        case .myFlashCards:
            return "Words you added to Flash Cards from the library"
        case .favorites:
            return "Words you starred as Favorites in the library"
        case .myList:
            return "Words in your custom learning list"
        case .allN5:
            return "Complete vocabulary items in N5 level"
        }
    }
    
    var iconName: String {
        switch self {
        case .myFlashCards: return "square.on.square.fill"
        case .favorites: return "star.fill"
        case .myList: return "list.bullet.rectangle.portrait.fill"
        case .allN5: return "character.book.closed.fill"
        }
    }
    
    var themeColor: Color {
        switch self {
        case .myFlashCards: return AppTheme.sakuraPink
        case .favorites: return AppTheme.woodCozy
        case .myList: return AppTheme.sageGreen
        case .allN5: return AppTheme.darkNavy
        }
    }
}

enum SRSSessionType: String, Codable, CaseIterable {
    case due = "Due Today"
    case new = "New Words"
    case all = "Review All Saved"
}

@MainActor
final class FlashCardsViewModel: ObservableObject {
    @Published var reviewOptions: FlashCardReviewOptions = .default {
        didSet {
            saveOptions()
        }
    }
    
    var selectedSource: ReviewSource {
        get { reviewOptions.source }
        set { reviewOptions.source = newValue }
    }
    
    private let userDefaultsKey = "MainichiFlashCardReviewOptions"
    
    init() {
        self.reviewOptions = loadOptions()
    }
    
    private func loadOptions() -> FlashCardReviewOptions {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let options = try? JSONDecoder().decode(FlashCardReviewOptions.self, from: data) {
            return options
        }
        return .default
    }
    
    private func saveOptions() {
        if let data = try? JSONEncoder().encode(reviewOptions) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
            print("[FlashCardsViewModel] Options saved via UserDefaults.")
        }
    }
    
    func cardCount(for source: ReviewSource, userLibrary: StudyUserLibraryService, repository: StudyDataRepository, userVocabularyService: UserVocabularyService) -> Int {
        return getVocabularyIds(for: source, userLibrary: userLibrary, repository: repository, userVocabularyService: userVocabularyService).count
    }
    
    func srsCardCount(for source: ReviewSource, sessionType: SRSSessionType, userLibrary: StudyUserLibraryService, repository: StudyDataRepository, userVocabularyService: UserVocabularyService, srsService: SRSService) -> Int {
        let baseVocabIds = getVocabularyIds(for: source, userLibrary: userLibrary, repository: repository, userVocabularyService: userVocabularyService)
        let now = Date()
        return baseVocabIds.filter { id in
            let st = srsService.ensureState(for: .vocabulary, targetId: id)
            switch sessionType {
            case .due:
                return st.status != .new && (st.dueDate.map { $0 <= now } ?? false)
            case .new:
                return st.status == .new
            case .all:
                return true
            }
        }.count
    }
    
    func promptCount(for source: ReviewSource, userLibrary: StudyUserLibraryService, repository: StudyDataRepository, userVocabularyService: UserVocabularyService) -> Int {
        let vocabIds = getVocabularyIds(for: source, userLibrary: userLibrary, repository: repository, userVocabularyService: userVocabularyService)
        let prompts = repository.allFlashcardPrompts()
        return prompts.filter { $0.targetType == .vocabulary && vocabIds.contains($0.targetId) }.count
    }
    
    private func getVocabularyIds(for source: ReviewSource, userLibrary: StudyUserLibraryService, repository: StudyDataRepository, userVocabularyService: UserVocabularyService) -> Set<String> {
        switch source {
        case .myFlashCards:
            return userLibrary.flashcardVocabularyIds()
        case .favorites:
            return userLibrary.favoriteVocabularyIds()
        case .myList:
            return userLibrary.myListVocabularyIds()
        case .allN5:
            let n5Items = repository.allVocabularyItems().filter { item in
                let level = item.level ?? ""
                let studyLevel = item.studyLevel ?? ""
                return level.lowercased().contains("5") || studyLevel.lowercased().contains("5")
            }
            let userN5Items = userVocabularyService.userItems.map { $0.toVocabularyItem() }.filter { item in
                let level = item.level ?? ""
                return level.lowercased().contains("5")
            }
            return Set(n5Items.map { $0.id } + userN5Items.map { $0.id })
        }
    }
    
    func startSession(
        source: ReviewSource,
        sessionType: SRSSessionType = .all,
        userLibrary: StudyUserLibraryService,
        repository: StudyDataRepository,
        userVocabularyService: UserVocabularyService,
        srsService: SRSService
    ) -> [ReviewCard] {
        let baseVocabIds = getVocabularyIds(for: source, userLibrary: userLibrary, repository: repository, userVocabularyService: userVocabularyService)
        let now = Date()
        
        let vocabIds = baseVocabIds.filter { id in
            let st = srsService.ensureState(for: .vocabulary, targetId: id)
            switch sessionType {
            case .due:
                return st.status != .new && (st.dueDate.map { $0 <= now } ?? false)
            case .new:
                return st.status == .new
            case .all:
                return true
            }
        }
        
        let allSeedVocabs = repository.allVocabularyItems()
        let allUserVocabs = userVocabularyService.userItems.map { $0.toVocabularyItem() }
        let allVocabs = allSeedVocabs + allUserVocabs
        
        // Resolve card candidates
        var matchingVocabs: [VocabularyItem] = []
        for vocabId in vocabIds {
            if vocabId.hasPrefix("user_") {
                if let item = userVocabularyService.userVocabularyItem(id: vocabId)?.toVocabularyItem() {
                    matchingVocabs.append(item)
                }
            } else {
                if let item = repository.vocabularyItem(id: vocabId) {
                    matchingVocabs.append(item)
                }
            }
        }
        
        // Define candidates pool for distractors: current source deck, fallback to all vocabs if deck is too small
        let distractorPool = matchingVocabs.count >= 10 ? matchingVocabs : allVocabs
        
        var generatedCards: [ReviewCard] = []
        
        for correctItem in matchingVocabs {
            // For custom user-created words, always use the fallback Reveal Card mode
            if correctItem.status == "custom" {
                let card = ReviewCard(
                    id: "\(correctItem.id)_custom_reveal",
                    targetType: .vocabulary,
                    targetId: correctItem.id,
                    promptId: nil,
                    mode: .mixed,
                    promptText: correctItem.japanese,
                    promptSubtext: reviewOptions.showReading ? correctItem.reading : nil,
                    choices: [],
                    correctChoiceId: "",
                    explanationTh: nil,
                    vocabularyItem: correctItem
                )
                generatedCards.append(card)
                continue
            }
            
            // Determine active mode for this specific card
            let cardMode = determineCardMode(for: correctItem, baseMode: reviewOptions.questionMode, repository: repository)
            
            // Build card based on mode
            if cardMode == .seedMultipleChoice {
                // Find preloaded prompt
                let prompts = repository.allFlashcardPrompts().filter { $0.targetType == .vocabulary && $0.targetId == correctItem.id }
                if let prompt = prompts.first {
                    // Seed mode
                    var choicesList: [ReviewChoice] = []
                    for choiceText in prompt.choices {
                        let isCorrect = (choiceText == prompt.correctAnswer)
                        // Try to find matching vocabulary item to show Romaji in choices if enabled
                        var romajiSub: String? = nil
                        if reviewOptions.showRomajiInChoices {
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
                    // Fallback to Japanese to Thai if no seed prompt found
                    let card = generateCustomCard(correctItem: correctItem, mode: .japaneseToThai, pool: distractorPool)
                    generatedCards.append(card)
                }
            } else {
                // Custom generated mode
                let card = generateCustomCard(correctItem: correctItem, mode: cardMode, pool: distractorPool)
                generatedCards.append(card)
            }
        }
        
        // Shuffle cards if enabled
        if reviewOptions.shuffle {
            generatedCards.shuffle()
        }
        
        // Apply card limit
        if reviewOptions.cardLimit < generatedCards.count {
            generatedCards = Array(generatedCards.prefix(reviewOptions.cardLimit))
        }
        
        return generatedCards
    }
    
    private func determineCardMode(for item: VocabularyItem, baseMode: FlashCardQuestionMode, repository: StudyDataRepository) -> FlashCardQuestionMode {
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
    
    private func generateCustomCard(correctItem: VocabularyItem, mode: FlashCardQuestionMode, pool: [VocabularyItem]) -> ReviewCard {
        let cardId = "\(correctItem.id)_\(mode.rawValue)"
        
        // Helper to select distractors
        let getCandidatesText: (VocabularyItem) -> String = { item in
            switch mode {
            case .japaneseToThai, .readingToMeaning: return item.meaningTh
            case .thaiToJapanese: return item.japanese
            case .meaningToReading: return item.reading
            default: return item.japanese
            }
        }
        
        let distractorItems = getDistractors(correctItem: correctItem, candidates: pool, textSelector: getCandidatesText, count: 3)
        
        // Fallback to reveal card if not enough distractors
        if distractorItems.count < 3 {
            // Empty choices represent reveal card
            return ReviewCard(
                id: cardId,
                targetType: .vocabulary,
                targetId: correctItem.id,
                promptId: nil,
                mode: mode,
                promptText: correctItem.japanese,
                promptSubtext: nil,
                choices: [],
                correctChoiceId: "",
                explanationTh: nil,
                vocabularyItem: correctItem
            )
        }
        
        // Build Choices
        var choicesList: [ReviewChoice] = []
        
        // Add Correct Choice
        let correctText = getCandidatesText(correctItem)
        var correctSec: String? = nil
        var correctTer: String? = nil
        
        if mode == .thaiToJapanese {
            correctSec = reviewOptions.showReading ? correctItem.reading : nil
            correctTer = (reviewOptions.showRomaji && reviewOptions.showRomajiInChoices) ? correctItem.romaji : nil
        } else if mode == .meaningToReading {
            correctSec = (reviewOptions.showRomaji && reviewOptions.showRomajiInChoices) ? correctItem.romaji : nil
            correctTer = reviewOptions.showReading ? correctItem.japanese : nil
        }
        
        choicesList.append(ReviewChoice(
            id: correctText,
            primaryText: correctText,
            secondaryText: correctSec,
            tertiaryText: correctTer,
            isCorrect: true
        ))
        
        // Add Distractors
        for distItem in distractorItems {
            let distText = getCandidatesText(distItem)
            var distSec: String? = nil
            var distTer: String? = nil
            
            if mode == .thaiToJapanese {
                distSec = reviewOptions.showReading ? distItem.reading : nil
                distTer = (reviewOptions.showRomaji && reviewOptions.showRomajiInChoices) ? distItem.romaji : nil
            } else if mode == .meaningToReading {
                distSec = (reviewOptions.showRomaji && reviewOptions.showRomajiInChoices) ? distItem.romaji : nil
                distTer = reviewOptions.showReading ? distItem.japanese : nil
            }
            
            choicesList.append(ReviewChoice(
                id: distText,
                primaryText: distText,
                secondaryText: distSec,
                tertiaryText: distTer,
                isCorrect: false
            ))
        }
        
        choicesList.shuffle()
        
        // Resolve Prompt Texts
        var pText = correctItem.japanese
        var pSub: String? = nil
        
        switch mode {
        case .japaneseToThai:
            pText = correctItem.japanese
            pSub = (reviewOptions.showReading ? correctItem.reading : "") +
                   (reviewOptions.showReading && reviewOptions.showRomaji ? " / " : "") +
                   (reviewOptions.showRomaji ? correctItem.romaji : "")
            if pSub?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true { pSub = nil }
        case .thaiToJapanese:
            pText = correctItem.meaningTh
            pSub = nil
        case .readingToMeaning:
            pText = correctItem.reading
            pSub = reviewOptions.showRomaji ? correctItem.romaji : nil
        case .meaningToReading:
            pText = correctItem.meaningTh
            pSub = nil
        default:
            break
        }
        
        return ReviewCard(
            id: cardId,
            targetType: .vocabulary,
            targetId: correctItem.id,
            promptId: nil,
            mode: mode,
            promptText: pText,
            promptSubtext: pSub,
            choices: choicesList,
            correctChoiceId: correctText,
            explanationTh: "คำนี้แปลว่า \"\(correctItem.meaningTh)\" (อ่านว่า \(correctItem.reading))",
            vocabularyItem: correctItem
        )
    }
    
    private func getDistractors(correctItem: VocabularyItem, candidates: [VocabularyItem], textSelector: (VocabularyItem) -> String, count: Int) -> [VocabularyItem] {
        let correctText = textSelector(correctItem).trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        var filteredCandidates = candidates.filter { item in
            item.id != correctItem.id &&
            !textSelector(item).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            textSelector(item).trimmingCharacters(in: .whitespacesAndNewlines).lowercased() != correctText
        }
        
        filteredCandidates.shuffle()
        
        var selectedDistractors: [VocabularyItem] = []
        var selectedTexts = Set<String>([correctText])
        
        let matchingPriority = filteredCandidates.filter { item in
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
        
        for item in filteredCandidates {
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
