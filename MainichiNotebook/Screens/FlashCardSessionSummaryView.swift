import SwiftUI

struct FlashCardSessionSummaryView: View {
    let source: ReviewSource
    let correctCount: Int
    let incorrectCount: Int
    let reviewedCards: [ReviewCard]
    let sessionRecords: [SRSReviewRecord]
    let onRestart: () -> Void
    let onClose: () -> Void
    
    var accuracy: Double {
        let total = correctCount + incorrectCount
        return total > 0 ? Double(correctCount) / Double(total) : 1.0
    }
    
    var ratingCounts: (again: Int, hard: Int, good: Int, easy: Int) {
        var again = 0
        var hard = 0
        var good = 0
        var easy = 0
        for rec in sessionRecords {
            switch rec.rating {
            case .again: again += 1
            case .hard: hard += 1
            case .good: good += 1
            case .easy: easy += 1
            }
        }
        return (again, hard, good, easy)
    }
    
    func nextDuePreview(for cardId: String) -> String {
        guard let record = sessionRecords.first(where: { $0.targetId == cardId }) else {
            return ""
        }
        if record.rating == .again {
            return "อีกครั้งใน 10 นาที"
        } else if let days = record.nextIntervalDays {
            let rounded = Int(round(days))
            if rounded == 0 {
                return "อีกครั้งวันนี้"
            }
            return "อีกครั้งใน \(rounded) วัน"
        }
        return ""
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.sakuraPinkLight)
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 36))
                            .foregroundColor(AppTheme.sakuraPink)
                    }
                    
                    VStack(spacing: 4) {
                        Text("Session Complete! 🎉")
                            .font(AppTheme.fontSerif(size: 24, weight: .bold))
                            .foregroundColor(AppTheme.textDark)
                        
                        Text("Source: \(source.rawValue)")
                            .font(AppTheme.fontRounded(size: 13))
                            .foregroundColor(AppTheme.textMuted)
                    }
                    
                    HStack(spacing: 24) {
                        SummaryStatItem(title: "Accuracy", value: "\(Int(accuracy * 100))%", color: accuracyColor)
                        
                        Divider()
                            .frame(height: 40)
                            .background(AppTheme.borderLight)
                        
                        SummaryStatItem(title: "Correct", value: "\(correctCount)", color: AppTheme.sageGreen)
                        
                        Divider()
                            .frame(height: 40)
                            .background(AppTheme.borderLight)
                        
                        SummaryStatItem(title: "Total Cards", value: "\(reviewedCards.count)", color: AppTheme.textDark)
                    }
                    .padding(.vertical, 16)
                }
                .padding(24)
                .frame(maxWidth: .infinity)
                .background(AppTheme.paperCard)
                .cornerRadius(20)
                .shadow(color: AppTheme.shadowColor, radius: 8, x: 0, y: 4)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.borderLight, lineWidth: 1))
                
                // Ratings Stats Grid
                let counts = ratingCounts
                VStack(alignment: .leading, spacing: 10) {
                    Text("Rating Outcomes")
                        .font(AppTheme.fontSerif(size: 16, weight: .bold))
                        .foregroundColor(AppTheme.textDark)
                        .padding(.horizontal, 4)
                    
                    HStack(spacing: 12) {
                        RatingStatBadge(label: "Again", count: counts.again, color: AppTheme.sakuraPink)
                        RatingStatBadge(label: "Hard", count: counts.hard, color: AppTheme.woodCozy)
                        RatingStatBadge(label: "Good", count: counts.good, color: AppTheme.sageGreen)
                        RatingStatBadge(label: "Easy", count: counts.easy, color: AppTheme.darkNavy)
                    }
                }
                
                VStack(alignment: .leading, spacing: 14) {
                    Text("Reviewed Words")
                        .font(AppTheme.fontSerif(size: 18, weight: .bold))
                        .foregroundColor(AppTheme.textDark)
                        .padding(.horizontal, 4)
                    
                    VStack(spacing: 10) {
                        ForEach(reviewedCards) { card in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 6) {
                                        Text(card.vocabularyItem.japanese)
                                            .font(AppTheme.fontSerif(size: 16, weight: .bold))
                                            .foregroundColor(AppTheme.textDark)
                                        Text("(\(card.vocabularyItem.reading))")
                                            .font(AppTheme.fontRounded(size: 13))
                                            .foregroundColor(AppTheme.textMuted)
                                    }
                                    
                                    HStack(spacing: 8) {
                                        Text(card.vocabularyItem.meaningTh)
                                            .font(AppTheme.fontRounded(size: 13))
                                            .foregroundColor(AppTheme.textMuted)
                                        
                                        let preview = nextDuePreview(for: card.targetId)
                                        if !preview.isEmpty {
                                            Text("•")
                                                .font(.caption2)
                                                .foregroundColor(AppTheme.borderLight)
                                            
                                            Text(preview)
                                                .font(AppTheme.fontRounded(size: 11, weight: .bold))
                                                .foregroundColor(AppTheme.sakuraPink)
                                        }
                                    }
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    let _ = JapanesePronunciationService.shared.speakVocabulary(card.vocabularyItem)
                                }) {
                                    Image(systemName: "speaker.wave.2.fill")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.sakuraPink)
                                        .padding(6)
                                        .background(AppTheme.sakuraPinkLight)
                                        .clipShape(Circle())
                                }
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 14)
                            .background(AppTheme.paperCard)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.borderLight, lineWidth: 1))
                        }
                    }
                }
                
                VStack(spacing: 12) {
                    Button(action: onRestart) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Review Again")
                        }
                        .font(AppTheme.fontRounded(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.sakuraPink)
                        .cornerRadius(12)
                        .shadow(color: AppTheme.sakuraPink.opacity(0.3), radius: 6, x: 0, y: 3)
                    }
                    
                    Button(action: onClose) {
                        Text("Close Session")
                            .font(AppTheme.fontRounded(size: 16, weight: .bold))
                            .foregroundColor(AppTheme.textDark)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppTheme.paperBeige)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.borderLight, lineWidth: 1))
                    }
                }
            }
            .padding(24)
        }
        .background(AppTheme.paperBackground.ignoresSafeArea())
    }
    
    private var accuracyColor: Color {
        if accuracy >= 0.8 { return AppTheme.sageGreen }
        if accuracy >= 0.5 { return AppTheme.woodCozy }
        return AppTheme.sakuraPink
    }
}

struct RatingStatBadge: View {
    let label: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(AppTheme.fontRounded(size: 11, weight: .bold))
                .foregroundColor(color)
            
            Text("\(count)")
                .font(AppTheme.fontRounded(size: 15, weight: .bold))
                .foregroundColor(AppTheme.textDark)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(AppTheme.paperCard)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.borderLight, lineWidth: 1))
    }
}

struct SummaryStatItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(AppTheme.fontRounded(size: 20, weight: .bold))
                .foregroundColor(color)
            
            Text(title)
                .font(AppTheme.fontRounded(size: 11))
                .foregroundColor(AppTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
    }
}

