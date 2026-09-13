import SwiftUI

struct WritingPracticeScreen: View {
    @StateObject private var viewModel: WritingPracticeViewModel
    @EnvironmentObject private var progressService: WritingPracticeProgressService
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var activeCharacter: WritingPracticeCharacter? = nil
    
    init(service: StudyDataService) {
        _viewModel = StateObject(wrappedValue: WritingPracticeViewModel(service: service))
    }
    
    // Fallback init
    init() {
        let dummy = StudyDataService()
        _viewModel = StateObject(wrappedValue: WritingPracticeViewModel(service: dummy))
    }
    
    var body: some View {
        Group {
            if sizeClass == .compact {
                // iPhone Layout
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            headerSection
                            
                            WritingPracticeGuideCard() // Collapsible beginner guide
                            
                            WritingModeSegmentedControl(selectedMode: $viewModel.selectedMode)
                            
                            statsSection
                            
                            searchBar
                            
                            characterGrid
                        }
                        .padding(20)
                    }
                }
                .background(colorScheme == .dark ? AppTheme.darkBackground : AppTheme.paperBackground)
                .navigationDestination(item: $activeCharacter) { character in
                    WritingPracticeDetailScreen(character: character)
                        .navigationTitle(character.character)
                        .navigationBarTitleDisplayMode(.inline)
                }
            } else {
                // iPad / Mac Split-Screen Layout
                HStack(spacing: 0) {
                    // Left Column (Grid / Search / Stats)
                    VStack(alignment: .leading, spacing: 16) {
                        headerSection
                        
                        WritingPracticeGuideCard() // Collapsible beginner guide
                        
                        WritingModeSegmentedControl(selectedMode: $viewModel.selectedMode)
                        
                        statsSection
                        
                        searchBar
                        
                        characterGrid
                    }
                    .padding(24)
                    .frame(width: 320) // Narrowed down left grid to give more width to details canvas
                    .background(colorScheme == .dark ? AppTheme.darkBackground : AppTheme.paperBackground)
                    
                    Divider()
                    
                    // Right Workspace Panel
                    Group {
                        if let selectedChar = viewModel.selectedCharacter {
                            WritingPracticeDetailScreen(character: selectedChar, isEmbedded: true)
                                .id(selectedChar.id) // Reload view context when character changes
                        } else {
                            WritingPracticeEmptyStateView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .background(colorScheme == .dark ? AppTheme.darkBackground : AppTheme.paperBackground)
            }
        }
    }
    
    // MARK: - Subviews
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Writing Practice")
                .font(AppTheme.titleLarge)
                .foregroundColor(colorScheme == .dark ? AppTheme.darkTextPrimary : AppTheme.textDark)
            
            Text("Practice kana and kanji with guided writing sheets")
                .font(AppTheme.fontRounded(size: 13))
                .foregroundColor(colorScheme == .dark ? AppTheme.darkTextSecondary : AppTheme.textMuted)
        }
    }
    
    private var statsSection: some View {
        WritingPracticeStatsView(
            mode: viewModel.selectedMode,
            totalCount: viewModel.totalCountForCurrentMode,
            practicedCount: progressService.modePracticedCount(mode: viewModel.selectedMode),
            todayCount: progressService.todayPracticedCount(),
            lastChar: lastPracticedCharSymbol
        )
    }
    
    private var lastPracticedCharSymbol: String? {
        let modeProgress = progressService.progressItems.values.filter { $0.mode == viewModel.selectedMode && $0.lastPracticedAt != nil }
        guard let latest = modeProgress.max(by: { ($0.lastPracticedAt ?? Date.distantPast) < ($1.lastPracticedAt ?? Date.distantPast) }) else {
            return nil
        }
        return viewModel.character(forId: latest.characterId)?.character
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(colorScheme == .dark ? AppTheme.darkTextSecondary.opacity(0.6) : AppTheme.textMuted.opacity(0.6))
            
            TextField(viewModel.selectedMode == .kanji ? "Search character, meaning, reading..." : "Search...", text: $viewModel.searchText)
                .font(AppTheme.fontRounded(size: 14))
                .foregroundColor(colorScheme == .dark ? AppTheme.darkTextPrimary : AppTheme.textDark)
                .autocorrectionDisabled()
            
            if !viewModel.searchText.isEmpty {
                Button(action: { viewModel.searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(colorScheme == .dark ? AppTheme.darkTextSecondary.opacity(0.6) : AppTheme.textMuted.opacity(0.6))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background((colorScheme == .dark ? AppTheme.darkCardActive : AppTheme.paperBeige).opacity(0.6))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(colorScheme == .dark ? AppTheme.darkBorder : AppTheme.borderLight, lineWidth: 1)
        )
    }
    
    private var characterGrid: some View {
        Group {
            let list = viewModel.filteredCharacters
            if list.isEmpty {
                VStack(spacing: 8) {
                    Text("No results found")
                        .font(AppTheme.fontRounded(size: 14, weight: .bold))
                        .foregroundColor(colorScheme == .dark ? AppTheme.darkTextSecondary : AppTheme.textMuted)
                    Text("Try looking for another pronunciation or meaning.")
                        .font(AppTheme.fontRounded(size: 12))
                        .foregroundColor(colorScheme == .dark ? AppTheme.darkTextSecondary.opacity(0.8) : AppTheme.textMuted.opacity(0.8))
                }
                .frame(maxWidth: .infinity, minHeight: 180)
            } else {
                CharacterGridView(
                    characters: list,
                    selectedId: viewModel.selectedCharacterId,
                    progressService: progressService,
                    onSelect: { char in
                        if sizeClass == .compact {
                            activeCharacter = char
                        } else {
                            viewModel.selectedCharacterId = char.id
                        }
                    }
                )
            }
        }
    }
}

// Wrapper view to handle safe inject lookup of StudyDataService
struct WritingPracticeScreen_Wrapper: View {
    @EnvironmentObject private var studyDataService: StudyDataService
    
    var body: some View {
        WritingPracticeScreen(service: studyDataService)
    }
}
