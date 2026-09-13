import Foundation
import Combine

@MainActor
final class DailySummaryService: ObservableObject {
    @Published var entries: [String: DailySummaryEntry] = [:]
    
    private var fileURL: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        let directoryURL = documentsDirectory.appendingPathComponent("MainichiUserData", isDirectory: true)
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        return directoryURL.appendingPathComponent("daily-summary.json")
    }
    
    init() {
        loadEntries()
    }
    
    // MARK: - Local Persistence
    
    func loadEntries() {
        let path = fileURL
        guard FileManager.default.fileExists(atPath: path.path) else {
            self.entries = [:]
            return
        }
        
        do {
            let data = try Data(contentsOf: path)
            let decoded = try JSONDecoder().decode([DailySummaryEntry].self, from: data)
            var temp: [String: DailySummaryEntry] = [:]
            for item in decoded {
                temp[item.dateKey] = item
            }
            self.entries = temp
            print("[DailySummaryService] Loaded \(entries.count) summary entries.")
        } catch {
            print("[DailySummaryService] Failed to load entries: \(error.localizedDescription)")
            self.entries = [:]
        }
    }
    
    func saveEntries() {
        let path = fileURL
        do {
            let list = Array(entries.values)
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(list)
            try data.write(to: path, options: .atomic)
            print("[DailySummaryService] Saved daily entries successfully.")
        } catch {
            print("[DailySummaryService] Failed to save entries: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Get / Create Helpers
    
    func makeDateKey(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }
    
    func getEntry(forDateKey dateKey: String) -> DailySummaryEntry {
        if let entry = entries[dateKey] {
            return entry
        }
        
        let now = Date()
        let newEntry = DailySummaryEntry(
            id: dateKey,
            dateKey: dateKey,
            mood: nil,
            manualStudyMinutes: 0,
            dailyNote: "",
            completedTaskIds: [],
            createdAt: now,
            updatedAt: now
        )
        entries[dateKey] = newEntry
        saveEntries()
        return newEntry
    }
    
    func getEntry(for date: Date) -> DailySummaryEntry {
        let key = makeDateKey(from: date)
        return getEntry(forDateKey: key)
    }
    
    // MARK: - Actions
    
    func updateMood(dateKey: String, mood: DailyMood?) {
        var entry = getEntry(forDateKey: dateKey)
        entry.mood = mood
        entry.updatedAt = Date()
        entries[dateKey] = entry
        saveEntries()
    }
    
    func updateManualStudyMinutes(dateKey: String, minutes: Int) {
        var entry = getEntry(forDateKey: dateKey)
        entry.manualStudyMinutes = max(0, minutes)
        entry.updatedAt = Date()
        entries[dateKey] = entry
        saveEntries()
    }
    
    func updateDailyNote(dateKey: String, note: String) {
        var entry = getEntry(forDateKey: dateKey)
        entry.dailyNote = note
        entry.updatedAt = Date()
        entries[dateKey] = entry
        saveEntries()
    }
    
    func toggleTask(dateKey: String, taskId: String) {
        var entry = getEntry(forDateKey: dateKey)
        if let idx = entry.completedTaskIds.firstIndex(of: taskId) {
            entry.completedTaskIds.remove(at: idx)
        } else {
            entry.completedTaskIds.append(taskId)
        }
        entry.updatedAt = Date()
        entries[dateKey] = entry
        saveEntries()
    }
    
    // MARK: - Streak Calculations
    
    func computeStreak() -> Int {
        let calendar = Calendar.current
        var currentStreak = 0
        var checkDate = Date()
        
        while true {
            let key = makeDateKey(from: checkDate)
            let entry = entries[key]
            let hasCompletedTasks = !(entry?.completedTaskIds.isEmpty ?? true)
            
            if hasCompletedTasks {
                currentStreak += 1
                guard let yesterday = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = yesterday
            } else {
                let isToday = calendar.isDateInToday(checkDate)
                if isToday {
                    guard let yesterday = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                    let yesterdayKey = makeDateKey(from: yesterday)
                    let yesterdayEntry = entries[yesterdayKey]
                    let yesterdayHasTasks = !(yesterdayEntry?.completedTaskIds.isEmpty ?? true)
                    if yesterdayHasTasks {
                        checkDate = yesterday
                        continue
                    }
                }
                break
            }
        }
        return currentStreak
    }
    
    func computeBestStreak() -> Int {
        let calendar = Calendar.current
        let activeKeys = entries.values
            .filter { !$0.completedTaskIds.isEmpty }
            .map { $0.dateKey }
            .sorted()
        
        guard !activeKeys.isEmpty else { return 0 }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        
        var bestStreak = 0
        var currentStreak = 0
        var lastDate: Date? = nil
        
        for key in activeKeys {
            guard let date = formatter.date(from: key) else { continue }
            if let last = lastDate {
                let components = calendar.dateComponents([.day], from: last, to: date)
                if components.day == 1 {
                    currentStreak += 1
                } else if components.day == 0 {
                    // Ignore same day
                } else {
                    bestStreak = max(bestStreak, currentStreak)
                    currentStreak = 1
                }
            } else {
                currentStreak = 1
            }
            lastDate = date
        }
        bestStreak = max(bestStreak, currentStreak)
        return bestStreak
    }
}
