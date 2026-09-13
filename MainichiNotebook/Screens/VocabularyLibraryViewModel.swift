import Foundation
import Combine
import SwiftUI

enum VocabularyLayoutMode: String, Codable, CaseIterable {
    case grid
    case list
}

enum VocabularySortOption: String, CaseIterable, Identifiable {
    case japaneseAZ = "A-Z (Kana)"
    case japaneseZA = "Z-A (Kana)"
    case meaningAZ = "Thai Meaning (ก-ฮ)"
    case level = "JLPT Level"
    
    var id: String { self.rawValue }
}

enum VocabularyScope: String, CaseIterable, Identifiable {
    case all = "All Words"
    case seed = "Seed Words"
    case myWords = "My Words"
    case favorites = "Favorites"
    case myList = "My List"
    case flashcards = "Flash Cards"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .all: return "book"
        case .seed: return "archivebox"
        case .myWords: return "person.circle"
        case .favorites: return "star.fill"
        case .myList: return "plus.circle.fill"
        case .flashcards: return "square.stack.3d.up.fill"
        }
    }
}

@MainActor
final class VocabularyLibraryViewModel: ObservableObject {
    let service: StudyDataService
    let userLibraryService: StudyUserLibraryService
    let userVocabularyService: UserVocabularyService
    private let repository: StudyDataRepository
    private var cancellables = Set<AnyCancellable>()

    @Published var searchText: String = ""
    @Published var selectedCategoryId: String = "all-vocabulary"
    @Published var selectedScope: VocabularyScope = .all
    @Published var selectedLevel: String? = nil
    @Published var sortOption: VocabularySortOption = .japaneseAZ
    @Published var layoutMode: VocabularyLayoutMode = .grid
    @Published var selectedItemId: String? = nil
    
    init(service: StudyDataService, userLibraryService: StudyUserLibraryService, userVocabularyService: UserVocabularyService) {
        self.service = service
        self.userLibraryService = userLibraryService
        self.userVocabularyService = userVocabularyService
        self.repository = StudyDataRepository(service: service)
        
        // Observe data service, user library state, and user vocabulary dynamically
        Publishers.CombineLatest3(service.$vocabularyItems, userLibraryService.$state, userVocabularyService.$userItems)
            .receive(on: RunLoop.main)
            .sink { [weak self] _, _, _ in
                guard let self = self else { return }
                // Adjust selected item if it's no longer present in the filtered output
                let filtered = self.filteredVocabularyItems
                if let selected = self.selectedItemId, !filtered.contains(where: { $0.id == selected }) {
                    self.selectedItemId = filtered.first?.id
                } else if self.selectedItemId == nil {
                    self.selectedItemId = filtered.first?.id
                }
            }
            .store(in: &cancellables)
    }
    
    var filteredVocabularyItems: [VocabularyItem] {
        // 1. Get base items for selected category (both seed and user-created)
        let seedItems = repository.vocabularyItems(inCategory: selectedCategoryId)
        let customMappedItems = userVocabularyService.userItems.map { $0.toVocabularyItem() }
        let categoryCustomItems: [VocabularyItem]
        if selectedCategoryId == "all-vocabulary" {
            categoryCustomItems = customMappedItems
        } else {
            categoryCustomItems = customMappedItems.filter {
                $0.primaryCategory == selectedCategoryId || $0.categories.contains(selectedCategoryId)
            }
        }
        
        let categoryItems = seedItems + categoryCustomItems
        
        // 2. Filter by scope
        let scopeItems: [VocabularyItem]
        switch selectedScope {
        case .all:
            scopeItems = categoryItems
        case .seed:
            scopeItems = categoryItems.filter { $0.status != "custom" }
        case .myWords:
            scopeItems = categoryItems.filter { $0.status == "custom" }
        case .favorites:
            let favIds = userLibraryService.favoriteVocabularyIds()
            scopeItems = categoryItems.filter { favIds.contains($0.id) }
        case .myList:
            let listIds = userLibraryService.myListVocabularyIds()
            scopeItems = categoryItems.filter { listIds.contains($0.id) }
        case .flashcards:
            let fcIds = userLibraryService.flashcardVocabularyIds()
            scopeItems = categoryItems.filter { fcIds.contains($0.id) }
        }
        
        // 3. Filter by search text
        let searchedItems: [VocabularyItem]
        if searchText.isEmpty {
            searchedItems = scopeItems
        } else {
            let lowerSearch = searchText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            searchedItems = scopeItems.filter { item in
                item.japanese.lowercased().contains(lowerSearch) ||
                item.reading.lowercased().contains(lowerSearch) ||
                item.romaji.lowercased().contains(lowerSearch) ||
                item.meaningTh.lowercased().contains(lowerSearch) ||
                item.tags.contains(where: { $0.lowercased().contains(lowerSearch) })
            }
        }
        
        // 4. Filter by level
        let levelFilteredItems: [VocabularyItem]
        if let level = selectedLevel {
            levelFilteredItems = searchedItems.filter { $0.level == level || $0.studyLevel == level }
        } else {
            levelFilteredItems = searchedItems
        }
        
        // 5. Sort items
        return sortItems(levelFilteredItems)
    }
    
    var availableLevels: [String] {
        let levels = (service.vocabularyItems + userVocabularyService.userItems.map { $0.toVocabularyItem() }).compactMap { $0.level }
        return Array(Set(levels)).sorted()
    }
    
    var availableCategories: [StudyCategory] {
        return service.categories
    }
    
    var selectedItem: VocabularyItem? {
        guard let id = selectedItemId else { return nil }
        if id.hasPrefix("user_") {
            return userVocabularyService.userVocabularyItem(id: id)?.toVocabularyItem()
        }
        return repository.vocabularyItem(id: id)
    }
    
    private func sortItems(_ items: [VocabularyItem]) -> [VocabularyItem] {
        switch sortOption {
        case .japaneseAZ:
            return items.sorted { $0.reading.localizedCompare($1.reading) == .orderedAscending }
        case .japaneseZA:
            return items.sorted { $0.reading.localizedCompare($1.reading) == .orderedDescending }
        case .meaningAZ:
            return items.sorted { $0.meaningTh.localizedCompare($1.meaningTh) == .orderedAscending }
        case .level:
            return items.sorted {
                let lvl1 = $0.level ?? "N9"
                let lvl2 = $1.level ?? "N9"
                return lvl1.localizedCompare(lvl2) == .orderedAscending
            }
        }
    }
}
