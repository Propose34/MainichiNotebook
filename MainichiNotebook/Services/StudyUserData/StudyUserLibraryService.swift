import Foundation

@MainActor
final class StudyUserLibraryService: ObservableObject {
    @Published var state: StudyUserLibraryState = StudyUserLibraryState(favoriteTargets: [], myListTargets: [], flashcardTargets: [], lastUpdated: Date())
    
    private var fileURL: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        let directoryURL = documentsDirectory.appendingPathComponent("MainichiUserData", isDirectory: true)
        
        // Ensure directory exists
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        
        return directoryURL.appendingPathComponent("study-user-library.json")
    }
    
    init() {
        loadState()
    }
    
    // MARK: - Save & Load
    
    func loadState() {
        let url = fileURL
        guard FileManager.default.fileExists(atPath: url.path) else {
            self.state = StudyUserLibraryState(favoriteTargets: [], myListTargets: [], flashcardTargets: [], lastUpdated: Date())
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            self.state = try JSONDecoder().decode(StudyUserLibraryState.self, from: data)
            print("[StudyUserLibraryService] State loaded successfully from Documents: \(state.favoriteTargets.count) favs, \(state.myListTargets.count) lists, \(state.flashcardTargets.count) flashcards.")
        } catch {
            print("[StudyUserLibraryService] Failed to load study user library state: \(error.localizedDescription)")
            // Fallback to empty state
            self.state = StudyUserLibraryState(favoriteTargets: [], myListTargets: [], flashcardTargets: [], lastUpdated: Date())
        }
    }
    
    func saveState() {
        let url = fileURL
        state.lastUpdated = Date()
        
        do {
            let data = try JSONEncoder().encode(state)
            try data.write(to: url, options: .atomic)
            print("[StudyUserLibraryService] State saved successfully to \(url.lastPathComponent)")
        } catch {
            print("[StudyUserLibraryService] Failed to save state: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Query Helpers
    
    func isFavorite(targetType: StudyDataTargetType, targetId: String) -> Bool {
        return state.favoriteTargets.contains(where: { $0.targetType == targetType && $0.targetId == targetId })
    }
    
    func isInMyList(targetType: StudyDataTargetType, targetId: String) -> Bool {
        return state.myListTargets.contains(where: { $0.targetType == targetType && $0.targetId == targetId })
    }
    
    func isInFlashcards(targetType: StudyDataTargetType, targetId: String) -> Bool {
        return state.flashcardTargets.contains(where: { $0.targetType == targetType && $0.targetId == targetId })
    }
    
    // MARK: - Toggles
    
    func toggleFavorite(targetType: StudyDataTargetType, targetId: String) {
        if let idx = state.favoriteTargets.firstIndex(where: { $0.targetType == targetType && $0.targetId == targetId }) {
            state.favoriteTargets.remove(at: idx)
            print("[StudyUserLibraryService] Removed favorite: \(targetId)")
        } else {
            let target = SavedStudyTarget(targetType: targetType, targetId: targetId, dateAdded: Date())
            state.favoriteTargets.append(target)
            print("[StudyUserLibraryService] Added favorite: \(targetId)")
        }
        saveState()
    }
    
    func toggleMyList(targetType: StudyDataTargetType, targetId: String) {
        if let idx = state.myListTargets.firstIndex(where: { $0.targetType == targetType && $0.targetId == targetId }) {
            state.myListTargets.remove(at: idx)
            print("[StudyUserLibraryService] Removed from My List: \(targetId)")
        } else {
            let target = SavedStudyTarget(targetType: targetType, targetId: targetId, dateAdded: Date())
            state.myListTargets.append(target)
            print("[StudyUserLibraryService] Added to My List: \(targetId)")
        }
        saveState()
    }
    
    func toggleFlashcardCollection(targetType: StudyDataTargetType, targetId: String) {
        if let idx = state.flashcardTargets.firstIndex(where: { $0.targetType == targetType && $0.targetId == targetId }) {
            state.flashcardTargets.remove(at: idx)
            print("[StudyUserLibraryService] Removed from Flashcards: \(targetId)")
        } else {
            let target = SavedStudyTarget(targetType: targetType, targetId: targetId, dateAdded: Date())
            state.flashcardTargets.append(target)
            print("[StudyUserLibraryService] Added to Flashcards: \(targetId)")
        }
        saveState()
    }
    
    // MARK: - ID Sets
    
    func favoriteVocabularyIds() -> Set<String> {
        return Set(state.favoriteTargets.filter { $0.targetType == .vocabulary }.map { $0.targetId })
    }
    
    func myListVocabularyIds() -> Set<String> {
        return Set(state.myListTargets.filter { $0.targetType == .vocabulary }.map { $0.targetId })
    }
    
    func flashcardVocabularyIds() -> Set<String> {
        return Set(state.flashcardTargets.filter { $0.targetType == .vocabulary }.map { $0.targetId })
    }
}
