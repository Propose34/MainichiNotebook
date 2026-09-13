import SwiftUI

struct SimpleVocabularyPacksScreen: View {
    @EnvironmentObject private var studyDataService: StudyDataService
    @EnvironmentObject private var studyUserLibraryService: StudyUserLibraryService
    @EnvironmentObject private var userVocabularyService: UserVocabularyService
    @EnvironmentObject private var progressService: SimpleVocabularyProgressService
    @EnvironmentObject private var settingsService: AppSettingsService
    @Environment(\.colorScheme) var colorScheme
    
    @StateObject private var viewModel: SimpleVocabularyPacksViewModel
    
    init(
        service: StudyDataService,
        userLibraryService: StudyUserLibraryService,
        userVocabularyService: UserVocabularyService,
        progressService: SimpleVocabularyProgressService
    ) {
        _viewModel = StateObject(wrappedValue: SimpleVocabularyPacksViewModel(
            service: service,
            userLibraryService: userLibraryService,
            userVocabularyService: userVocabularyService,
            progressService: progressService
        ))
    }
    
    // Fallback initializer
    init() {
        let dummyData = StudyDataService()
        let dummyUser = StudyUserLibraryService()
        let dummyUserVocab = UserVocabularyService()
        let dummyProgress = SimpleVocabularyProgressService()
        _viewModel = StateObject(wrappedValue: SimpleVocabularyPacksViewModel(
            service: dummyData,
            userLibraryService: dummyUser,
            userVocabularyService: dummyUserVocab,
            progressService: dummyProgress
        ))
    }
    
    private let sections = [
        "Starter Packs",
        "Daily Japanese",
        "Classroom Survival",
        "JLPT N5 Basics",
        "Review Ready"
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header Section
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Simple Vocabulary 🌸")
                            .font(AppTheme.titleLarge)
                            .foregroundColor(colorScheme == .dark ? AppTheme.darkTextPrimary : AppTheme.textDark)
                        
                        Text("Start with friendly word packs for daily Japanese")
                            .font(AppTheme.fontRounded(size: 14))
                            .foregroundColor(colorScheme == .dark ? AppTheme.darkTextSecondary : AppTheme.textMuted)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    
                    // Overall Stats Row
                    HStack(spacing: 12) {
                        MiniStatCard(title: "Words Seen", value: "\(viewModel.totalWordsLearned)", icon: "eye.fill")
                        MiniStatCard(title: "Saved Cards", value: "\(viewModel.totalSavedToFlashcards)", icon: "square.stack.3d.up.fill")
                        MiniStatCard(title: "Favorites", value: "\(viewModel.totalFavorites)", icon: "star.fill")
                    }
                    .padding(.horizontal, 24)
                    
                    // Pack Sections
                    ForEach(sections, id: \.self) { sectionName in
                        let sectionPacks = viewModel.packs.filter { $0.section == sectionName }
                        
                        if !sectionPacks.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(sectionName)
                                    .font(AppTheme.titleSmall)
                                    .foregroundColor(colorScheme == .dark ? AppTheme.darkTextPrimary : AppTheme.textDark)
                                    .padding(.horizontal, 24)
                                
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 16)], spacing: 16) {
                                    ForEach(sectionPacks) { pack in
                                        let wCount = viewModel.wordCount(for: pack)
                                        
                                        // Hide pack if no matching data and not user custom words
                                        if wCount > 0 || pack.id == "my-custom-words" {
                                            NavigationLink(destination: SimpleVocabularyPackDetailScreen(pack: pack)) {
                                                VocabularyPackCardView(
                                                    pack: pack,
                                                    wordCount: wCount,
                                                    savedCount: viewModel.savedToFlashcardsCount(for: pack),
                                                    favoriteCount: viewModel.favoriteCount(for: pack),
                                                    progress: viewModel.progress(for: pack)
                                                )
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                    }
                }
                .padding(.bottom, 24)
            }
            .background((colorScheme == .dark ? AppTheme.darkBackground : AppTheme.paperBackground).ignoresSafeArea())
        }
    }
}

// Wrapper for safe lookup of environment objects
struct SimpleVocabularyPacksScreen_Wrapper: View {
    @EnvironmentObject private var studyDataService: StudyDataService
    @EnvironmentObject private var studyUserLibraryService: StudyUserLibraryService
    @EnvironmentObject private var userVocabularyService: UserVocabularyService
    @EnvironmentObject private var progressService: SimpleVocabularyProgressService
    
    var body: some View {
        SimpleVocabularyPacksScreen(
            service: studyDataService,
            userLibraryService: studyUserLibraryService,
            userVocabularyService: userVocabularyService,
            progressService: progressService
        )
    }
}
