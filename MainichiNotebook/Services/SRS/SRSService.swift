import Foundation
import Combine
import SwiftUI

struct SRSHistoryState: Codable {
    var records: [SRSReviewRecord]
    var lastSessionCorrectRate: Double?
}

@MainActor
final class SRSService: ObservableObject {
    @Published var cardStates: [String: SRSCardState] = [:]
    @Published var historyRecords: [SRSReviewRecord] = []
    @Published var lastSessionCorrectRate: Double?
    
    private var libraryCancellable: AnyCancellable?
    
    private var cardStatesURL: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        let directoryURL = documentsDirectory.appendingPathComponent("MainichiUserData", isDirectory: true)
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        return directoryURL.appendingPathComponent("srs-card-states.json")
    }
    
    private var historyURL: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        let directoryURL = documentsDirectory.appendingPathComponent("MainichiUserData", isDirectory: true)
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        return directoryURL.appendingPathComponent("flashcard-review-history.json")
    }
    
    init() {
        load()
    }
    
    func observeLibrary(_ libraryService: StudyUserLibraryService) {
        libraryCancellable = libraryService.$state
            .receive(on: RunLoop.main)
            .sink { [weak self] libraryState in
                self?.sync(flashcardTargets: libraryState.flashcardTargets)
            }
    }
    
    // MARK: - Load & Save
    
    func load() {
        // 1. Load SRS Card States
        let statesPath = cardStatesURL
        if FileManager.default.fileExists(atPath: statesPath.path) {
            do {
                let data = try Data(contentsOf: statesPath)
                let statesList = try JSONDecoder().decode([SRSCardState].self, from: data)
                var tempStates: [String: SRSCardState] = [:]
                for state in statesList {
                    tempStates[state.id] = state
                }
                self.cardStates = tempStates
                print("[SRSService] Loaded \(cardStates.count) SRS card states.")
            } catch {
                print("[SRSService] Failed to load card states: \(error.localizedDescription)")
            }
        }
        
        // 2. Load History
        let histPath = historyURL
        if FileManager.default.fileExists(atPath: histPath.path) {
            do {
                let data = try Data(contentsOf: histPath)
                let historyState = try JSONDecoder().decode(SRSHistoryState.self, from: data)
                self.historyRecords = historyState.records
                self.lastSessionCorrectRate = historyState.lastSessionCorrectRate
                print("[SRSService] Loaded \(historyRecords.count) review history records.")
            } catch {
                print("[SRSService] Failed to decode history directly: \(error.localizedDescription). Trying legacy fallback...")
                
                // Legacy decoding fallback if needed
                struct LegacyHistoryState: Codable {
                    var records: [LegacyReviewRecord]
                    var lastSessionCorrectRate: Double?
                }
                struct LegacyReviewRecord: Codable {
                    var id: UUID
                    var targetType: StudyDataTargetType
                    var targetId: String
                    var promptId: String?
                    var rating: String
                    var wasCorrect: Bool?
                    var reviewedAt: Date
                    var questionMode: FlashCardQuestionMode?
                }
                
                if let legacyData = try? Data(contentsOf: histPath),
                   let legacyState = try? JSONDecoder().decode(LegacyHistoryState.self, from: legacyData) {
                    self.historyRecords = legacyState.records.map { legacy in
                        let r = SRSRating(rawValue: legacy.rating.lowercased()) ?? .good
                        return SRSReviewRecord(
                            id: legacy.id,
                            targetType: legacy.targetType,
                            targetId: legacy.targetId,
                            promptId: legacy.promptId,
                            rating: r,
                            wasCorrect: legacy.wasCorrect,
                            reviewedAt: legacy.reviewedAt,
                            previousDueDate: nil,
                            nextDueDate: nil,
                            previousIntervalDays: nil,
                            nextIntervalDays: nil,
                            previousEaseFactor: nil,
                            nextEaseFactor: nil,
                            questionMode: legacy.questionMode
                        )
                    }
                    self.lastSessionCorrectRate = legacyState.lastSessionCorrectRate
                    print("[SRSService] Migrated \(historyRecords.count) legacy review records successfully.")
                }
            }
        }
    }
    
    func save() {
        // 1. Save Card States
        do {
            let list = Array(cardStates.values)
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(list)
            try data.write(to: cardStatesURL, options: .atomic)
        } catch {
            print("[SRSService] Failed to save card states: \(error.localizedDescription)")
        }
        
        // 2. Save History
        do {
            let state = SRSHistoryState(records: historyRecords, lastSessionCorrectRate: lastSessionCorrectRate)
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(state)
            try data.write(to: historyURL, options: .atomic)
        } catch {
            print("[SRSService] Failed to save history: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Library Sync Helper
    
    private func sync(flashcardTargets: [SavedStudyTarget]) {
        let activeKeys = Set(flashcardTargets.map { "\($0.targetType.rawValue)_\($0.targetId)" })
        
        // Remove states that are no longer in flashcardTargets
        let originalCount = cardStates.count
        cardStates = cardStates.filter { activeKeys.contains($0.key) }
        
        // Create new states for items not present
        let now = Date()
        for target in flashcardTargets {
            let key = "\(target.targetType.rawValue)_\(target.targetId)"
            if cardStates[key] == nil {
                cardStates[key] = SRSCardState(
                    id: key,
                    targetType: target.targetType,
                    targetId: target.targetId,
                    status: .new,
                    dueDate: nil,
                    lastReviewedAt: nil,
                    firstReviewedAt: nil,
                    intervalDays: 0,
                    easeFactor: 2.5,
                    reviewCount: 0,
                    lapseCount: 0,
                    createdAt: now,
                    updatedAt: now
                )
            }
        }
        
        if cardStates.count != originalCount {
            print("[SRSService] Synced with library. Original: \(originalCount), New: \(cardStates.count)")
            save()
        }
    }
    
    // MARK: - Core API
    
    func state(for targetType: StudyDataTargetType, targetId: String) -> SRSCardState? {
        let key = "\(targetType.rawValue)_\(targetId)"
        return cardStates[key]
    }
    
    func ensureState(for targetType: StudyDataTargetType, targetId: String) -> SRSCardState {
        let key = "\(targetType.rawValue)_\(targetId)"
        if let st = cardStates[key] {
            return st
        }
        
        let now = Date()
        let newState = SRSCardState(
            id: key,
            targetType: targetType,
            targetId: targetId,
            status: .new,
            dueDate: nil,
            lastReviewedAt: nil,
            firstReviewedAt: nil,
            intervalDays: 0,
            easeFactor: 2.5,
            reviewCount: 0,
            lapseCount: 0,
            createdAt: now,
            updatedAt: now
        )
        cardStates[key] = newState
        save()
        return newState
    }
    
    func review(
        targetType: StudyDataTargetType,
        targetId: String,
        promptId: String?,
        rating: SRSRating,
        wasCorrect: Bool?,
        questionMode: FlashCardQuestionMode? = nil
    ) -> SRSReviewRecord {
        let st = ensureState(for: targetType, targetId: targetId)
        let now = Date()
        let result = SRScheduler.nextState(currentState: st, rating: rating, now: now)
        
        let nextSt = result.nextState
        var record = result.record
        
        // Fill dynamic fields
        record.promptId = promptId
        record.wasCorrect = wasCorrect
        record.questionMode = questionMode
        
        cardStates[nextSt.id] = nextSt
        historyRecords.append(record)
        
        save()
        return record
    }
    
    func logSessionFinished(correctRate: Double) {
        lastSessionCorrectRate = correctRate
        save()
    }
    
    func dueCards(now: Date = Date()) -> [SRSCardState] {
        return Array(cardStates.values).filter { state in
            state.status != .new && (state.dueDate.map { $0 <= now } ?? false)
        }.sorted { ($0.dueDate ?? Date()) < ($1.dueDate ?? Date()) }
    }
    
    func newCards(limit: Int? = nil) -> [SRSCardState] {
        let list = Array(cardStates.values).filter { $0.status == .new }
            .sorted { $0.createdAt < $1.createdAt }
        if let lim = limit {
            return Array(list.prefix(lim))
        }
        return list
    }
    
    func allActiveCardStates() -> [SRSCardState] {
        return Array(cardStates.values)
    }
    
    func queueSummary(now: Date = Date()) -> SRSQueueSummary {
        let allStates = Array(cardStates.values)
        
        let due = allStates.filter {
            $0.status != .new && ($0.dueDate.map { $0 <= now } ?? false)
        }.count
        
        let newCount = allStates.filter { $0.status == .new }.count
        let learning = allStates.filter { $0.status == .learning || $0.status == .relearning }.count
        let reviewCount = allStates.filter { $0.status == .review }.count
        
        let calendar = Calendar.current
        let todayReviews = historyRecords.filter { calendar.isDateInToday($0.reviewedAt) }.count
        
        return SRSQueueSummary(
            dueCount: due,
            newCount: newCount,
            learningCount: learning,
            reviewCount: reviewCount,
            totalActiveCount: allStates.count,
            reviewedTodayCount: todayReviews
        )
    }
    
    func resetProgress(for targetType: StudyDataTargetType, targetId: String) {
        let key = "\(targetType.rawValue)_\(targetId)"
        if let st = cardStates[key] {
            let now = Date()
            cardStates[key] = SRSCardState(
                id: key,
                targetType: targetType,
                targetId: targetId,
                status: .new,
                dueDate: nil,
                lastReviewedAt: nil,
                firstReviewedAt: nil,
                intervalDays: 0,
                easeFactor: 2.5,
                reviewCount: 0,
                lapseCount: 0,
                createdAt: st.createdAt,
                updatedAt: now
            )
            save()
        }
    }
    
    func removeState(for targetType: StudyDataTargetType, targetId: String) {
        let key = "\(targetType.rawValue)_\(targetId)"
        cardStates.removeValue(forKey: key)
        save()
    }
    
    // MARK: - Debug utilities
    
    func debugMarkAllDue() {
        let now = Date()
        let tenMinsAgo = now.addingTimeInterval(-601)
        for key in cardStates.keys {
            if cardStates[key]?.status == .new {
                cardStates[key]?.status = .learning
            }
            cardStates[key]?.dueDate = tenMinsAgo
        }
        save()
    }
    
    func debugResetAllSRSProgress() {
        let now = Date()
        for key in cardStates.keys {
            if let st = cardStates[key] {
                cardStates[key] = SRSCardState(
                    id: st.id,
                    targetType: st.targetType,
                    targetId: st.targetId,
                    status: .new,
                    dueDate: nil,
                    lastReviewedAt: nil,
                    firstReviewedAt: nil,
                    intervalDays: 0,
                    easeFactor: 2.5,
                    reviewCount: 0,
                    lapseCount: 0,
                    createdAt: st.createdAt,
                    updatedAt: now
                )
            }
        }
        save()
    }
}
