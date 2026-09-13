import SwiftUI

struct FlashCardsScreen: View {
    @Binding var selectedCategory: MainCategory
    
    @EnvironmentObject var studyDataService: StudyDataService
    @EnvironmentObject var userLibraryService: StudyUserLibraryService
    @EnvironmentObject var userVocabularyService: UserVocabularyService
    @EnvironmentObject var srsService: SRSService
    @EnvironmentObject private var settingsService: AppSettingsService
    @Environment(\.colorScheme) var colorScheme
    
    @StateObject private var viewModel = FlashCardsViewModel()
    @State private var activeSessionViewModel: FlashCardReviewSessionViewModel? = nil
    @State private var lastStartedSessionType: SRSSessionType? = nil
    
    // Debug tools states
    @State private var showingDebugPanel = false
    @State private var showingMarkDueAlert = false
    @State private var showingResetAllAlert = false
    
    private var repository: StudyDataRepository {
        StudyDataRepository(service: studyDataService)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Flash Cards 🌸")
                            .font(AppTheme.titleLarge)
                            .foregroundColor(colorScheme == .dark ? AppTheme.darkTextPrimary : AppTheme.textDark)
                        
                        Text("Review vocabulary words you saved from Vocabulary Library")
                            .font(AppTheme.fontRounded(size: 14))
                            .foregroundColor(colorScheme == .dark ? AppTheme.darkTextSecondary : AppTheme.textMuted)
                    }
                    Spacer()
                }
                .padding(.horizontal, 4)
                
                // SRS metrics header stats
                let summary = srsService.queueSummary()
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 16) {
                    MiniStatCard(title: "Due Today", value: "\(summary.dueCount)", icon: "clock.fill")
                    MiniStatCard(title: "New Words", value: "\(summary.newCount)", icon: "sparkles")
                    MiniStatCard(title: "Learning", value: "\(summary.learningCount)", icon: "book.fill")
                    MiniStatCard(title: "Saved Cards", value: "\(userLibraryService.state.flashcardTargets.count)", icon: "square.on.square.fill")
                    MiniStatCard(title: "Reviewed Today", value: "\(summary.reviewedTodayCount)", icon: "checkmark.seal.fill")
                    MiniStatCard(title: "Last Score", value: lastSessionScoreString, icon: "trophy.fill")
                }
                
                VStack(alignment: .leading, spacing: 14) {
                    Text("Select Review Source")
                        .font(AppTheme.titleSmall)
                        .foregroundColor(colorScheme == .dark ? AppTheme.darkTextPrimary : AppTheme.textDark)
                        .padding(.horizontal, 4)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(ReviewSource.allCases) { source in
                            let count = viewModel.cardCount(for: source, userLibrary: userLibraryService, repository: repository, userVocabularyService: userVocabularyService)
                            let promptCount = viewModel.promptCount(for: source, userLibrary: userLibraryService, repository: repository, userVocabularyService: userVocabularyService)
                            
                            FlashCardDeckCardView(
                                source: source,
                                cardCount: count,
                                promptCount: promptCount,
                                isSelected: viewModel.selectedSource == source,
                                action: {
                                    viewModel.selectedSource = source
                                }
                            )
                        }
                    }
                }
                
                // Get counts for current selected deck source
                let dueCount = viewModel.srsCardCount(for: viewModel.selectedSource, sessionType: .due, userLibrary: userLibraryService, repository: repository, userVocabularyService: userVocabularyService, srsService: srsService)
                
                let newCount = viewModel.srsCardCount(for: viewModel.selectedSource, sessionType: .new, userLibrary: userLibraryService, repository: repository, userVocabularyService: userVocabularyService, srsService: srsService)
                
                let allCount = viewModel.srsCardCount(for: viewModel.selectedSource, sessionType: .all, userLibrary: userLibraryService, repository: repository, userVocabularyService: userVocabularyService, srsService: srsService)
                
                if allCount == 0 {
                    FlashCardEmptyStateView(onNavigate: {
                        withAnimation {
                            selectedCategory = .vocabularyLibrary
                        }
                    })
                    .padding(.top, 8)
                } else {
                    FlashCardSetupOptionsView(options: $viewModel.reviewOptions, availableCardsCount: allCount)
                        .padding(.top, 8)
                    
                    VStack(spacing: 12) {
                        // 1. Due Review Button
                        Button(action: {
                            startReviewSession(sessionType: .due)
                        }) {
                            HStack {
                                Image(systemName: "alarm.fill")
                                Text(dueCount > 0 ? "Start Due Review (\(dueCount) Cards)" : "You're all caught up today.")
                            }
                            .font(AppTheme.fontRounded(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(dueCount > 0 ? viewModel.selectedSource.themeColor : Color.gray.opacity(0.4))
                            .cornerRadius(12)
                            .shadow(color: (dueCount > 0 ? viewModel.selectedSource.themeColor : Color.clear).opacity(0.2), radius: 4)
                        }
                        .disabled(dueCount == 0)
                        
                        // 2. Study New Cards Button
                        Button(action: {
                            startReviewSession(sessionType: .new)
                        }) {
                            HStack {
                                Image(systemName: "sparkles")
                                Text(newCount > 0 ? "Study New Cards (\(newCount) Cards)" : "No new cards waiting.")
                            }
                            .font(AppTheme.fontRounded(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(newCount > 0 ? AppTheme.sageGreen : Color.gray.opacity(0.4))
                            .cornerRadius(12)
                            .shadow(color: (newCount > 0 ? AppTheme.sageGreen : Color.clear).opacity(0.2), radius: 4)
                        }
                        .disabled(newCount == 0)
                        
                        // 3. Review All Saved Button
                        Button(action: {
                            startReviewSession(sessionType: .all)
                        }) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Review All Saved (\(min(viewModel.reviewOptions.cardLimit, allCount)) Cards)")
                            }
                            .font(AppTheme.fontRounded(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppTheme.darkNavy)
                            .cornerRadius(12)
                            .shadow(color: AppTheme.darkNavy.opacity(0.2), radius: 4)
                        }
                    }
                    .padding(.top, 8)
                }
                
                if settingsService.settings.showDeveloperDiagnostics {
                    // Debug / testing utilities accordion
                    VStack(alignment: .leading, spacing: 8) {
                        Button(action: {
                            withAnimation {
                                showingDebugPanel.toggle()
                            }
                        }) {
                            HStack {
                                Text("⚙️ DEVELOPER DIAGNOSTICS")
                                    .font(AppTheme.fontRounded(size: 10, weight: .bold))
                                    .foregroundColor(AppTheme.textMuted.opacity(0.7))
                                Spacer()
                                Image(systemName: showingDebugPanel ? "chevron.up" : "chevron.down")
                                    .font(.caption2)
                                    .foregroundColor(AppTheme.textMuted)
                            }
                        }
                        
                        if showingDebugPanel {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("SRS Stats: Due: \(summary.dueCount) | New: \(summary.newCount) | Learning: \(summary.learningCount) | Review: \(summary.reviewCount) | Total: \(summary.totalActiveCount) | Today: \(summary.reviewedTodayCount)")
                                    .font(AppTheme.fontRounded(size: 9))
                                    .foregroundColor(AppTheme.textMuted)
                                
                                HStack(spacing: 12) {
                                    Button(action: {
                                        showingMarkDueAlert = true
                                    }) {
                                        Text("Mark all cards due")
                                            .font(AppTheme.fontRounded(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(AppTheme.sakuraPink)
                                            .cornerRadius(6)
                                    }
                                    
                                    Button(action: {
                                        showingResetAllAlert = true
                                    }) {
                                        Text("Reset all SRS progress")
                                            .font(AppTheme.fontRounded(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.red.opacity(0.85))
                                            .cornerRadius(6)
                                    }
                                }
                            }
                            .padding(12)
                            .background(colorScheme == .dark ? AppTheme.darkCardActive : AppTheme.paperBeige.opacity(0.5))
                            .cornerRadius(10)
                            .transition(.opacity)
                        }
                    }
                    .padding(.top, 32)
                    .padding(.horizontal, 4)
                }
            }
            .padding(24)
        }
        .background((colorScheme == .dark ? AppTheme.darkBackground : AppTheme.paperBackground).ignoresSafeArea())
        .fullScreenCover(item: $activeSessionViewModel) { vm in
            FlashCardReviewScreen(viewModel: vm, onRestart: {
                self.activeSessionViewModel = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if let sType = self.lastStartedSessionType {
                        self.startReviewSession(sessionType: sType)
                    } else {
                        self.startReviewSession(sessionType: .all)
                    }
                }
            })
        }
        .alert("Mark all cards due?", isPresented: $showingMarkDueAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Mark Due", role: .destructive) {
                srsService.debugMarkAllDue()
            }
        } message: {
            Text("This will set all card next due dates to the past so they appear in your active due queue for testing.")
        }
        .alert("Reset all SRS progress?", isPresented: $showingResetAllAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                srsService.debugResetAllSRSProgress()
            }
        } message: {
            Text("This will permanently wipe all review count intervals, ease factors, and status statistics.")
        }
    }
    
    private func startReviewSession(sessionType: SRSSessionType) {
        let cards = viewModel.startSession(
            source: viewModel.selectedSource,
            sessionType: sessionType,
            userLibrary: userLibraryService,
            repository: repository,
            userVocabularyService: userVocabularyService,
            srsService: srsService
        )
        guard !cards.isEmpty else { return }
        
        self.lastStartedSessionType = sessionType
        
        self.activeSessionViewModel = FlashCardReviewSessionViewModel(
            source: viewModel.selectedSource,
            cards: cards,
            options: viewModel.reviewOptions,
            srsService: srsService
        )
    }
    
    private var lastSessionScoreString: String {
        if let score = srsService.lastSessionCorrectRate {
            return "\(Int(score * 100))%"
        }
        return "N/A"
    }
}

struct MiniStatCard: View {
    let title: String
    let value: String
    let icon: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(AppTheme.sakuraPink)
                Spacer()
            }
            
            Text(value)
                .font(AppTheme.fontRounded(size: 22, weight: .bold))
                .foregroundColor(colorScheme == .dark ? AppTheme.darkTextPrimary : AppTheme.textDark)
            
            Text(title)
                .font(AppTheme.fontRounded(size: 11, weight: .medium))
                .foregroundColor(colorScheme == .dark ? AppTheme.darkTextSecondary : AppTheme.textMuted)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(colorScheme == .dark ? AppTheme.darkCard : AppTheme.paperCard)
        .cornerRadius(AppTheme.cornerLG)
        .overlay(RoundedRectangle(cornerRadius: AppTheme.cornerLG).stroke(colorScheme == .dark ? AppTheme.darkBorder : AppTheme.borderLight, lineWidth: 1))
        .shadow(color: AppTheme.shadowColor, radius: 2, x: 0, y: 1)
    }
}

