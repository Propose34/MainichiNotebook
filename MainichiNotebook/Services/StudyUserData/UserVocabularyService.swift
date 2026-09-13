import Foundation

@MainActor
final class UserVocabularyService: ObservableObject {
    @Published var userItems: [UserVocabularyItem] = []
    
    private var fileURL: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        let directoryURL = documentsDirectory.appendingPathComponent("MainichiUserData", isDirectory: true)
        
        // Ensure directory exists
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        
        return directoryURL.appendingPathComponent("user-vocabulary-items.json")
    }
    
    init() {
        loadUserVocabulary()
    }
    
    // MARK: - Core Database Actions
    
    func loadUserVocabulary() {
        let url = fileURL
        guard FileManager.default.fileExists(atPath: url.path) else {
            self.userItems = []
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            self.userItems = try decoder.decode([UserVocabularyItem].self, from: data)
            #if DEBUG
            print("[UserVocabularyService] Successfully loaded \(userItems.count) custom vocabulary items.")
            #endif
        } catch {
            #if DEBUG
            print("[UserVocabularyService] Failed to load custom vocabulary items: \(error.localizedDescription)")
            #endif
            self.userItems = []
        }
    }
    
    func saveUserVocabulary() {
        let url = fileURL
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(userItems)
            try data.write(to: url, options: .atomic)
            #if DEBUG
            print("[UserVocabularyService] Successfully saved \(userItems.count) custom vocabulary items.")
            #endif
        } catch {
            #if DEBUG
            print("[UserVocabularyService] Failed to save custom vocabulary items: \(error.localizedDescription)")
            #endif
        }
    }
    
    // MARK: - Query & Mutation Helpers
    
    func allUserVocabularyItems() -> [UserVocabularyItem] {
        return userItems
    }
    
    func userVocabularyItem(id: String) -> UserVocabularyItem? {
        return userItems.first(where: { $0.id == id })
    }
    
    func addUserVocabularyItem(_ item: UserVocabularyItem) {
        userItems.append(item)
        saveUserVocabulary()
    }
    
    func updateUserVocabularyItem(_ item: UserVocabularyItem) {
        if let idx = userItems.firstIndex(where: { $0.id == item.id }) {
            userItems[idx] = item
            saveUserVocabulary()
        }
    }
    
    func deleteUserVocabularyItem(id: String) {
        userItems.removeAll(where: { $0.id == id })
        saveUserVocabulary()
    }
}
