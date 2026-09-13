import Foundation
import Combine
import SwiftUI

@MainActor
final class DailySummaryViewModel: ObservableObject {
    let service: DailySummaryService
    let srsService: SRSService
    let libraryService: StudyUserLibraryService
    let userVocabularyService: UserVocabularyService
    let writingProgressService: WritingPracticeProgressService
    let simpleVocabProgressService: SimpleVocabularyProgressService
    
    private let aggregator: DailyActivityAggregator
    private var cancellables = Set<AnyCancellable>()
    
    @Published var selectedDate: Date = Date() {
        didSet {
            loadSelectedEntry()
        }
    }
    
    // Inputs bound to UI
    @Published var manualMinutes: Int = 0
    @Published var dailyNote: String = ""
    @Published var activeSnapshot: DailyActivitySnapshot?
    
    let defaultTasks = [
        DailyTaskItem(id: "review-flashcards", title: "Review Flash Cards", titleTh: "ทบทวนการ์ดคำศัพท์ (Flash Cards)", description: "ทบทวนการ์ดที่ถึงกำหนดส่งวันนี้"),
        DailyTaskItem(id: "practice-writing", title: "Practice Writing", titleTh: "ฝึกคัดลายเส้นตัวอักษร (Kana/Kanji)", description: "ฝึกเขียนตัวอักษรบนกระดาษคัดลายมือ"),
        DailyTaskItem(id: "learn-5-words", title: "Learn 5 New Words", titleTh: "เรียนรู้คำศัพท์ใหม่ 5 คำ", description: "เปิดดูคำศัพท์ใหม่ในคลังคำศัพท์หรือหมวดความรู้"),
        DailyTaskItem(id: "add-one-note", title: "Write Daily Note", titleTh: "เขียนบันทึกประจำวันสั้นๆ", description: "จดบันทึกย่อการเรียนรู้วันนี้ลงในสมุดบันทึก"),
        DailyTaskItem(id: "listen-pronunciation", title: "Listen to Pronunciation", titleTh: "ฟังเสียงออกเสียงภาษาญี่ปุ่น", description: "กดฟังเสียงอ่านสะกดคำอย่างถูกต้อง")
    ]
    
    init(
        service: DailySummaryService,
        srsService: SRSService,
        libraryService: StudyUserLibraryService,
        userVocabularyService: UserVocabularyService,
        writingProgressService: WritingPracticeProgressService,
        simpleVocabProgressService: SimpleVocabularyProgressService
    ) {
        self.service = service
        self.srsService = srsService
        self.libraryService = libraryService
        self.userVocabularyService = userVocabularyService
        self.writingProgressService = writingProgressService
        self.simpleVocabProgressService = simpleVocabProgressService
        self.aggregator = DailyActivityAggregator(
            srsService: srsService,
            userLibraryService: libraryService,
            userVocabularyService: userVocabularyService,
            writingProgressService: writingProgressService,
            simpleVocabProgressService: simpleVocabProgressService
        )
        
        loadSelectedEntry()
        
        // Redraw when services update dynamically
        Publishers.CombineLatest4(
            service.$entries,
            srsService.$historyRecords,
            libraryService.$state,
            writingProgressService.$progressItems
        )
        .receive(on: RunLoop.main)
        .sink { [weak self] _, _, _, _ in
            guard let self = self else { return }
            self.loadSelectedEntry()
        }
        .store(in: &cancellables)
    }
    
    var activeEntry: DailySummaryEntry {
        service.getEntry(for: selectedDate)
    }
    
    var selectedDateKey: String {
        service.makeDateKey(from: selectedDate)
    }
    
    // MARK: - Actions
    
    func loadSelectedEntry() {
        let entry = activeEntry
        self.manualMinutes = entry.manualStudyMinutes
        self.dailyNote = entry.dailyNote
        self.activeSnapshot = aggregator.buildSnapshot(for: selectedDate)
    }
    
    func selectMood(_ mood: DailyMood?) {
        service.updateMood(dateKey: selectedDateKey, mood: mood)
    }
    
    func addMinutes(_ mins: Int) {
        let newMins = manualMinutes + mins
        self.manualMinutes = max(0, newMins)
        service.updateManualStudyMinutes(dateKey: selectedDateKey, minutes: manualMinutes)
    }
    
    func saveNote() {
        service.updateDailyNote(dateKey: selectedDateKey, note: dailyNote)
    }
    
    func toggleTask(_ taskId: String) {
        service.toggleTask(dateKey: selectedDateKey, taskId: taskId)
    }
    
    // MARK: - Recent History List
    
    struct PastDaySummary: Identifiable, Hashable {
        var id: String { dateKey }
        let date: Date
        let dateKey: String
        let mood: DailyMood?
        let manualStudyMinutes: Int
        let flashcardsReviewed: Int
        let hasNote: Bool
    }
    
    var recentDays: [PastDaySummary] {
        var summaries: [PastDaySummary] = []
        let calendar = Calendar.current
        let today = Date()
        
        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            let key = service.makeDateKey(from: date)
            let entry = service.getEntry(forDateKey: key)
            let snapshot = aggregator.buildSnapshot(for: date)
            
            summaries.append(PastDaySummary(
                date: date,
                dateKey: key,
                mood: entry.mood,
                manualStudyMinutes: entry.manualStudyMinutes,
                flashcardsReviewed: snapshot.reviewedFlashcards,
                hasNote: !entry.dailyNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ))
        }
        
        return summaries
    }
    
    // MARK: - Computed Overall Metrics
    
    var weeklyTotalStudyMinutes: Int {
        var total = 0
        let calendar = Calendar.current
        let today = Date()
        
        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            let key = service.makeDateKey(from: date)
            let entry = service.getEntry(forDateKey: key)
            total += entry.manualStudyMinutes
        }
        return total
    }
    
    var weeklyReviewedCards: Int {
        var total = 0
        let calendar = Calendar.current
        let today = Date()
        
        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            let snapshot = aggregator.buildSnapshot(for: date)
            total += snapshot.reviewedFlashcards
        }
        return total
    }
}
