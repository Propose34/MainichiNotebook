import SwiftUI

struct MainAppShellView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    @EnvironmentObject private var settingsService: AppSettingsService
    @Environment(\.colorScheme) var colorScheme
    
    @State private var selectedCategory: MainCategory = .home
    @State private var selectedLectureBook: LectureBook? = nil
    
    @State private var showingSettingsSheet = false
    @State private var showingThemeSheet = false
    @State private var isSidebarCollapsed = false
    
    var body: some View {
        if sizeClass == .compact {
            // iPhone Responsive Stack Layout
            NavigationStack {
                IPhoneMenuScreen(selectedCategory: $selectedCategory, selectedLectureBook: $selectedLectureBook)
                    .sheet(isPresented: $showingSettingsSheet) {
                        AppSettingsScreen()
                    }
                    .sheet(isPresented: $showingThemeSheet) {
                        AppSettingsScreen()
                    }
            }
        } else {
            // iPad / Mac Split-Screen Layout
            HStack(spacing: 0) {
                SidebarView(
                    selectedCategory: $selectedCategory,
                    isCollapsed: $isSidebarCollapsed,
                    onSettingTap: { showingSettingsSheet = true },
                    onThemeTap: { showingThemeSheet = true }
                )
                
                Divider()
                
                // Right main working screen workspace
                Group {
                    switch selectedCategory {
                    case .home:
                        HomeDashboardScreen(selectedCategory: $selectedCategory, selectedLectureBook: $selectedLectureBook)
                    case .lectures:
                        LecturesModuleWrapper(selectedBook: $selectedLectureBook, isSidebarCollapsed: $isSidebarCollapsed)
                    case .vocabularyLibrary:
                        VocabularyLibraryScreen_Wrapper()
                    case .writingPractice:
                        WritingPracticeScreen_Wrapper()
                    case .simpleVocabulary:
                        SimpleVocabularyPacksScreen_Wrapper()
                    case .dailySummary:
                        DailySummaryScreen_Wrapper()
                    case .flashCards:
                        FlashCardsScreen(selectedCategory: $selectedCategory)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(colorScheme == .dark ? AppTheme.darkBackground : AppTheme.paperBackground)
            .onChange(of: selectedLectureBook) { book in
                withAnimation(.easeInOut(duration: 0.25)) {
                    if let book = book {
                        isSidebarCollapsed = true
                        
                        // Update recent book IDs
                        var recents = UserDefaults.standard.stringArray(forKey: "com.mainichi.recentBookIds") ?? []
                        let idStr = book.id.uuidString
                        recents.removeAll { $0 == idStr }
                        recents.insert(idStr, at: 0)
                        if recents.count > 5 {
                            recents = Array(recents.prefix(5))
                        }
                        UserDefaults.standard.set(recents, forKey: "com.mainichi.recentBookIds")
                    } else {
                        isSidebarCollapsed = false
                    }
                }
            }
            .sheet(isPresented: $showingSettingsSheet) {
                AppSettingsScreen()
            }
            .sheet(isPresented: $showingThemeSheet) {
                AppSettingsScreen()
            }
        }
    }
}

// Wrapper for lectures navigation to support going into the Editor and returning
struct LecturesModuleWrapper: View {
    @Binding var selectedBook: LectureBook?
    @Binding var isSidebarCollapsed: Bool
    
    var body: some View {
        if let book = selectedBook {
            LectureBookEditorScreen(book: book, isSidebarCollapsed: $isSidebarCollapsed, onBack: { selectedBook = nil })
        } else {
            LecturesOverviewScreen(selectedBook: $selectedBook)
        }
    }
}

// iPhone Menu Screen View
struct IPhoneMenuScreen: View {
    @Binding var selectedCategory: MainCategory
    @Binding var selectedLectureBook: LectureBook?
    
    @EnvironmentObject private var dailySummaryService: DailySummaryService
    @EnvironmentObject private var studyDataService: StudyDataService
    @EnvironmentObject private var userVocabularyService: UserVocabularyService
    @Environment(\.colorScheme) var colorScheme
    
    private var streakDays: Int {
        dailySummaryService.computeStreak()
    }
    
    private var todayProgress: String {
        let key = dailySummaryService.makeDateKey(from: Date())
        let entry = dailySummaryService.getEntry(forDateKey: key)
        let completedCount = entry.completedTaskIds.filter { ["add-one-note", "learn-5-words", "practice-writing", "review-flashcards"].contains($0) }.count
        let pct = Int(Double(completedCount) / 4.0 * 100)
        return "\(pct)%"
    }
    
    private var totalWordsCount: Int {
        studyDataService.vocabularyItems.count + userVocabularyService.userItems.count
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header Logo
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .stroke(AppTheme.sakuraPink.opacity(0.4), lineWidth: 1.5)
                            .frame(width: 64, height: 64)
                        
                        Circle()
                            .stroke(AppTheme.sakuraPink.opacity(0.6), lineWidth: 0.8)
                            .frame(width: 58, height: 58)
                        
                        Image(systemName: "flower.turtle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(AppTheme.sakuraPink)
                    }
                    .padding(.top, 16)
                    
                    Text("毎日ノート")
                        .font(AppTheme.fontSerif(size: 20, weight: .bold))
                        .foregroundColor(colorScheme == .dark ? AppTheme.darkTextPrimary : AppTheme.textDark)
                        .tracking(2)
                    
                    Text("Japanese Study Hub")
                        .font(AppTheme.fontRounded(size: 11))
                        .foregroundColor(colorScheme == .dark ? AppTheme.darkTextSecondary : AppTheme.textMuted)
                }
                
                // Quick Dashboard mini stats card
                HStack(spacing: 12) {
                    MiniStatBadge(title: "Streak", val: "\(streakDays) Days", icon: "sparkles")
                    MiniStatBadge(title: "Today", val: todayProgress, icon: "checklist")
                    MiniStatBadge(title: "Words", val: "\(totalWordsCount)", icon: "character.book.closed")
                }
                .padding(.horizontal, 24)
                
                // Categories list for iPhone push navigation
                VStack(spacing: 10) {
                    ForEach(MainCategory.allCases) { category in
                        NavigationLink(destination: destinationView(for: category)) {
                            HStack(spacing: 14) {
                                if category == .simpleVocabulary {
                                    Text("あ")
                                        .font(AppTheme.fontSerif(size: 12, weight: .bold))
                                        .frame(width: 32, height: 32)
                                        .background(colorScheme == .dark ? AppTheme.darkCardActive : AppTheme.sakuraPinkLight)
                                        .foregroundColor(AppTheme.sakuraPink)
                                        .cornerRadius(8)
                                } else {
                                    Image(systemName: category.iconName)
                                        .font(.system(size: 14))
                                        .foregroundColor(AppTheme.sakuraPink)
                                        .frame(width: 32, height: 32)
                                        .background(colorScheme == .dark ? AppTheme.darkCardActive : AppTheme.sakuraPinkLight)
                                        .clipShape(Circle())
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(category.rawValue)
                                        .font(AppTheme.fontRounded(size: 15, weight: .bold))
                                        .foregroundColor(colorScheme == .dark ? AppTheme.darkTextPrimary : AppTheme.textDark)
                                    
                                    if !category.thaiPlaceholderTitle.isEmpty {
                                        Text(category.thaiPlaceholderTitle)
                                            .font(AppTheme.fontRounded(size: 11))
                                            .foregroundColor(colorScheme == .dark ? AppTheme.darkTextSecondary : AppTheme.textMuted)
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(colorScheme == .dark ? AppTheme.darkTextSecondary.opacity(0.4) : AppTheme.textMuted.opacity(0.4))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(colorScheme == .dark ? AppTheme.darkCard : AppTheme.paperCard)
                            .cornerRadius(12)
                            .shadow(color: AppTheme.shadowColor, radius: 4)
                        }
                        .buttonStyle(SpringPressButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
                
                // Bottom consistency quote
                VStack(alignment: .leading, spacing: 4) {
                    Text("継続は力なり。")
                        .font(AppTheme.fontSerif(size: 13, weight: .bold))
                        .foregroundColor(AppTheme.sakuraPink)
                    Text("Consistency is power.")
                        .font(AppTheme.fontRounded(size: 11))
                        .foregroundColor(colorScheme == .dark ? AppTheme.darkTextSecondary : AppTheme.textDark.opacity(0.8))
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(colorScheme == .dark ? AppTheme.darkCardActive.opacity(0.4) : AppTheme.paperBeige.opacity(0.2))
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .background(colorScheme == .dark ? AppTheme.darkBackground : AppTheme.paperBackground)
        .navigationTitle("Mainichi Notebook")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    private func destinationView(for category: MainCategory) -> some View {
        switch category {
        case .home:
            HomeDashboardScreen(selectedCategory: $selectedCategory, selectedLectureBook: $selectedLectureBook)
                .navigationTitle("Home")
                .navigationBarTitleDisplayMode(.inline)
        case .lectures:
            IPhoneLecturesWrapper()
        case .vocabularyLibrary:
            VocabularyLibraryScreen_Wrapper()
                .navigationTitle("Vocabulary")
                .navigationBarTitleDisplayMode(.inline)
        case .writingPractice:
            WritingPracticeScreen_Wrapper()
                .navigationTitle("Writing Practice")
                .navigationBarTitleDisplayMode(.inline)
        case .simpleVocabulary:
            SimpleVocabularyPacksScreen_Wrapper()
                .navigationTitle("Simple Vocabulary")
                .navigationBarTitleDisplayMode(.inline)
        case .dailySummary:
            DailySummaryScreen_Wrapper()
                .navigationTitle("Daily Summary")
                .navigationBarTitleDisplayMode(.inline)
        case .flashCards:
            FlashCardsScreen(selectedCategory: $selectedCategory)
                .navigationTitle("Flash Cards")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// iPhone lectures helper wrapper to manage navigation inside NavigationStack
struct IPhoneLecturesWrapper: View {
    @State private var selectedBook: LectureBook? = nil
    @State private var isSidebarCollapsed = false
    
    var body: some View {
        if let book = selectedBook {
            LectureBookEditorScreen(book: book, isSidebarCollapsed: $isSidebarCollapsed, onBack: { selectedBook = nil })
                .navigationTitle(book.title)
                .navigationBarTitleDisplayMode(.inline)
        } else {
            LecturesOverviewScreen(selectedBook: $selectedBook)
                .navigationTitle("Lectures")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// Mini Stat Badge for iPhone Header
struct MiniStatBadge: View {
    let title: String
    let val: String
    let icon: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(AppTheme.sakuraPink)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(AppTheme.fontRounded(size: 9))
                    .foregroundColor(colorScheme == .dark ? AppTheme.darkTextSecondary : AppTheme.textMuted)
                Text(val)
                    .font(AppTheme.fontRounded(size: 11, weight: .bold))
                    .foregroundColor(colorScheme == .dark ? AppTheme.darkTextPrimary : AppTheme.textDark)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(colorScheme == .dark ? AppTheme.darkCard : AppTheme.paperCard)
        .cornerRadius(10)
        .shadow(color: AppTheme.shadowColor, radius: 2)
    }
}
