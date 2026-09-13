import Foundation
import Combine

enum StudyDataLoadingState: Equatable, Hashable {
    case idle
    case loading
    case loaded
    case failed(String)
}

@MainActor
final class StudyDataService: ObservableObject {
    @Published var vocabularyItems: [VocabularyItem] = []
    @Published var kanjiItems: [KanjiItem] = []
    @Published var grammarPatterns: [GrammarPattern] = []
    @Published var flashcardPrompts: [FlashcardPrompt] = []
    @Published var decks: [StudyDeck] = []
    @Published var categories: [StudyCategory] = []
    @Published var manifest: StudyDataManifest?
    @Published var loadingState: StudyDataLoadingState = .idle
    @Published var validationResult: StudyDataValidationResult?

    init() {
        // Automatically start loading when initialized
        Task {
            await load()
        }
    }

    func load() async {
        guard loadingState != .loading else { return }
        loadingState = .loading
        print("[StudyDataService] Starting data load pipeline...")

        do {
            // 1. Load manifest
            guard let manifestURL = Bundle.main.url(forResource: "mainichi-data-manifest", withExtension: "json") else {
                throw NSError(domain: "StudyDataService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Manifest file 'mainichi-data-manifest.json' not found in bundle."])
            }
            
            let manifestData = try Data(contentsOf: manifestURL)
            let loadedManifest = try JSONDecoder().decode(StudyDataManifest.self, from: manifestData)
            self.manifest = loadedManifest
            
            print("[StudyDataService] Manifest loaded. Dataset version: \(loadedManifest.version), Name: \(loadedManifest.datasetName)")

            // Helper to get resource URL or throw
            let getURL = { (filename: String) throws -> URL in
                let baseName = (filename as NSString).deletingPathExtension
                let fileExtension = (filename as NSString).pathExtension
                guard let url = Bundle.main.url(forResource: baseName, withExtension: fileExtension) else {
                    throw NSError(domain: "StudyDataService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Resource file '\(filename)' not found in bundle."])
                }
                return url
            }

            // 2. Load Vocabulary
            let vocabURL = try getURL(loadedManifest.files.vocabulary)
            let vocabData = try Data(contentsOf: vocabURL)
            let loadedVocab = try JSONDecoder().decode([VocabularyItem].self, from: vocabData)

            // 3. Load Kanji
            let kanjiURL = try getURL(loadedManifest.files.kanji)
            let kanjiData = try Data(contentsOf: kanjiURL)
            let loadedKanji = try JSONDecoder().decode([KanjiItem].self, from: kanjiData)

            // 4. Load Grammar
            let grammarURL = try getURL(loadedManifest.files.grammarPatterns)
            let grammarData = try Data(contentsOf: grammarURL)
            let loadedGrammar = try JSONDecoder().decode([GrammarPattern].self, from: grammarData)

            // 5. Load Flashcards
            let promptsURL = try getURL(loadedManifest.files.flashcardPrompts)
            let promptsData = try Data(contentsOf: promptsURL)
            let loadedPrompts = try JSONDecoder().decode([FlashcardPrompt].self, from: promptsData)

            // 6. Load Decks
            let decksURL = try getURL(loadedManifest.files.decks)
            let decksData = try Data(contentsOf: decksURL)
            let loadedDecks = try JSONDecoder().decode([StudyDeck].self, from: decksData)

            // 7. Load Categories
            let categoriesURL = try getURL(loadedManifest.files.categories)
            let categoriesData = try Data(contentsOf: categoriesURL)
            let loadedCategories = try JSONDecoder().decode([StudyCategory].self, from: categoriesData)

            // 8. Assign loaded data to published properties
            self.vocabularyItems = loadedVocab
            self.kanjiItems = loadedKanji
            self.grammarPatterns = loadedGrammar
            self.flashcardPrompts = loadedPrompts
            self.decks = loadedDecks
            self.categories = loadedCategories

            // 9. Run validation
            let result = StudyDataValidation.validate(
                vocabularyItems: loadedVocab,
                kanjiItems: loadedKanji,
                grammarPatterns: loadedGrammar,
                flashcardPrompts: loadedPrompts,
                decks: loadedDecks,
                categories: loadedCategories
            )
            self.validationResult = result

            print("[StudyDataService] Data loading and validation complete. Passed: \(result.passed)")
            print("[StudyDataService] Counts -> Vocab: \(result.counts.vocabularyCount), Kanji: \(result.counts.kanjiCount), Grammar: \(result.counts.grammarPatternCount), Prompts: \(result.counts.flashcardPromptCount), Decks: \(result.counts.deckCount), Categories: \(result.counts.categoryCount) (+ \(result.counts.virtualCategoryCount) virtual)")
            
            if !result.passed {
                print("[StudyDataService] Validation Errors: \(result.errors)")
            }
            if !result.warnings.isEmpty {
                print("[StudyDataService] Validation Warnings: \(result.warnings)")
            }

            self.loadingState = .loaded

        } catch {
            let errorMsg = error.localizedDescription
            print("[StudyDataService] Failed to load data foundation: \(errorMsg)")
            self.loadingState = .failed(errorMsg)
        }
    }
}
