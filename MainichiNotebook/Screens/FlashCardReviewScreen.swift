import SwiftUI

struct FlashCardReviewScreen: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.horizontalSizeClass) var sizeClass
    
    @EnvironmentObject var srsService: SRSService
    
    @ObservedObject var viewModel: FlashCardReviewSessionViewModel
    let onRestart: () -> Void
    
    @State private var showingQuitAlert = false
    
    var body: some View {
        ZStack {
            AppTheme.paperBackground.ignoresSafeArea()
            
            DotGridPaperView()
                .opacity(0.15)
                .ignoresSafeArea()
            
            if viewModel.isFinished {
                FlashCardSessionSummaryView(
                    source: viewModel.source,
                    correctCount: viewModel.correctCount,
                    incorrectCount: viewModel.incorrectCount,
                    reviewedCards: viewModel.reviewedCards,
                    sessionRecords: viewModel.sessionRecords,
                    onRestart: {
                        onRestart()
                    },
                    onClose: {
                        dismiss()
                    }
                )
            } else {
                VStack(spacing: 0) {
                    VStack(spacing: 16) {
                        HStack {
                            Button(action: {
                                showingQuitAlert = true
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "chevron.left")
                                    Text("Quit")
                                }
                                .font(AppTheme.fontRounded(size: 15, weight: .bold))
                                .foregroundColor(AppTheme.textDark)
                            }
                            .alert("Quit Study Session?", isPresented: $showingQuitAlert) {
                                Button("Cancel", role: .cancel) { }
                                Button("Quit", role: .destructive) {
                                    dismiss()
                                }
                            } message: {
                                Text("Your current progress will not be completed, but saved history records will remain logged.")
                            }
                            
                            Spacer()
                            
                            Text(viewModel.source.rawValue)
                                .font(AppTheme.fontSerif(size: 16, weight: .bold))
                                .foregroundColor(AppTheme.textDark)
                            
                            Spacer()
                            
                            Text("\(viewModel.currentIndex + 1) / \(viewModel.cards.count)")
                                .font(AppTheme.fontRounded(size: 14, weight: .bold))
                                .foregroundColor(AppTheme.textMuted)
                        }
                        
                        FlashCardProgressBarView(
                            progress: viewModel.progress,
                            color: viewModel.source.themeColor,
                            totalCount: viewModel.cards.count
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                    .background(AppTheme.paperBackground)
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            if let card = viewModel.currentCard {
                                FlashCardReviewCardView(
                                    card: card,
                                    isAnswerRevealed: viewModel.isAnswerRevealed,
                                    selectedChoice: viewModel.selectedChoice,
                                    isCorrect: viewModel.isCorrect,
                                    enablePronunciation: viewModel.options.enablePronunciation,
                                    showExampleAfterAnswer: viewModel.options.showExampleAfterAnswer,
                                    onSelectChoice: { choice in
                                        viewModel.selectChoice(choice)
                                    },
                                    onRevealAnswer: {
                                        viewModel.revealAnswer()
                                    }
                                )
                                .frame(maxWidth: sizeClass == .compact ? .infinity : 550)
                                
                                if let st = srsService.state(for: card.targetType, targetId: card.targetId) {
                                    HStack(spacing: 12) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "clock.badge")
                                            Text(st.status == .new ? "New Word" : "Status: \(st.status.label)")
                                        }
                                        .font(AppTheme.fontRounded(size: 11, weight: .semibold))
                                        .foregroundColor(AppTheme.textMuted)
                                        
                                        if st.status != .new {
                                            Text("•")
                                                .font(.caption2)
                                                .foregroundColor(AppTheme.borderLight)
                                            
                                            let intervalInt = Int(round(st.intervalDays))
                                            Text("Interval: \(intervalInt) \(intervalInt == 1 ? "day" : "days")")
                                                .font(AppTheme.fontRounded(size: 11))
                                                .foregroundColor(AppTheme.textMuted)
                                            
                                            Text("•")
                                                .font(.caption2)
                                                .foregroundColor(AppTheme.borderLight)
                                            
                                            Text("Reviews: \(st.reviewCount)")
                                                .font(AppTheme.fontRounded(size: 11))
                                                .foregroundColor(AppTheme.textMuted)
                                            
                                            if let next = st.dueDate {
                                                Text("•")
                                                    .font(.caption2)
                                                    .foregroundColor(AppTheme.borderLight)
                                                
                                                let formatter: RelativeDateTimeFormatter = {
                                                    let f = RelativeDateTimeFormatter()
                                                    f.unitsStyle = .full
                                                    return f
                                                }()
                                                let nextString = formatter.localizedString(for: next, relativeTo: Date())
                                                Text("Next: \(nextString)")
                                                    .font(AppTheme.fontRounded(size: 11))
                                                    .foregroundColor(AppTheme.textMuted)
                                            }
                                        }
                                    }
                                    .padding(.vertical, 4)
                                    .frame(maxWidth: sizeClass == .compact ? .infinity : 550)
                                }
                            }
                            
                            VStack(spacing: 12) {
                                if viewModel.isAnswerRevealed {
                                    Text("How was this card?")
                                        .font(AppTheme.fontRounded(size: 12, weight: .medium))
                                        .foregroundColor(AppTheme.textMuted)
                                    
                                    HStack(spacing: 12) {
                                        RatingButton(rating: .again, color: AppTheme.sakuraPink) {
                                            viewModel.rateCard(.again)
                                        }
                                        RatingButton(rating: .hard, color: AppTheme.woodCozy) {
                                            viewModel.rateCard(.hard)
                                        }
                                        RatingButton(rating: .good, color: AppTheme.sageGreen) {
                                            viewModel.rateCard(.good)
                                        }
                                        RatingButton(rating: .easy, color: AppTheme.darkNavy) {
                                            viewModel.rateCard(.easy)
                                        }
                                    }
                                    
                                    Button(action: {
                                        viewModel.nextCardWithoutRating()
                                    }) {
                                        Text("Skip rating & Next")
                                            .font(AppTheme.fontRounded(size: 13, weight: .medium))
                                            .foregroundColor(AppTheme.textMuted)
                                            .underline()
                                    }
                                    .padding(.top, 6)
                                } else {
                                    Text(viewModel.currentCard?.isMultipleChoice == true ? "Choose the correct translation option above" : "Tap 'Reveal Answer' to check pronunciation and details")
                                        .font(AppTheme.fontRounded(size: 12))
                                        .foregroundColor(AppTheme.textMuted)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 32)
                                }
                            }
                            .padding(.bottom, 32)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 12)
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
}

struct RatingButton: View {
    let rating: SRSRating
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(rating.rawValue.capitalized)
                    .font(AppTheme.fontRounded(size: 14, weight: .bold))
                    .foregroundColor(color)
                
                Text(rating.labelTh)
                    .font(AppTheme.fontRounded(size: 10))
                    .foregroundColor(AppTheme.textMuted)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(AppTheme.paperCard)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.borderLight, lineWidth: 1))
            .shadow(color: AppTheme.shadowColor, radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
