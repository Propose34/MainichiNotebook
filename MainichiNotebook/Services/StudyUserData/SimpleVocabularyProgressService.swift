import Foundation

@MainActor
final class SimpleVocabularyProgressService: ObservableObject {
    @Published var progressList: [SimpleVocabularyPackProgress] = []
    
    private var fileURL: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        let directoryURL = documentsDirectory.appendingPathComponent("MainichiUserData", isDirectory: true)
        
        // Ensure directory exists
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        
        return directoryURL.appendingPathComponent("simple-vocabulary-progress.json")
    }
    
    init() {
        loadProgress()
    }
    
    // MARK: - Save & Load
    
    func loadProgress() {
        let url = fileURL
        guard FileManager.default.fileExists(atPath: url.path) else {
            self.progressList = []
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            self.progressList = try JSONDecoder().decode([SimpleVocabularyPackProgress].self, from: data)
            print("[SimpleVocabularyProgressService] Loaded progress for \(progressList.count) packs.")
        } catch {
            print("[SimpleVocabularyProgressService] Failed to load progress: \(error.localizedDescription)")
            self.progressList = []
        }
    }
    
    func saveProgress() {
        let url = fileURL
        do {
            let data = try JSONEncoder().encode(progressList)
            try data.write(to: url, options: .atomic)
            print("[SimpleVocabularyProgressService] Saved progress successfully.")
        } catch {
            print("[SimpleVocabularyProgressService] Failed to save progress: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Actions
    
    func getProgress(for packId: String) -> SimpleVocabularyPackProgress {
        if let progress = progressList.first(where: { $0.packId == packId }) {
            return progress
        }
        // Return default empty progress
        return SimpleVocabularyPackProgress(
            id: packId,
            packId: packId,
            openedAt: nil,
            lastStudiedAt: nil,
            viewedWordIds: [],
            completedWordIds: [],
            studyCount: 0,
            updatedAt: Date()
        )
    }
    
    func trackOpened(packId: String) {
        var progress = getProgress(for: packId)
        if progress.openedAt == nil {
            progress.openedAt = Date()
        }
        progress.updatedAt = Date()
        updateProgress(progress)
    }
    
    func trackWordViewed(packId: String, wordId: String) {
        var progress = getProgress(for: packId)
        if !progress.viewedWordIds.contains(wordId) {
            progress.viewedWordIds.append(wordId)
            progress.updatedAt = Date()
            updateProgress(progress)
        }
    }
    
    func trackStudySession(packId: String, completedWordIds: [String]) {
        var progress = getProgress(for: packId)
        progress.studyCount += 1
        progress.lastStudiedAt = Date()
        
        for wId in completedWordIds {
            if !progress.completedWordIds.contains(wId) {
                progress.completedWordIds.append(wId)
            }
            if !progress.viewedWordIds.contains(wId) {
                progress.viewedWordIds.append(wId)
            }
        }
        progress.updatedAt = Date()
        updateProgress(progress)
    }
    
    private func updateProgress(_ progress: SimpleVocabularyPackProgress) {
        if let idx = progressList.firstIndex(where: { $0.packId == progress.packId }) {
            progressList[idx] = progress
        } else {
            progressList.append(progress)
        }
        saveProgress()
    }
}
