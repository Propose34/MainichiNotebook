import SwiftUI

struct HomeDashboardScreen: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    @Binding var selectedCategory: MainCategory
    @Binding var selectedLectureBook: LectureBook?
    
    @EnvironmentObject private var dailySummaryService: DailySummaryService
    @EnvironmentObject private var srsService: SRSService
    @EnvironmentObject private var userProfileService: UserProfileService
    @EnvironmentObject private var studyPlanService: StudyPlanService
    @EnvironmentObject private var studyDataService: StudyDataService
    @EnvironmentObject private var userVocabularyService: UserVocabularyService
    @EnvironmentObject private var settingsService: AppSettingsService
    @Environment(\.colorScheme) var colorScheme
    
    private var recentBooks: [LectureBook] {
        let recents = UserDefaults.standard.stringArray(forKey: "com.mainichi.recentBookIds") ?? []
        let allBooks = LectureStorageService.shared.loadBooks()
        return recents.compactMap { idStr in
            allBooks.first { $0.id.uuidString == idStr }
        }
    }
    
    private var upcomingReviews: [VocabularyItem] {
        let now = Date()
        let dueStates = srsService.cardStates.values.filter { state in
            state.targetType == .vocabulary && state.status != .new && (state.dueDate.map { $0 <= now } ?? false)
        }.sorted { ($0.dueDate ?? Date()) < ($1.dueDate ?? Date()) }
        
        let repository = StudyDataRepository(service: studyDataService)
        
        var list: [VocabularyItem] = []
        for state in dueStates {
            let vocabId = state.targetId
            if vocabId.hasPrefix("user_") {
                if let item = userVocabularyService.userVocabularyItem(id: vocabId)?.toVocabularyItem() {
                    list.append(item)
                }
            } else {
                if let item = repository.vocabularyItem(id: vocabId) {
                    list.append(item)
                }
            }
        }
        return list
    }
    
    @State private var showingSettingsSheet = false
    @State private var showingPlannerSheet = false
    
    private var todayKey: String {
        dailySummaryService.makeDateKey(from: Date())
    }
    
    private var todayEntry: DailySummaryEntry {
        dailySummaryService.getEntry(forDateKey: todayKey)
    }
    
    private var selectedMoodIndex: Int {
        guard let mood = todayEntry.mood else { return -1 }
        switch mood {
        case .neutral: return 0
        case .happy: return 1
        case .focused: return 2
        case .tired: return 3
        case .confused: return 4
        case .proud: return 1
        }
    }
    
    private func updateMoodFromIndex(_ idx: Int) {
        let mood: DailyMood?
        switch idx {
        case 0: mood = .neutral
        case 1: mood = .happy
        case 2: mood = .focused
        case 3: mood = .tired
        case 4: mood = .confused
        default: mood = nil
        }
        dailySummaryService.updateMood(dateKey: todayKey, mood: mood)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                statsSection
                studyModulesShelf
                detailsGrid
                footerSection
            }
        }
        .background(colorScheme == .dark ? AppTheme.darkBackground : AppTheme.paperBackground)
    }
    
    // MARK: - Sub-Sections
    
    @ViewBuilder
    private var headerSection: some View {
        Group {
            if sizeClass == .compact {
                VStack(alignment: .leading, spacing: 16) {
                    greetingCard
                    HStack {
                        Spacer()
                        iconRow
                    }
                }
            } else {
                HStack(alignment: .top, spacing: 20) {
                    greetingCard
                    iconRow
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
    }
    
    private var greetingCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("おはようございます、\(userProfileService.profile.displayName)! 🌸")
                    .font(AppTheme.fontSerif(size: 26, weight: .bold))
                    .foregroundColor(colorScheme == .dark ? AppTheme.darkTextPrimary : AppTheme.textDark)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer()
            }
            
            Text("今日も一緒に、少しずつ進んでいきましょう。")
                .font(AppTheme.fontSerif(size: 14, weight: .medium))
                .foregroundColor(colorScheme == .dark ? AppTheme.darkTextSecondary : AppTheme.textMuted)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            
            Text("Good morning! Let's make today a productive step forward.")
                .font(AppTheme.fontRounded(size: 13, weight: .regular))
                .foregroundColor(colorScheme == .dark ? AppTheme.darkTextSecondary.opacity(0.85) : AppTheme.textMuted.opacity(0.85))
                .padding(.top, 4)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerLG)
                .fill(colorScheme == .dark ? AppTheme.darkCard : AppTheme.paperCard)
                .shadow(color: AppTheme.shadowColor, radius: AppTheme.cardShadow)
        )
    }
    
    private var iconRow: some View {
        HStack(spacing: 12) {
            Button(action: {
                showingPlannerSheet = true
            }) {
                HeaderIconButton(iconName: "calendar")
            }
            .buttonStyle(PlainButtonStyle())
            
            HeaderIconButton(iconName: "bell.badge", badgeCount: 3)
            
            Button(action: {
                showingSettingsSheet = true
            }) {
                profileAvatarButtonView
            }
            .buttonStyle(PlainButtonStyle())
        }
        .sheet(isPresented: $showingSettingsSheet) {
            AppSettingsScreen()
        }
        .sheet(isPresented: $showingPlannerSheet) {
            CalendarPlanningScreen()
        }
    }
    
    private var profileAvatarButtonView: some View {
        let presets = [
            ("preset_cherry", "🌸"),
            ("preset_kitsune", "🦊"),
            ("preset_castle", "🏯"),
            ("preset_onigiri", "🍙"),
            ("preset_daruma", "🏮"),
            ("preset_sushi", "🍣"),
            ("preset_cat", "🐱")
        ]
        
        return ZStack {
            Circle()
                .stroke(AppTheme.sakuraPink.opacity(0.3), lineWidth: 1.5)
                .frame(width: 44, height: 44)
                .background(Circle().fill(colorScheme == .dark ? AppTheme.darkCard : AppTheme.paperCard))
                .shadow(color: AppTheme.shadowColor, radius: 4)
            
            if let avatar = userProfileService.profile.avatarImageFileName {
                if avatar == "avatar.jpg",
                   let uiImage = UIImage(contentsOfFile: userProfileService.customAvatarURL.path) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 38, height: 38)
                        .clipShape(Circle())
                } else if let preset = presets.first(where: { $0.0 == avatar }) {
                    Text(preset.1)
                        .font(.system(size: 20))
                        .frame(width: 38, height: 38)
                        .background(AppTheme.sakuraPinkLight)
                        .clipShape(Circle())
                } else {
                    defaultAvatarPlaceholder
                }
            } else {
                defaultAvatarPlaceholder
            }
        }
    }
    
    private var defaultAvatarPlaceholder: some View {
        Image(systemName: "person.crop.circle")
            .font(.system(size: 20))
            .foregroundColor(colorScheme == .dark ? AppTheme.darkTextPrimary : AppTheme.textDark)
    }
    
    @ViewBuilder
    private var statsSection: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 260, maximum: .infinity), spacing: 16)], spacing: 16) {
            // 1. Daily Streak
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Daily Streak")
                        .font(AppTheme.fontRounded(size: 12, weight: .bold))
                        .foregroundColor(colorScheme == .dark ? AppTheme.darkTextSecondary : AppTheme.textMuted)
                    
                    HStack(alignment: .bottom, spacing: 4) {
                        Text("\(dailySummaryService.computeStreak())")
                            .font(AppTheme.fontSerif(size: 32, weight: .bold))
                            .foregroundColor(colorScheme == .dark ? AppTheme.darkTextPrimary : AppTheme.textDark)
                        Text("days")
                            .font(AppTheme.fontRounded(size: 14, weight: .medium))
                            .foregroundColor(colorScheme == .dark ? AppTheme.darkTextSecondary : AppTheme.textMuted)
                            .padding(.bottom, 6)
                    }
                    
                    Text("Best: \(dailySummaryService.computeBestStreak()) days")
                        .font(AppTheme.fontRounded(size: 11, weight: .regular))
                        .foregroundColor(colorScheme == .dark ? AppTheme.darkTextSecondary.opacity(0.8) : AppTheme.textMuted.opacity(0.8))
                }
                Spacer()
                Image(systemName: "sparkles")
                    .font(.system(size: 28))
                    .foregroundColor(AppTheme.sakuraPink)
            }
            .padding(16)
            .background(colorScheme == .dark ? AppTheme.darkCard : AppTheme.paperCard)
            .cornerRadius(AppTheme.cornerLG)
            .shadow(color: AppTheme.shadowColor, radius: AppTheme.cardShadow)
            
            // 2. Today's Progress
            let completedCount = todayEntry.completedTaskIds.filter { ["add-one-note", "learn-5-words", "practice-writing", "review-flashcards"].contains($0) }.count
            let progressPct = Double(completedCount) / 4.0
            
            HStack(spacing: 16) {
                CircularProgressView(progress: progressPct, thickness: 6)
                    .frame(width: 60, height: 60)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Progress")
                        .font(AppTheme.fontRounded(size: 12, weight: .bold))
                        .foregroundColor(colorScheme == .dark ? AppTheme.darkTextSecondary : AppTheme.textMuted)
                    
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 68, maximum: .infinity), spacing: 6)
                    ], alignment: .leading, spacing: 6) {
                        MiniCheckIndicator(label: "Lectures", checked: todayEntry.completedTaskIds.contains("add-one-note"))
                        MiniCheckIndicator(label: "Vocab", checked: todayEntry.completedTaskIds.contains("learn-5-words"))
                        MiniCheckIndicator(label: "Writing", checked: todayEntry.completedTaskIds.contains("practice-writing"))
                        MiniCheckIndicator(label: "Review", checked: todayEntry.completedTaskIds.contains("review-flashcards"))
                    }
                }
                Spacer()
            }
            .padding(16)
            .background(colorScheme == .dark ? AppTheme.darkCard : AppTheme.paperCard)
            .cornerRadius(AppTheme.cornerLG)
            .shadow(color: AppTheme.shadowColor, radius: AppTheme.cardShadow)
            
            // 3. Study Time Today
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Study Time Today")
                        .font(AppTheme.fontRounded(size: 12, weight: .bold))
                        .foregroundColor(colorScheme == .dark ? AppTheme.darkTextSecondary : AppTheme.textMuted)
                    
                    HStack(alignment: .bottom, spacing: 4) {
                        Text("\(todayEntry.manualStudyMinutes)")
                            .font(AppTheme.fontSerif(size: 32, weight: .bold))
                            .foregroundColor(colorScheme == .dark ? AppTheme.darkTextPrimary : AppTheme.textDark)
                        Text("mins")
                            .font(AppTheme.fontRounded(size: 14, weight: .medium))
                            .foregroundColor(colorScheme == .dark ? AppTheme.darkTextSecondary : AppTheme.textMuted)
                            .padding(.bottom, 6)
                    }
                    
                    Text("Goal: 30 mins")
                        .font(AppTheme.fontRounded(size: 11, weight: .regular))
                        .foregroundColor(colorScheme == .dark ? AppTheme.darkTextSecondary.opacity(0.8) : AppTheme.textMuted.opacity(0.8))
                }
                Spacer()
                Image(systemName: "clock.fill")
                    .font(.system(size: 26))
                    .foregroundColor(AppTheme.sakuraPink)
            }
            .padding(16)
            .background(colorScheme == .dark ? AppTheme.darkCard : AppTheme.paperCard)
            .cornerRadius(AppTheme.cornerLG)
            .shadow(color: AppTheme.shadowColor, radius: AppTheme.cardShadow)
            
            // 4. Mood Snapshot
            VStack(alignment: .leading, spacing: 10) {
                Text("Mood Snapshot")
                    .font(AppTheme.fontRounded(size: 12, weight: .bold))
                    .foregroundColor(colorScheme == .dark ? AppTheme.darkTextSecondary : AppTheme.textMuted)
                
                let mood = todayEntry.mood
                let moodLabel = mood?.labelEn ?? "No mood logged"
                let moodComment = mood.map { " - Feeling \($0.rawValue) today!" } ?? " - How are you feeling?"
                (Text(moodLabel)
                    .font(AppTheme.fontRounded(size: 14, weight: .bold))
                    .foregroundColor(AppTheme.sakuraPink)
                    + Text(moodComment)
                        .font(AppTheme.fontRounded(size: 12, weight: .regular))
                        .foregroundColor(colorScheme == .dark ? AppTheme.darkTextSecondary : AppTheme.textMuted))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                
                HStack(spacing: 0) {
                    MoodEmojiButton(emoji: "😐", isSelected: selectedMoodIndex == 0) { updateMoodFromIndex(0) }
                    Spacer(minLength: 4)
                    MoodEmojiButton(emoji: "😊", isSelected: selectedMoodIndex == 1) { updateMoodFromIndex(1) }
                    Spacer(minLength: 4)
                    MoodEmojiButton(emoji: "😇", isSelected: selectedMoodIndex == 2) { updateMoodFromIndex(2) }
                    Spacer(minLength: 4)
                    MoodEmojiButton(emoji: "😴", isSelected: selectedMoodIndex == 3) { updateMoodFromIndex(3) }
                    Spacer(minLength: 4)
                    MoodEmojiButton(emoji: "😔", isSelected: selectedMoodIndex == 4) { updateMoodFromIndex(4) }
                }
            }
            .padding(16)
            .background(colorScheme == .dark ? AppTheme.darkCard : AppTheme.paperCard)
            .cornerRadius(AppTheme.cornerLG)
            .shadow(color: AppTheme.shadowColor, radius: AppTheme.cardShadow)
        }
        .padding(.horizontal, 24)
    }
    
    @ViewBuilder
    private var studyModulesShelf: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "books.vertical.fill")
                    .foregroundColor(colorScheme == .dark ? AppTheme.woodCozy : AppTheme.woodDark)
                Text("My Study Modules")
                    .font(AppTheme.titleSmall)
                    .foregroundColor(colorScheme == .dark ? AppTheme.darkTextPrimary : AppTheme.textDark)
                Spacer()
            }
            
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .bottom, spacing: 20) {
                        ModuleCoverShortcut(title: "講義", subtitle: "Lectures", colorHex: "EAA09B", emoji: "🎥") {
                            selectedCategory = .lectures
                        }
                        ModuleCoverShortcut(title: "単語帳", subtitle: "Vocabulary", colorHex: "8A9A86", emoji: "📖") {
                            selectedCategory = .vocabularyLibrary
                        }
                        ModuleCoverShortcut(title: "書く練習", subtitle: "Writing", colorHex: "EAE5DB", emoji: "✍️") {
                            selectedCategory = .writingPractice
                        }
                        ModuleCoverShortcut(title: "やさしい単語", subtitle: "Simple Vocab", colorHex: "DECBB7", emoji: "あ") {
                            selectedCategory = .simpleVocabulary
                        }
                        ModuleCoverShortcut(title: "日まとめ", subtitle: "Daily Summary", colorHex: "E2B586", emoji: "⛅") {
                            selectedCategory = .dailySummary
                        }
                        ModuleCoverShortcut(title: "フラッシュ\nカード", subtitle: "Flash Cards", colorHex: "131B26", emoji: "🗂️") {
                            selectedCategory = .flashCards
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 2)
                }
                
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.woodDark, AppTheme.woodCozy, AppTheme.woodDark],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 12)
                    .cornerRadius(4)
                    .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 3)
            }
        }
        .padding(.horizontal, 24)
    }
    
    @ViewBuilder
    private var detailsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 280, maximum: .infinity), spacing: 20)
        ], spacing: 20) {
            recentLecturesColumn
            upcomingReviewColumn
            todaysPlanColumn
        }
        .padding(.horizontal, 24)
    }
    
    @ViewBuilder
    private var recentLecturesColumn: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Lectures")
                    .font(AppTheme.titleSmall)
                    .foregroundColor(colorScheme == .dark ? AppTheme.darkTextPrimary : AppTheme.textDark)
                Spacer()
                Button("See all") {
                    selectedCategory = .lectures
                }
                .font(AppTheme.fontRounded(size: 12, weight: .semibold))
                .foregroundColor(AppTheme.sakuraPink)
            }
            
            VStack(spacing: 12) {
                let list = recentBooks
                if list.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 24))
                            .foregroundColor(colorScheme == .dark ? AppTheme.darkTextSecondary.opacity(0.4) : AppTheme.textMuted.opacity(0.4))
                        Text("No recently opened notebooks.\nยังไม่มีสมุดโน้ตที่เพิ่งเปิด")
                            .font(AppTheme.fontRounded(size: 11))
                            .foregroundColor(colorScheme == .dark ? AppTheme.darkTextSecondary : AppTheme.textMuted)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                } else {
                    ForEach(list) { book in
                        Button(action: {
                            selectedLectureBook = book
                            selectedCategory = .lectures
                        }) {
                            HStack {
                                Text(book.decorationEmoji)
                                    .font(.system(size: 18))
                                    .frame(width: 28, height: 28)
                                    .background(Color(hex: book.coverColorHex).opacity(0.2))
                                    .cornerRadius(6)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(book.title)
                                        .font(AppTheme.fontRounded(size: 13, weight: .semibold))
                                        .foregroundColor(colorScheme == .dark ? AppTheme.darkTextPrimary : AppTheme.textDark)
                                        .lineLimit(1)
                                    
                                    Text(book.subject)
                                        .font(AppTheme.fontRounded(size: 10, weight: .regular))
                                        .foregroundColor(colorScheme == .dark ? AppTheme.darkTextSecondary : AppTheme.textMuted)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(colorScheme == .dark ? AppTheme.darkTextSecondary.opacity(0.5) : AppTheme.textMuted.opacity(0.5))
                            }
                            .padding(8)
                            .background(colorScheme == .dark ? AppTheme.darkCardActive.opacity(0.4) : AppTheme.paperBeige.opacity(0.3))
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .padding(16)
        .background(colorScheme == .dark ? AppTheme.darkCard : AppTheme.paperCard)
        .cornerRadius(AppTheme.cornerLG)
        .shadow(color: AppTheme.shadowColor, radius: AppTheme.cardShadow)
    }
    
    @ViewBuilder
    private var upcomingReviewColumn: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Upcoming Review")
                    .font(AppTheme.titleSmall)
                    .foregroundColor(colorScheme == .dark ? AppTheme.darkTextPrimary : AppTheme.textDark)
                
                let dueCount = upcomingReviews.count
                Text("\(dueCount)")
                    .font(AppTheme.fontRounded(size: 11, weight: .bold))
                    .foregroundColor(Color.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(AppTheme.sakuraPink)
                    .clipShape(Capsule())
                
                Spacer()
                
                Button("View all") {
                    selectedCategory = .flashCards
                }
                .font(AppTheme.fontRounded(size: 12, weight: .semibold))
                .foregroundColor(AppTheme.sakuraPink)
            }
            
            VStack(spacing: 8) {
                if upcomingReviews.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(AppTheme.sageGreen.opacity(0.8))
                        Text("No upcoming reviews!\nไม่มีรายการทบทวนค้าง")
                            .font(AppTheme.fontRounded(size: 11))
                            .foregroundColor(colorScheme == .dark ? AppTheme.darkTextSecondary : AppTheme.textMuted)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                } else {
                    ForEach(upcomingReviews.prefix(3)) { word in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(word.japanese)
                                    .font(AppTheme.fontSerif(size: 15, weight: .bold))
                                    .foregroundColor(colorScheme == .dark ? AppTheme.darkTextPrimary : AppTheme.textDark)
                                Text(word.reading)
                                    .font(AppTheme.fontSerif(size: 11, weight: .regular))
                                    .foregroundColor(colorScheme == .dark ? AppTheme.darkTextSecondary : AppTheme.textMuted)
                            }
                            
                            Spacer()
                            
                            Text(word.meaningTh)
                                .font(AppTheme.fontRounded(size: 12, weight: .medium))
                                .foregroundColor(colorScheme == .dark ? AppTheme.darkTextPrimary : AppTheme.textDark)
                            
                            Text(word.partOfSpeech)
                                .font(AppTheme.fontRounded(size: 9, weight: .bold))
                                .foregroundColor(AppTheme.sageGreen)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(colorScheme == .dark ? AppTheme.darkCardActive : AppTheme.sageGreenLight)
                                .cornerRadius(4)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 8)
                        .background(colorScheme == .dark ? AppTheme.darkCardActive.opacity(0.4) : AppTheme.paperBeige.opacity(0.3))
                        .cornerRadius(8)
                    }
                    
                    if upcomingReviews.count > 3 {
                        HStack {
                            Image(systemName: "cup.and.saucer.fill")
                                .foregroundColor(AppTheme.sageGreen.opacity(0.6))
                            Text("+\(upcomingReviews.count - 3) more items")
                                .font(AppTheme.fontRounded(size: 11, weight: .regular).italic())
                                .foregroundColor(colorScheme == .dark ? AppTheme.darkTextSecondary : AppTheme.textMuted)
                            Spacer()
                        }
                        .padding(.top, 4)
                        .padding(.horizontal, 8)
                    }
                }
            }
        }
        .padding(16)
        .background(colorScheme == .dark ? AppTheme.darkCard : AppTheme.paperCard)
        .cornerRadius(AppTheme.cornerLG)
        .shadow(color: AppTheme.shadowColor, radius: AppTheme.cardShadow)
    }
    
    @ViewBuilder
    private var todaysPlanColumn: some View {
        let todayKey = dailySummaryService.makeDateKey(from: Date())
        let todayTasks = studyPlanService.getTasks(forDateKey: todayKey)
        let totalMinutes = todayTasks.reduce(0) { sum, task in
            let rawStr = task.timeString.lowercased().replacingOccurrences(of: " min", with: "").replacingOccurrences(of: "m", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            let mins = Int(rawStr) ?? 0
            return sum + mins
        }
        
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Today's Plan")
                    .font(AppTheme.titleSmall)
                    .foregroundColor(colorScheme == .dark ? AppTheme.darkTextPrimary : AppTheme.textDark)
                Spacer()
                Button("Edit") {
                    showingPlannerSheet = true
                }
                .font(AppTheme.fontRounded(size: 12, weight: .semibold))
                .foregroundColor(AppTheme.sakuraPink)
            }
            
            VStack(spacing: 8) {
                if todayTasks.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "checklist.checked")
                            .font(.system(size: 26))
                            .foregroundColor(colorScheme == .dark ? AppTheme.darkTextSecondary.opacity(0.4) : AppTheme.textMuted.opacity(0.4))
                        Text("No plans scheduled for today.")
                            .font(AppTheme.fontRounded(size: 11))
                            .foregroundColor(colorScheme == .dark ? AppTheme.darkTextSecondary : AppTheme.textMuted)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
                } else {
                    ForEach(todayTasks) { plan in
                        Button(action: {
                            withAnimation {
                                studyPlanService.toggleTask(id: plan.id, dateKey: todayKey)
                            }
                        }) {
                            HStack {
                                Image(systemName: plan.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(plan.isCompleted ? AppTheme.sageGreen : (colorScheme == .dark ? AppTheme.darkTextSecondary.opacity(0.4) : AppTheme.textMuted.opacity(0.4)))
                                
                                Text(plan.title)
                                    .font(AppTheme.fontRounded(size: 13, weight: .bold))
                                    .foregroundColor(plan.isCompleted ? (colorScheme == .dark ? AppTheme.darkTextSecondary : AppTheme.textMuted) : (colorScheme == .dark ? AppTheme.darkTextPrimary : AppTheme.textDark))
                                    .strikethrough(plan.isCompleted)
                                
                                Spacer()
                                
                                Text(plan.timeString)
                                    .font(AppTheme.fontRounded(size: 11))
                                    .foregroundColor(colorScheme == .dark ? AppTheme.darkTextSecondary : AppTheme.textMuted)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 10)
                            .background(colorScheme == .dark ? AppTheme.darkCardActive.opacity(0.4) : AppTheme.paperBeige.opacity(0.3))
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                Divider()
                    .background(colorScheme == .dark ? AppTheme.darkBorder : AppTheme.borderLight)
                    .padding(.vertical, 4)
                
                HStack {
                    Text("Total Time")
                        .font(AppTheme.fontRounded(size: 13, weight: .bold))
                        .foregroundColor(colorScheme == .dark ? AppTheme.darkTextPrimary : AppTheme.textDark)
                    Spacer()
                    Text("\(totalMinutes) min")
                        .font(AppTheme.fontRounded(size: 13, weight: .bold))
                        .foregroundColor(colorScheme == .dark ? AppTheme.darkTextPrimary : AppTheme.textDark)
                }
                .padding(.horizontal, 6)
            }
        }
        .padding(16)
        .background(colorScheme == .dark ? AppTheme.darkCard : AppTheme.paperCard)
        .cornerRadius(AppTheme.cornerLG)
        .shadow(color: AppTheme.shadowColor, radius: AppTheme.cardShadow)
    }
    
    @ViewBuilder
    private var footerSection: some View {
        VStack(spacing: 12) {
            FujiVectorView()
                .frame(height: 120)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(colorScheme == .dark ? AppTheme.darkBorder : AppTheme.borderLight, lineWidth: 1)
                )
                .padding(.horizontal, 24)
            
            Text("小さな一歩の積み重ねが、大きな成長につながります。")
                .font(AppTheme.fontSerif(size: 13, weight: .semibold))
                .foregroundColor(colorScheme == .dark ? AppTheme.darkTextPrimary : AppTheme.textDark)
                .multilineTextAlignment(.center)
            
            Text("Small steps every day lead to big growth.")
                .font(AppTheme.fontRounded(size: 12, weight: .regular))
                .foregroundColor(colorScheme == .dark ? AppTheme.darkTextSecondary : AppTheme.textMuted)
                .multilineTextAlignment(.center)
        }
    }
}

// Button style for micro-interactions
struct SpringPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// Sub-components used locally on Dashboard
struct HeaderIconButton: View {
    let iconName: String
    var badgeCount: Int = 0
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: iconName)
                .font(.system(size: 20))
                .foregroundColor(colorScheme == .dark ? AppTheme.darkTextPrimary : AppTheme.textDark)
                .padding(12)
                .background(Circle().fill(colorScheme == .dark ? AppTheme.darkCard : AppTheme.paperCard))
                .shadow(color: AppTheme.shadowColor, radius: 4)
            
            if badgeCount > 0 {
                Text("\(badgeCount)")
                    .font(AppTheme.fontRounded(size: 9, weight: .bold))
                    .foregroundColor(.white)
                    .padding(5)
                    .background(AppTheme.sakuraPink)
                    .clipShape(Circle())
                    .offset(x: 2, y: -2)
            }
        }
    }
}

struct MiniCheckIndicator: View {
    let label: String
    let checked: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: checked ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 10))
                .foregroundColor(checked ? AppTheme.sageGreen : (colorScheme == .dark ? AppTheme.darkTextSecondary.opacity(0.3) : AppTheme.textMuted.opacity(0.3)))
            Text(label)
                .font(AppTheme.fontRounded(size: 10, weight: .medium))
                .foregroundColor(checked ? (colorScheme == .dark ? AppTheme.darkTextPrimary : AppTheme.textDark) : (colorScheme == .dark ? AppTheme.darkTextSecondary.opacity(0.6) : AppTheme.textMuted.opacity(0.6)))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
    }
}

struct MoodEmojiButton: View {
    let emoji: String
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            Text(emoji)
                .font(.system(size: 22))
                .padding(8)
                .background(
                    Circle()
                        .fill(isSelected ? (colorScheme == .dark ? AppTheme.darkCardActive : AppTheme.sakuraPinkLight) : Color.clear)
                        .overlay(
                            Circle()
                                .stroke(isSelected ? AppTheme.sakuraPink.opacity(0.4) : Color.clear, lineWidth: 1)
                        )
                )
                .scaleEffect(isSelected ? 1.25 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isSelected)
        }
        .buttonStyle(SpringPressButtonStyle())
    }
}

struct ModuleCoverShortcut: View {
    let title: String
    let subtitle: String
    let colorHex: String
    let emoji: String
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .leading) {
                // Book Base
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(hex: colorHex))
                    .frame(width: 80, height: 110)
                    .shadow(color: Color.black.opacity(0.2), radius: 3, x: 1, y: 2)
                
                // Book Spine Overlay
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.black.opacity(0.18), Color.white.opacity(0.06), Color.black.opacity(0.02)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 10, height: 110)
                    .cornerRadius(6, corners: [.topLeft, .bottomLeft])
                
                // Spine lines
                Rectangle()
                    .stroke(Color.black.opacity(0.12), lineWidth: 0.5)
                    .frame(width: 6, height: 110)
                
                // Content inside book cover
                VStack(spacing: 4) {
                    Spacer()
                    
                    if emoji == "あ" {
                        Text(emoji)
                            .font(AppTheme.fontSerif(size: 16, weight: .bold))
                            .foregroundColor(textColor)
                            .padding(4)
                            .background(textColor.opacity(0.15))
                            .cornerRadius(4)
                    } else {
                        Image(systemName: symbolForEmoji(emoji))
                            .font(.system(size: 16))
                            .foregroundColor(textColor)
                    }
                    
                    Text(title)
                        .font(AppTheme.fontSerif(size: 10, weight: .bold))
                        .foregroundColor(textColor)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.85)
                    
                    Text(subtitle)
                        .font(AppTheme.fontRounded(size: 7, weight: .medium))
                        .foregroundColor(textColor.opacity(0.8))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    
                    Spacer()
                }
                .frame(width: 80, height: 110)
            }
        }
        .buttonStyle(SpringPressButtonStyle())
    }
    
    private var textColor: Color {
        let darkColors = ["131B26"]
        if darkColors.contains(colorHex) {
            return AppTheme.paperBackground
        } else {
            return colorScheme == .dark ? AppTheme.darkTextPrimary : AppTheme.textDark
        }
    }
    
    private func symbolForEmoji(_ emoji: String) -> String {
        switch emoji {
        case "🎥": return "play.rectangle.fill"
        case "📖": return "book.closed.fill"
        case "✍️": return "pencil"
        case "⛅": return "cloud.sun.fill"
        case "🗂️": return "square.on.square.fill"
        default: return "star.fill"
        }
    }
}
