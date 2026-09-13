import Foundation
import Combine
import PencilKit

@MainActor
final class WritingPracticeProgressService: ObservableObject {
    @Published var progressItems: [String: WritingPracticeProgress] = [:]
    
    private var fileURL: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        let directoryURL = documentsDirectory.appendingPathComponent("MainichiUserData", isDirectory: true)
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        return directoryURL.appendingPathComponent("writing-practice-progress.json")
    }
    
    private var drawingsDirectoryURL: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        let dirURL = documentsDirectory.appendingPathComponent("MainichiUserData/WritingPractice/drawings", isDirectory: true)
        try? FileManager.default.createDirectory(at: dirURL, withIntermediateDirectories: true)
        return dirURL
    }
    
    init() {
        loadProgress()
    }
    
    func loadProgress() {
        let path = fileURL
        guard FileManager.default.fileExists(atPath: path.path) else {
            self.progressItems = [:]
            return
        }
        
        do {
            let data = try Data(contentsOf: path)
            let decoded = try JSONDecoder().decode([WritingPracticeProgress].self, from: data)
            var temp: [String: WritingPracticeProgress] = [:]
            for item in decoded {
                temp[item.characterId] = item
            }
            self.progressItems = temp
            print("[WritingPracticeProgressService] Loaded \(progressItems.count) progress records.")
        } catch {
            print("[WritingPracticeProgressService] Failed to load progress: \(error.localizedDescription)")
            self.progressItems = [:]
        }
    }
    
    func saveProgress() {
        let path = fileURL
        do {
            let list = Array(progressItems.values)
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(list)
            try data.write(to: path, options: .atomic)
        } catch {
            print("[WritingPracticeProgressService] Failed to save progress: \(error.localizedDescription)")
        }
    }
    
    func markPracticed(characterId: String, mode: WritingPracticeMode) {
        let now = Date()
        if var item = progressItems[characterId] {
            item.practiceCount += 1
            item.lastPracticedAt = now
            item.updatedAt = now
            progressItems[characterId] = item
        } else {
            let newItem = WritingPracticeProgress(
                id: characterId,
                characterId: characterId,
                mode: mode,
                practiceCount: 1,
                lastPracticedAt: now,
                createdAt: now,
                updatedAt: now
            )
            progressItems[characterId] = newItem
        }
        saveProgress()
    }
    
    func practiceCount(for characterId: String) -> Int {
        return progressItems[characterId]?.practiceCount ?? 0
    }
    
    func lastPracticedAt(for characterId: String) -> Date? {
        return progressItems[characterId]?.lastPracticedAt
    }
    
    func resetProgress(for characterId: String) {
        progressItems.removeValue(forKey: characterId)
        deleteDrawing(forCharacterId: characterId)
        saveProgress()
    }
    
    func resetAllProgress() {
        progressItems.removeAll()
        saveProgress()
        
        // Wipe all drawings files
        try? FileManager.default.removeItem(at: drawingsDirectoryURL)
        try? FileManager.default.createDirectory(at: drawingsDirectoryURL, withIntermediateDirectories: true)
    }
    
    // MARK: - Drawing Persistence
    
    func saveDrawing(_ drawing: PKDrawing, forCharacterId id: String) {
        let data = drawing.dataRepresentation()
        let fileURL = drawingsDirectoryURL.appendingPathComponent("\(id).bin")
        do {
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("[WritingPracticeProgressService] Failed to save drawing binary: \(error.localizedDescription)")
        }
    }
    
    func loadDrawing(forCharacterId id: String) -> PKDrawing {
        let fileURL = drawingsDirectoryURL.appendingPathComponent("\(id).bin")
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return PKDrawing() }
        
        if let data = try? Data(contentsOf: fileURL),
           let drawing = try? PKDrawing(data: data) {
            return drawing
        }
        return PKDrawing()
    }
    
    func deleteDrawing(forCharacterId id: String) {
        let fileURL = drawingsDirectoryURL.appendingPathComponent("\(id).bin")
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    // MARK: - Mode Summaries
    
    func modePracticedCount(mode: WritingPracticeMode) -> Int {
        return progressItems.values.filter { $0.mode == mode && $0.practiceCount > 0 }.count
    }
    
    func todayPracticedCount() -> Int {
        let calendar = Calendar.current
        return progressItems.values.filter { item in
            guard let date = item.lastPracticedAt else { return false }
            return calendar.isDateInToday(date)
        }.count
    }
}
