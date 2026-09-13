import Foundation

struct FlashCardHistoryState: Codable {
    var records: [FlashCardReviewRecord]
    var lastSessionCorrectRate: Double?
}

@MainActor
final class FlashCardReviewHistoryService: ObservableObject {
    @Published var state = FlashCardHistoryState(records: [], lastSessionCorrectRate: nil)
    
    private var fileURL: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        let directoryURL = documentsDirectory.appendingPathComponent("MainichiUserData", isDirectory: true)
        
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        return directoryURL.appendingPathComponent("flashcard-review-history.json")
    }
    
    init() {
        loadHistory()
    }
    
    func loadHistory() {
        let url = fileURL
        guard FileManager.default.fileExists(atPath: url.path) else {
            self.state = FlashCardHistoryState(records: [], lastSessionCorrectRate: nil)
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            self.state = try JSONDecoder().decode(FlashCardHistoryState.self, from: data)
            print("[FlashCardReviewHistoryService] Loaded \(state.records.count) records. Last session correct rate: \(String(describing: state.lastSessionCorrectRate))")
        } catch {
            print("[FlashCardReviewHistoryService] Failed to load history: \(error.localizedDescription)")
            self.state = FlashCardHistoryState(records: [], lastSessionCorrectRate: nil)
        }
    }
    
    func saveHistory() {
        let url = fileURL
        do {
            let data = try JSONEncoder().encode(state)
            try data.write(to: url, options: .atomic)
            print("[FlashCardReviewHistoryService] History saved successfully.")
        } catch {
            print("[FlashCardReviewHistoryService] Failed to save history: \(error.localizedDescription)")
        }
    }
    
    func logReview(targetType: StudyDataTargetType, targetId: String, promptId: String?, rating: FlashCardReviewRating, wasCorrect: Bool?, questionMode: FlashCardQuestionMode? = nil) {
        let record = FlashCardReviewRecord(
            id: UUID(),
            targetType: targetType,
            targetId: targetId,
            promptId: promptId,
            rating: rating,
            wasCorrect: wasCorrect,
            reviewedAt: Date(),
            questionMode: questionMode
        )
        state.records.append(record)
        saveHistory()
    }
    
    func logSessionFinished(correctRate: Double) {
        state.lastSessionCorrectRate = correctRate
        saveHistory()
    }
    
    // MARK: - Stats Helpers
    
    var totalReviewsCount: Int {
        state.records.count
    }
    
    var todayReviewsCount: Int {
        let calendar = Calendar.current
        return state.records.filter { calendar.isDateInToday($0.reviewedAt) }.count
    }
    
    var todayCorrectRate: Double? {
        let calendar = Calendar.current
        let todayRecords = state.records.filter { calendar.isDateInToday($0.reviewedAt) }
        
        // Filter those records that have a correctness status (multiple-choice cards)
        let gradedRecords = todayRecords.compactMap { $0.wasCorrect }
        guard !gradedRecords.isEmpty else { return nil }
        
        let correctCount = gradedRecords.filter { $0 }.count
        return Double(correctCount) / Double(gradedRecords.count)
    }
    
    var lastSessionScore: Double? {
        state.lastSessionCorrectRate
    }
    
    var uniqueReviewedWordsCount: Int {
        let vocabTargetIds = state.records
            .filter { $0.targetType == .vocabulary }
            .map { $0.targetId }
        return Set(vocabTargetIds).count
    }
}
