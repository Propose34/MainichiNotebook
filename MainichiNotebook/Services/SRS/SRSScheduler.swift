import Foundation

struct SRScheduler {
    static func nextState(
        currentState: SRSCardState,
        rating: SRSRating,
        now: Date = Date()
    ) -> (nextState: SRSCardState, record: SRSReviewRecord) {
        var nextState = currentState
        let isFirstReview = currentState.lastReviewedAt == nil
        
        let prevDueDate = currentState.dueDate
        let prevIntervalDays = currentState.intervalDays
        let prevEaseFactor = currentState.easeFactor
        
        // General updates
        nextState.lastReviewedAt = now
        if nextState.firstReviewedAt == nil {
            nextState.firstReviewedAt = now
        }
        nextState.reviewCount += 1
        nextState.updatedAt = now
        
        if rating == .again {
            nextState.lapseCount += 1
        }
        
        if isFirstReview {
            // First review scheduling
            switch rating {
            case .again:
                nextState.status = .learning
                nextState.intervalDays = 0.0
                nextState.dueDate = Calendar.current.date(byAdding: .minute, value: 10, to: now)
                nextState.easeFactor = max(1.3, currentState.easeFactor - 0.20)
            case .hard:
                nextState.status = .review
                nextState.intervalDays = 1.0
                nextState.dueDate = Calendar.current.date(byAdding: .day, value: 1, to: now)
                nextState.easeFactor = max(1.3, currentState.easeFactor - 0.15)
            case .good:
                nextState.status = .review
                nextState.intervalDays = 2.0
                nextState.dueDate = Calendar.current.date(byAdding: .day, value: 2, to: now)
                nextState.easeFactor = currentState.easeFactor
            case .easy:
                nextState.status = .review
                nextState.intervalDays = 4.0
                nextState.dueDate = Calendar.current.date(byAdding: .day, value: 4, to: now)
                nextState.easeFactor = currentState.easeFactor + 0.15
            }
        } else {
            // Existing review scheduling
            switch rating {
            case .again:
                nextState.status = .relearning
                nextState.intervalDays = 0.0
                nextState.dueDate = Calendar.current.date(byAdding: .minute, value: 10, to: now)
                nextState.easeFactor = max(1.3, currentState.easeFactor - 0.20)
            case .hard:
                nextState.status = .review
                let nextInterval = max(1.0, currentState.intervalDays * 1.2)
                nextState.intervalDays = nextInterval
                let roundedDays = Int(round(nextInterval))
                nextState.dueDate = Calendar.current.date(byAdding: .day, value: roundedDays, to: now)
                nextState.easeFactor = max(1.3, currentState.easeFactor - 0.15)
            case .good:
                nextState.status = .review
                let nextInterval = max(1.0, currentState.intervalDays * currentState.easeFactor)
                nextState.intervalDays = nextInterval
                let roundedDays = Int(round(nextInterval))
                nextState.dueDate = Calendar.current.date(byAdding: .day, value: roundedDays, to: now)
                nextState.easeFactor = currentState.easeFactor
            case .easy:
                nextState.status = .review
                let nextInterval = max(2.0, currentState.intervalDays * currentState.easeFactor * 1.6)
                nextState.intervalDays = nextInterval
                let roundedDays = Int(round(nextInterval))
                nextState.dueDate = Calendar.current.date(byAdding: .day, value: roundedDays, to: now)
                nextState.easeFactor = currentState.easeFactor + 0.15
            }
        }
        
        let record = SRSReviewRecord(
            id: UUID(),
            targetType: currentState.targetType,
            targetId: currentState.targetId,
            promptId: nil, // filled by caller if prompt id exists
            rating: rating,
            wasCorrect: nil, // filled by caller if graded in multiple choice
            reviewedAt: now,
            previousDueDate: prevDueDate,
            nextDueDate: nextState.dueDate,
            previousIntervalDays: prevIntervalDays,
            nextIntervalDays: nextState.intervalDays,
            previousEaseFactor: prevEaseFactor,
            nextEaseFactor: nextState.easeFactor,
            questionMode: nil // filled by caller if needed
        )
        
        return (nextState, record)
    }
}
