import SwiftUI

struct VocabularyLibraryScreen: View {
    @EnvironmentObject private var studyDataService: StudyDataService
    @EnvironmentObject private var studyUserLibraryService: StudyUserLibraryService
    @EnvironmentObject private var userVocabularyService: UserVocabularyService
    @EnvironmentObject private var settingsService: AppSettingsService
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var sizeClass
    
    @StateObject private var viewModel: VocabularyLibraryViewModel
    @State private var showingAddWordSheet: Bool = false
    
    // Initializer binding the view model after environment object injection is complete
    init(service: StudyDataService, userLibraryService: StudyUserLibraryService, userVocabularyService: UserVocabularyService) {
        _viewModel = StateObject(wrappedValue: VocabularyLibraryViewModel(service: service, userLibraryService: userLibraryService, userVocabularyService: userVocabularyService))
    }
    
    // Fallback init when environment objects are not yet fully available
    init() {
        let dummyData = StudyDataService()
        let dummyUser = StudyUserLibraryService()
        let dummyUserVocab = UserVocabularyService()
        _viewModel = StateObject(wrappedValue: VocabularyLibraryViewModel(service: dummyData, userLibraryService: dummyUser, userVocabularyService: dummyUserVocab))
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Main left/middle browsing content area
            VStack(alignment: .leading, spacing: 12) {
                // Header Title Section
                headerSection
                
                // Collection Scopes Chips (All, Favorites, My List, Flash Cards)
                scopeChipsBar
                
                // Controls Row (Search, Level Filter, Sort, Grid/List layout toggle)
                controlsRow
                
                // Category Scrollable Chips
                categoryChipsBar
                
                // Browser body content (Grid / List / Empty State)
                contentArea
                
                // Collapsible Developer Status View at the bottom
                developerAccordion
            }
            .frame(maxWidth: .infinity)
            
            // iPad Right Detail Panel
            if sizeClass == .regular {
                Divider()
                
                VocabularyDetailPanelView(item: viewModel.selectedItem)
                    .frame(width: 320)
                    .background((colorScheme == .dark ? AppTheme.darkCardActive : AppTheme.paperBeige).opacity(0.15))
            }
        }
        .background((colorScheme == .dark ? AppTheme.darkBackground : AppTheme.paperBackground).ignoresSafeArea())
        .sheet(isPresented: $showingAddWordSheet) {
            AddEditWordSheet(wordToEdit: nil)
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Vocabulary Library 🌸")
                    .font(AppTheme.fontSerif(size: 26, weight: .bold))
                    .foregroundColor(AppTheme.textDark)
                
                Spacer()
                
                Button(action: {
                    showingAddWordSheet = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                        Text("Add Word")
                            .font(AppTheme.fontRounded(size: 13, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AppTheme.sakuraPink)
                    .cornerRadius(8)
                    .shadow(color: AppTheme.sakuraPink.opacity(0.15), radius: 3, x: 0, y: 2)
                }
            }
            
            HStack {
                Text("Your personal Japanese vocabulary collection")
                    .font(AppTheme.fontRounded(size: 13))
                    .foregroundColor(AppTheme.textMuted)
                
                Spacer()
                
                Text("\(viewModel.filteredVocabularyItems.count) words shown")
                    .font(AppTheme.fontRounded(size: 11, weight: .bold))
                    .foregroundColor(AppTheme.sakuraPink)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(AppTheme.sakuraPinkLight)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }
    
    // MARK: - Collection Scopes Chips (All, Favorites, My List, Flash Cards)
    private var scopeChipsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(VocabularyScope.allCases) { scope in
                    scopeChip(scope: scope)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 2)
        }
    }
    
    private func scopeChip(scope: VocabularyScope) -> some View {
        let isSelected = viewModel.selectedScope == scope
        let count = scopeCount(for: scope)
        
        return Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.selectedScope = scope
                // iPad auto-select first item in scope
                if sizeClass == .regular {
                    viewModel.selectedItemId = viewModel.filteredVocabularyItems.first?.id
                }
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: scope.icon)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(isSelected ? .white : (scope == .favorites ? Color.orange : AppTheme.sakuraPink))
                
                Text(scope.rawValue)
                    .font(AppTheme.fontRounded(size: 12, weight: .bold))
                
                Text("\(count)")
                    .font(AppTheme.fontRounded(size: 10, weight: .bold))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1.5)
                    .background(isSelected ? Color.white.opacity(0.2) : AppTheme.paperBeige)
                    .foregroundColor(isSelected ? .white : AppTheme.textDark)
                    .cornerRadius(6)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? AppTheme.darkNavy : AppTheme.paperCard)
            .foregroundColor(isSelected ? .white : AppTheme.textDark)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.clear : AppTheme.borderLight, lineWidth: 1)
            )
            .shadow(color: AppTheme.shadowColor, radius: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func scopeCount(for scope: VocabularyScope) -> Int {
        switch scope {
        case .all:
            return studyDataService.vocabularyItems.count + userVocabularyService.userItems.count
        case .seed:
            return studyDataService.vocabularyItems.count
        case .myWords:
            return userVocabularyService.userItems.count
        case .favorites:
            return studyUserLibraryService.state.favoriteTargets.count
        case .myList:
            return studyUserLibraryService.state.myListTargets.count
        case .flashcards:
            return studyUserLibraryService.state.flashcardTargets.count
        }
    }
    
    // MARK: - Controls Row
    private var controlsRow: some View {
        VStack(spacing: 10) {
            // Search Bar (full-width for accessibility and typing comfort)
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppTheme.textMuted)
                TextField("Search words...", text: $viewModel.searchText)
                    .font(AppTheme.fontRounded(size: 13))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                
                if !viewModel.searchText.isEmpty {
                    Button(action: { viewModel.searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppTheme.textMuted)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(AppTheme.paperCard)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.borderLight, lineWidth: 1))
            
            // Scrollable Filters & Layout Controls Row (Prevents vertical character squeezing/wrapping)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    // JLPT Level filter Menu
                    Menu {
                        Button("All Levels") { viewModel.selectedLevel = nil }
                        ForEach(viewModel.availableLevels, id: \.self) { level in
                            Button(level) { viewModel.selectedLevel = level }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "tag")
                                .font(.system(size: 11))
                            Text(viewModel.selectedLevel ?? "All Levels")
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 9))
                        }
                        .font(AppTheme.fontRounded(size: 12, weight: .bold))
                        .foregroundColor(AppTheme.textDark)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(AppTheme.paperCard)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.borderLight, lineWidth: 1))
                    }
                    
                    // Sort Menu
                    Menu {
                        ForEach(VocabularySortOption.allCases) { opt in
                            Button(opt.rawValue) { viewModel.sortOption = opt }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.system(size: 11))
                            Text(viewModel.sortOption.rawValue)
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 9))
                        }
                        .font(AppTheme.fontRounded(size: 12, weight: .bold))
                        .foregroundColor(AppTheme.textDark)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(AppTheme.paperCard)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.borderLight, lineWidth: 1))
                    }
                    
                    // Layout Toggle
                    layoutToggle
                }
                .padding(.vertical, 2)
            }
        }
        .padding(.horizontal, 24)
    }
    
    private var layoutToggle: some View {
        HStack(spacing: 0) {
            Button(action: { viewModel.layoutMode = .grid }) {
                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 12, weight: .bold))
                    .padding(8)
                    .background(viewModel.layoutMode == .grid ? AppTheme.sakuraPink : Color.clear)
                    .foregroundColor(viewModel.layoutMode == .grid ? .white : AppTheme.textMuted)
            }
            
            Button(action: { viewModel.layoutMode = .list }) {
                Image(systemName: "list.bullet")
                    .font(.system(size: 12, weight: .bold))
                    .padding(8)
                    .background(viewModel.layoutMode == .list ? AppTheme.sakuraPink : Color.clear)
                    .foregroundColor(viewModel.layoutMode == .list ? .white : AppTheme.textMuted)
            }
        }
        .background(AppTheme.paperCard)
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.borderLight, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    // MARK: - Category Chips Bar
    private var categoryChipsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // "All" chip
                categoryChip(id: "all-vocabulary", label: "All Categories", icon: "square.grid.3x3")
                
                // Real data chips
                ForEach(viewModel.availableCategories.filter { !$0.isVirtual }, id: \.id) { cat in
                    categoryChip(id: cat.id, label: cat.nameEn, icon: cat.icon)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 2)
        }
    }
    
    private func categoryChip(id: String, label: String, icon: String? = nil) -> some View {
        let isSelected = viewModel.selectedCategoryId == id
        return Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.selectedCategoryId = id
                // iPad auto-select first item in category if available
                if sizeClass == .regular {
                    viewModel.selectedItemId = viewModel.filteredVocabularyItems.first?.id
                }
            }
        }) {
            HStack(spacing: 4) {
                if let iconName = icon {
                    Image(systemName: iconName)
                        .font(.system(size: 11))
                }
                Text(label)
                    .font(AppTheme.fontRounded(size: 12, weight: .bold))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? AppTheme.darkNavy : AppTheme.paperCard)
            .foregroundColor(isSelected ? .white : AppTheme.textDark)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.clear : AppTheme.borderLight, lineWidth: 1)
            )
            .shadow(color: AppTheme.shadowColor, radius: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Browsing Content Area
    private var contentArea: some View {
        Group {
            let items = viewModel.filteredVocabularyItems
            
            if items.isEmpty {
                VStack {
                    Spacer()
                    EmptyStateCardView(
                        iconName: "magnifyingglass",
                        title: "No matching words",
                        description: "Try adjusting your query, changing filters, or clearing active collection targets."
                    )
                    .padding(24)
                    Spacer()
                }
            } else {
                ScrollView {
                    if viewModel.layoutMode == .grid {
                        // Grid Mode
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 155), spacing: 12)], spacing: 12) {
                            ForEach(items) { item in
                                cellFor(item: item)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                    } else {
                        // List Mode
                        LazyVStack(spacing: 8) {
                            ForEach(items) { item in
                                cellFor(item: item)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func cellFor(item: VocabularyItem) -> some View {
        if sizeClass == .compact {
            // iPhone navigation link push
            NavigationLink(destination: VocabularyWordDetailView(item: item)) {
                if viewModel.layoutMode == .grid {
                    VocabularyCardView(item: item, isSelected: false, onSelect: {})
                } else {
                    VocabularyListRowView(item: item, isSelected: false, onSelect: {})
                }
            }
        } else {
            // iPad selection behavior
            if viewModel.layoutMode == .grid {
                VocabularyCardView(item: item, isSelected: viewModel.selectedItemId == item.id, onSelect: {
                    viewModel.selectedItemId = item.id
                })
            } else {
                VocabularyListRowView(item: item, isSelected: viewModel.selectedItemId == item.id, onSelect: {
                    viewModel.selectedItemId = item.id
                })
            }
        }
    }
    
    // MARK: - Collapsible Debug Accordion
    @State private var isDevExpanded = false
    
    @ViewBuilder
    private var developerAccordion: some View {
        if settingsService.settings.showDeveloperDiagnostics {
            VStack(spacing: 0) {
                Button(action: {
                    withAnimation(.spring()) {
                        isDevExpanded.toggle()
                    }
                }) {
                    HStack {
                        Image(systemName: "cpu")
                            .foregroundColor(AppTheme.sakuraPink)
                        Text("Developer Status Info")
                            .font(AppTheme.fontRounded(size: 11, weight: .bold))
                            .foregroundColor(colorScheme == .dark ? AppTheme.darkTextSecondary : AppTheme.textMuted)
                        Spacer()
                        Image(systemName: isDevExpanded ? "chevron.down" : "chevron.up")
                            .font(.system(size: 9))
                            .foregroundColor(colorScheme == .dark ? AppTheme.darkTextSecondary : AppTheme.textMuted)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background((colorScheme == .dark ? AppTheme.darkCardActive : AppTheme.paperBeige).opacity(0.3))
                }
                .buttonStyle(PlainButtonStyle())
                
                if isDevExpanded {
                    Divider()
                        .background(colorScheme == .dark ? AppTheme.darkBorder : AppTheme.borderLight)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 12) {
                            debugCountText("Vocab", count: studyDataService.vocabularyItems.count)
                            debugCountText("Kanji", count: studyDataService.kanjiItems.count)
                            debugCountText("Grammar", count: studyDataService.grammarPatterns.count)
                            debugCountText("Flashcards", count: studyDataService.flashcardPrompts.count)
                        }
                        
                        if let result = studyDataService.validationResult {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(result.passed ? AppTheme.sageGreen : Color.red)
                                    .frame(width: 6, height: 6)
                                Text(result.passed ? "Data Integrity Passed" : "Data Integrity Errors")
                                    .font(AppTheme.fontRounded(size: 10, weight: .medium))
                                    .foregroundColor(result.passed ? AppTheme.sageGreen : Color.red)
                            }
                        }
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(colorScheme == .dark ? AppTheme.darkCard : AppTheme.paperCard)
                }
            }
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(colorScheme == .dark ? AppTheme.darkBorder : AppTheme.borderLight, lineWidth: 1))
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }
    
    private func debugCountText(_ title: String, count: Int) -> some View {
        Text("\(title): \(count)")
            .font(AppTheme.fontRounded(size: 9, weight: .bold))
            .foregroundColor(colorScheme == .dark ? AppTheme.darkTextPrimary : AppTheme.textDark)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(colorScheme == .dark ? AppTheme.darkCardActive : AppTheme.paperBeige)
            .cornerRadius(4)
    }
}

// Wrapper view to handle safe inject lookup of StudyDataService, StudyUserLibraryService, and UserVocabularyService
struct VocabularyLibraryScreen_Wrapper: View {
    @EnvironmentObject private var studyDataService: StudyDataService
    @EnvironmentObject private var studyUserLibraryService: StudyUserLibraryService
    @EnvironmentObject private var userVocabularyService: UserVocabularyService
    
    var body: some View {
        VocabularyLibraryScreen(service: studyDataService, userLibraryService: studyUserLibraryService, userVocabularyService: userVocabularyService)
    }
}
