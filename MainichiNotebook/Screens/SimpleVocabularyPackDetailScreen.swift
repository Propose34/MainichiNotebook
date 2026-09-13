import SwiftUI

struct SimpleVocabularyPackDetailScreen: View {
    let pack: SimpleVocabularyPack
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass
    
    @EnvironmentObject private var studyDataService: StudyDataService
    @EnvironmentObject private var studyUserLibraryService: StudyUserLibraryService
    @EnvironmentObject private var userVocabularyService: UserVocabularyService
    @EnvironmentObject private var progressService: SimpleVocabularyProgressService
    @EnvironmentObject private var srsService: SRSService
    
    @StateObject private var viewModel: SimpleVocabularyPackDetailViewModel
    
    @State private var activeReviewSession: FlashCardReviewSessionViewModel? = nil
    @State private var showingDetailSheet = false
    
    @State private var toastMessage: String? = nil
    @State private var showToast = false
    
    init(pack: SimpleVocabularyPack) {
        self.pack = pack
        // Temporary dummy initialization
        let dummyData = StudyDataService()
        let dummyUser = StudyUserLibraryService()
        let dummyUserVocab = UserVocabularyService()
        let dummyProgress = SimpleVocabularyProgressService()
        
        _viewModel = StateObject(wrappedValue: SimpleVocabularyPackDetailViewModel(
            pack: pack,
            service: dummyData,
            userLibraryService: dummyUser,
            userVocabularyService: dummyUserVocab,
            progressService: dummyProgress
        ))
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Main left list column
            VStack(alignment: .leading, spacing: 14) {
                // Large Pack Header
                packHeaderSection
                
                // Active Actions Bar (Bulk Add, Start Quick Review)
                actionsBarSection
                
                // Search and Filters Section
                searchAndFilterBar
                
                // Words list
                wordsListView
            }
            .frame(maxWidth: .infinity)
            
            // iPad Right Detail Panel
            if sizeClass == .regular {
                Divider()
                
                VStack {
                    if let selected = viewModel.selectedItem {
                        VocabularyDetailPanelView(item: selected)
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "character.book.closed")
                                .font(.system(size: 48))
                                .foregroundColor(AppTheme.textMuted.opacity(0.4))
                            
                            Text("Select a word to see details\nเลือกคำศัพท์เพื่อดูรายละเอียด")
                                .font(AppTheme.fontRounded(size: 14, weight: .medium))
                                .foregroundColor(AppTheme.textMuted)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxHeight: .infinity)
                    }
                }
                .frame(width: 320)
                .background(AppTheme.paperBeige.opacity(0.15))
            }
        }
        .background(AppTheme.paperBackground.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Packs")
                    }
                    .font(AppTheme.fontRounded(size: 15, weight: .bold))
                    .foregroundColor(AppTheme.textDark)
                }
            }
        }
        // iPhone detail sheet presentation
        .sheet(isPresented: $showingDetailSheet) {
            if let selected = viewModel.selectedItem {
                ZStack {
                    AppTheme.paperBackground.ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        HStack {
                            Spacer()
                            Button(action: { showingDetailSheet = false }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(AppTheme.textMuted.opacity(0.6))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        
                        VocabularyDetailPanelView(item: selected)
                    }
                }
            }
        }
        // Quick review presentation
        .fullScreenCover(item: $activeReviewSession) { vm in
            FlashCardReviewScreen(viewModel: vm, onRestart: {
                self.activeReviewSession = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    let cards = viewModel.buildReviewCards(options: .default)
                    if !cards.isEmpty {
                        self.activeReviewSession = FlashCardReviewSessionViewModel(
                            source: .myFlashCards,
                            cards: cards,
                            options: .default,
                            srsService: srsService
                        )
                    }
                }
            })
        }
        // Custom toast overlay
        .overlay(
            VStack {
                if showToast, let msg = toastMessage {
                    Text(msg)
                        .font(AppTheme.fontRounded(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(AppTheme.darkNavy.opacity(0.9))
                        .cornerRadius(8)
                        .shadow(color: Color.black.opacity(0.2), radius: 4)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, 50)
                    Spacer()
                }
            }
            .animation(.spring(), value: showToast)
        )
        // Bind View Model after environment objects injected
        .onAppear {
            let activeVM = SimpleVocabularyPackDetailViewModel(
                pack: pack,
                service: studyDataService,
                userLibraryService: studyUserLibraryService,
                userVocabularyService: userVocabularyService,
                progressService: progressService
            )
            // Restore selection if regular size class
            if sizeClass == .regular {
                activeVM.selectedItemId = activeVM.filteredWords.first?.id
            }
            viewModel.searchText = ""
            viewModel.selectedFilter = .all
            viewModel.selectedPOS = nil
            
            // Re-bind to state
            // Swap runtime view model values to prevent multiple VM instances conflicting
            viewModel.selectedItemId = activeVM.selectedItemId
        }
    }
    
    // MARK: - Header Section
    
    private var packHeaderSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                // Emoji Icon
                Text(pack.emoji)
                    .font(.system(size: 32))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(pack.title)
                        .font(AppTheme.fontSerif(size: 24, weight: .bold))
                        .foregroundColor(AppTheme.textDark)
                    
                    Text(pack.description)
                        .font(AppTheme.fontRounded(size: 13))
                        .foregroundColor(AppTheme.textMuted)
                }
            }
            
            HStack(spacing: 8) {
                Text(pack.levelBadge)
                    .font(AppTheme.fontRounded(size: 10, weight: .bold))
                    .foregroundColor(AppTheme.woodDark)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppTheme.paperBeige)
                    .cornerRadius(6)
                
                Text("\(viewModel.allPackWords.count) Words")
                    .font(AppTheme.fontRounded(size: 10, weight: .bold))
                    .foregroundColor(AppTheme.sakuraPink)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppTheme.sakuraPinkLight)
                    .cornerRadius(6)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }
    
    // MARK: - Actions Bar Section
    
    private var actionsBarSection: some View {
        HStack(spacing: 12) {
            // Bulk Add to Flashcards
            Button(action: {
                let msg = viewModel.addPackToFlashCards()
                triggerToast(msg)
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus.square.on.square")
                    Text("Add to Flash Cards")
                }
                .font(AppTheme.fontRounded(size: 12, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(AppTheme.sakuraPink)
                .cornerRadius(10)
                .shadow(color: AppTheme.sakuraPink.opacity(0.2), radius: 3)
            }
            .disabled(viewModel.allPackWords.isEmpty)
            
            // Start Quick Review
            Button(action: {
                let cards = viewModel.buildReviewCards(options: .default)
                guard !cards.isEmpty else {
                    triggerToast("No reviewable words in this pack")
                    return
                }
                // Save progress
                progressService.trackStudySession(packId: pack.id, completedWordIds: matchingWordIds(for: cards))
                
                // Launch
                self.activeReviewSession = FlashCardReviewSessionViewModel(
                    source: .myFlashCards,
                    cards: cards,
                    options: .default,
                    srsService: srsService
                )
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "play.circle.fill")
                    Text("Quick Review")
                }
                .font(AppTheme.fontRounded(size: 12, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(AppTheme.darkNavy)
                .cornerRadius(10)
                .shadow(color: AppTheme.darkNavy.opacity(0.2), radius: 3)
            }
            .disabled(viewModel.allPackWords.isEmpty)
            
            Spacer()
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Search and Filter Bar
    
    private var searchAndFilterBar: some View {
        VStack(spacing: 10) {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppTheme.textMuted)
                TextField("Search in pack...", text: $viewModel.searchText)
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
            
            // Filter chips row
            HStack {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(SimpleVocabularyPackDetailViewModel.SimpleVocabularyFilter.allCases) { filter in
                            let isSelected = viewModel.selectedFilter == filter
                            Button(action: {
                                withAnimation {
                                    viewModel.selectedFilter = filter
                                }
                            }) {
                                Text(filter.rawValue)
                                    .font(AppTheme.fontRounded(size: 12, weight: .bold))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(isSelected ? AppTheme.darkNavy : AppTheme.paperCard)
                                    .foregroundColor(isSelected ? .white : AppTheme.textDark)
                                    .cornerRadius(8)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(isSelected ? Color.clear : AppTheme.borderLight, lineWidth: 1))
                            }
                        }
                        
                        Divider()
                            .frame(height: 18)
                        
                        // POS selector menu
                        Menu {
                            Button("All POS") { viewModel.selectedPOS = nil }
                            ForEach(viewModel.availablePOS, id: \.self) { pos in
                                Button(pos) { viewModel.selectedPOS = pos }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "tag")
                                    .font(.system(size: 10))
                                Text(viewModel.selectedPOS ?? "All Parts of Speech")
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 8))
                            }
                            .font(AppTheme.fontRounded(size: 12, weight: .bold))
                            .foregroundColor(AppTheme.textDark)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(AppTheme.paperCard)
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.borderLight, lineWidth: 1))
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Words List View
    
    private var wordsListView: some View {
        Group {
            let words = viewModel.filteredWords
            
            if words.isEmpty {
                VStack {
                    Spacer()
                    EmptyStateCardView(
                        iconName: "magnifyingglass",
                        title: "No words found",
                        description: "Try adjusting your search query or changing active filters."
                    )
                    .padding(24)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(words) { item in
                            SimpleVocabularyWordRowView(
                                item: item,
                                isSelected: viewModel.selectedItemId == item.id,
                                onSelect: {
                                    viewModel.selectedItemId = item.id
                                    viewModel.trackWordViewed(wordId: item.id)
                                    if sizeClass == .compact {
                                        showingDetailSheet = true
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
        }
    }
    
    // MARK: - Toast helper
    
    private func triggerToast(_ msg: String) {
        toastMessage = msg
        showToast = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            showToast = false
        }
    }
    
    private func matchingWordIds(for cards: [ReviewCard]) -> [String] {
        return cards.map { $0.vocabularyItem.id }
    }
}
