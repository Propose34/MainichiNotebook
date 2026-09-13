import SwiftUI

struct DailySummaryScreen: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject private var dailySummaryService: DailySummaryService
    @EnvironmentObject private var srsService: SRSService
    @EnvironmentObject private var libraryService: StudyUserLibraryService
    @EnvironmentObject private var userVocabularyService: UserVocabularyService
    @EnvironmentObject private var writingProgressService: WritingPracticeProgressService
    @EnvironmentObject private var simpleVocabProgressService: SimpleVocabularyProgressService
    
    @StateObject private var viewModel: DailySummaryViewModel
    
    init(
        service: DailySummaryService,
        srsService: SRSService,
        libraryService: StudyUserLibraryService,
        userVocabularyService: UserVocabularyService,
        writingProgressService: WritingPracticeProgressService,
        simpleVocabProgressService: SimpleVocabularyProgressService
    ) {
        _viewModel = StateObject(wrappedValue: DailySummaryViewModel(
            service: service,
            srsService: srsService,
            libraryService: libraryService,
            userVocabularyService: userVocabularyService,
            writingProgressService: writingProgressService,
            simpleVocabProgressService: simpleVocabProgressService
        ))
    }
    
    // Fallback initializer
    init() {
        let dummyService = DailySummaryService()
        let dummySrs = SRSService()
        let dummyLib = StudyUserLibraryService()
        let dummyVocab = UserVocabularyService()
        let dummyWriting = WritingPracticeProgressService()
        let dummySimple = SimpleVocabularyProgressService()
        _viewModel = StateObject(wrappedValue: DailySummaryViewModel(
            service: dummyService,
            srsService: dummySrs,
            libraryService: dummyLib,
            userVocabularyService: dummyVocab,
            writingProgressService: dummyWriting,
            simpleVocabProgressService: dummySimple
        ))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with Date Picker
                headerSection
                
                // Today's Study Snapshot Grid
                snapshotGridSection
                
                // Mood Selection Box
                moodCheckInSection
                
                // Study Time Stepper + Steppers
                studyTimeSection
                
                // Daily Tasks list
                dailyChecklistSection
                
                // Diary Note Box
                diaryNoteSection
                
                // SRS Rating breakdown
                srsBreakdownSection
                
                // Recent History Timeline
                recentTimelineSection
            }
            .padding(.bottom, 32)
        }
        .background((colorScheme == .dark ? AppTheme.darkBackground : AppTheme.paperBackground).ignoresSafeArea())
        .onAppear {
            // Re-instantiate ViewModel to fetch live environment objects
            let freshVM = DailySummaryViewModel(
                service: dailySummaryService,
                srsService: srsService,
                libraryService: libraryService,
                userVocabularyService: userVocabularyService,
                writingProgressService: writingProgressService,
                simpleVocabProgressService: simpleVocabProgressService
            )
            viewModel.selectedDate = freshVM.selectedDate
            viewModel.loadSelectedEntry()
        }
    }
    
    // MARK: - Sub-Views
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily Summary ⛅")
                        .font(AppTheme.titleLarge)
                        .foregroundColor(colorScheme == .dark ? AppTheme.darkTextPrimary : AppTheme.textDark)
                    
                    Text("A gentle recap of today's Japanese study")
                        .font(AppTheme.fontRounded(size: 13))
                        .foregroundColor(colorScheme == .dark ? AppTheme.darkTextSecondary : AppTheme.textMuted)
                }
                
                Spacer()
                
                // Date picker
                DatePicker(
                    "",
                    selection: $viewModel.selectedDate,
                    displayedComponents: [.date]
                )
                .labelsHidden()
                .accentColor(AppTheme.sakuraPink)
                .background(colorScheme == .dark ? AppTheme.darkCard : AppTheme.paperCard)
                .cornerRadius(8)
                .shadow(color: AppTheme.shadowColor, radius: 2)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }
    
    private var snapshotGridSection: some View {
        let snap = viewModel.activeSnapshot ?? DailyActivitySnapshot(date: Date(), reviewedFlashcards: 0, againCount: 0, hardCount: 0, goodCount: 0, easyCount: 0, vocabularyAddedToFavorites: 0, vocabularyAddedToMyList: 0, vocabularyAddedToFlashCards: 0, customVocabularyCreated: 0, writingCharactersPracticed: 0, simpleVocabularyPacksStudied: 0, dueCardsRemaining: 0, newCardsRemaining: 0)
        
        return LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 16) {
            MiniStatCard(title: "Study Minutes", value: "\(viewModel.manualMinutes) min", icon: "clock.fill")
            MiniStatCard(title: "Cards Reviewed", value: "\(snap.reviewedFlashcards)", icon: "square.on.square.fill")
            MiniStatCard(title: "Words Starred", value: "\(snap.vocabularyAddedToFavorites)", icon: "star.fill")
            MiniStatCard(title: "Custom Words", value: "\(snap.customVocabularyCreated)", icon: "plus.circle.fill")
            MiniStatCard(title: "Kana Practiced", value: "\(snap.writingCharactersPracticed)", icon: "pencil.line")
            MiniStatCard(title: "Packs Opened", value: "\(snap.simpleVocabularyPacksStudied)", icon: "folder.fill")
        }
        .padding(.horizontal, 24)
    }
    
    private var moodCheckInSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How was studying today? / วันนี้เรียนเป็นอย่างไรบ้าง?")
                .font(AppTheme.titleSmall)
                .foregroundColor(colorScheme == .dark ? AppTheme.darkTextPrimary : AppTheme.textDark)
            
            HStack(spacing: 0) {
                ForEach(DailyMood.allCases) { m in
                    let isSelected = viewModel.activeEntry.mood == m
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            viewModel.selectMood(isSelected ? nil : m)
                        }
                    }) {
                        VStack(spacing: 6) {
                            Text(m.emoji)
                                .font(.system(size: 28))
                                .padding(10)
                                .background(
                                    Circle()
                                        .fill(isSelected ? (colorScheme == .dark ? AppTheme.darkNavyActive : AppTheme.sakuraPinkLight) : (colorScheme == .dark ? AppTheme.darkCardActive : AppTheme.paperBeige.opacity(0.3)))
                                        .overlay(
                                            Circle()
                                                .stroke(isSelected ? AppTheme.sakuraPink : (colorScheme == .dark ? AppTheme.darkBorder : AppTheme.borderLight), lineWidth: 1)
                                        )
                                )
                                .shadow(color: isSelected ? AppTheme.sakuraPink.opacity(0.1) : Color.clear, radius: 4)
                            
                            Text(m.labelEn)
                                .font(AppTheme.fontRounded(size: 10, weight: .bold))
                                .foregroundColor(isSelected ? AppTheme.sakuraPink : (colorScheme == .dark ? AppTheme.darkTextSecondary : AppTheme.textMuted))
                        }
                    }
                    if m != DailyMood.allCases.last {
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 8)
        }
        .padding(16)
        .background(colorScheme == .dark ? AppTheme.darkCard : AppTheme.paperCard)
        .cornerRadius(AppTheme.cornerLG)
        .overlay(RoundedRectangle(cornerRadius: AppTheme.cornerLG).stroke(colorScheme == .dark ? AppTheme.darkBorder : AppTheme.borderLight, lineWidth: 1))
        .padding(.horizontal, 24)
    }
    
    private var studyTimeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Log Study Time / บันทึกเวลาเรียน")
                    .font(AppTheme.titleSmall)
                    .foregroundColor(colorScheme == .dark ? AppTheme.darkTextPrimary : AppTheme.textDark)
                Spacer()
                Text("\(viewModel.manualMinutes) mins")
                    .font(AppTheme.fontRounded(size: 15, weight: .bold))
                    .foregroundColor(AppTheme.sakuraPink)
            }
            
            HStack(spacing: 8) {
                // Stepper Buttons
                Button(action: { viewModel.addMinutes(-5) }) {
                    Image(systemName: "minus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(colorScheme == .dark ? AppTheme.darkTextPrimary : AppTheme.textDark)
                        .frame(width: 36, height: 36)
                        .background(colorScheme == .dark ? AppTheme.darkCardActive : AppTheme.paperBeige)
                        .clipShape(Circle())
                }
                
                Button(action: { viewModel.addMinutes(5) }) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(colorScheme == .dark ? AppTheme.darkTextPrimary : AppTheme.textDark)
                        .frame(width: 36, height: 36)
                        .background(colorScheme == .dark ? AppTheme.darkCardActive : AppTheme.paperBeige)
                        .clipShape(Circle())
                }
                
                Spacer()
                
                // Quick Adds
                HStack(spacing: 6) {
                    quickTimeChip(label: "+5 min", minutes: 5)
                    quickTimeChip(label: "+10 min", minutes: 10)
                    quickTimeChip(label: "+15 min", minutes: 15)
                    quickTimeChip(label: "+30 min", minutes: 30)
                }
            }
        }
        .padding(16)
        .background(colorScheme == .dark ? AppTheme.darkCard : AppTheme.paperCard)
        .cornerRadius(AppTheme.cornerLG)
        .overlay(RoundedRectangle(cornerRadius: AppTheme.cornerLG).stroke(colorScheme == .dark ? AppTheme.darkBorder : AppTheme.borderLight, lineWidth: 1))
        .padding(.horizontal, 24)
    }
    
    private func quickTimeChip(label: String, minutes: Int) -> some View {
        Button(action: {
            withAnimation {
                viewModel.addMinutes(minutes)
            }
        }) {
            Text(label)
                .font(AppTheme.fontRounded(size: 11, weight: .bold))
                .foregroundColor(colorScheme == .dark ? AppTheme.darkTextPrimary : AppTheme.textDark)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(colorScheme == .dark ? AppTheme.darkCardActive : AppTheme.paperBeige)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(colorScheme == .dark ? AppTheme.darkBorder : AppTheme.borderLight, lineWidth: 1))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var dailyChecklistSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily Goals Checklist / เป้าหมายวันนี้")
                .font(AppTheme.titleSmall)
                .foregroundColor(colorScheme == .dark ? AppTheme.darkTextPrimary : AppTheme.textDark)
            
            VStack(spacing: 8) {
                ForEach(viewModel.defaultTasks) { task in
                    let isCompleted = viewModel.activeEntry.completedTaskIds.contains(task.id)
                    Button(action: {
                        withAnimation {
                            viewModel.toggleTask(task.id)
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 18))
                                .foregroundColor(isCompleted ? AppTheme.sageGreen : (colorScheme == .dark ? AppTheme.darkTextSecondary.opacity(0.4) : AppTheme.textMuted.opacity(0.4)))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(task.titleTh)
                                    .font(AppTheme.fontRounded(size: 13, weight: .bold))
                                    .foregroundColor(isCompleted ? (colorScheme == .dark ? AppTheme.darkTextSecondary : AppTheme.textMuted) : (colorScheme == .dark ? AppTheme.darkTextPrimary : AppTheme.textDark))
                                    .strikethrough(isCompleted)
                                
                                Text(task.description)
                                    .font(AppTheme.fontRounded(size: 10))
                                    .foregroundColor(colorScheme == .dark ? AppTheme.darkTextSecondary : AppTheme.textMuted)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                        .background(colorScheme == .dark ? AppTheme.darkCardActive.opacity(0.4) : AppTheme.paperBeige.opacity(0.3))
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(isCompleted ? AppTheme.sageGreen.opacity(0.3) : (colorScheme == .dark ? AppTheme.darkBorder : AppTheme.borderLight), lineWidth: 1))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(16)
        .background(colorScheme == .dark ? AppTheme.darkCard : AppTheme.paperCard)
        .cornerRadius(AppTheme.cornerLG)
        .overlay(RoundedRectangle(cornerRadius: AppTheme.cornerLG).stroke(colorScheme == .dark ? AppTheme.darkBorder : AppTheme.borderLight, lineWidth: 1))
        .padding(.horizontal, 24)
    }
    
    private var diaryNoteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Study Journal Diary / บันทึกการเรียนประจำวัน")
                    .font(AppTheme.fontSerif(size: 16, weight: .bold))
                    .foregroundColor(AppTheme.textDark)
                Spacer()
                Button(action: {
                    viewModel.saveNote()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                        Text("Save Note")
                    }
                    .font(AppTheme.fontRounded(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(AppTheme.sakuraPink)
                    .cornerRadius(6)
                }
            }
            
            TextEditor(text: $viewModel.dailyNote)
                .font(AppTheme.fontRounded(size: 13))
                .foregroundColor(AppTheme.textDark)
                .frame(height: 90)
                .padding(8)
                .background(AppTheme.paperBeige.opacity(0.2))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.borderLight, lineWidth: 1))
        }
        .padding(16)
        .background(AppTheme.paperCard)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.borderLight, lineWidth: 1))
        .padding(.horizontal, 24)
    }
    
    private var srsBreakdownSection: some View {
        let snap = viewModel.activeSnapshot ?? DailyActivitySnapshot(date: Date(), reviewedFlashcards: 0, againCount: 0, hardCount: 0, goodCount: 0, easyCount: 0, vocabularyAddedToFavorites: 0, vocabularyAddedToMyList: 0, vocabularyAddedToFlashCards: 0, customVocabularyCreated: 0, writingCharactersPracticed: 0, simpleVocabularyPacksStudied: 0, dueCardsRemaining: 0, newCardsRemaining: 0)
        
        let total = snap.reviewedFlashcards
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("Review Outcome breakdown / สัดส่วนการจำคำศัพท์")
                .font(AppTheme.fontSerif(size: 16, weight: .bold))
                .foregroundColor(AppTheme.textDark)
            
            if total == 0 {
                HStack {
                    Spacer()
                    Text("No flashcards reviewed on this day.\nไม่มีประวัติทบทวนศัพท์ในวันนี้")
                        .font(AppTheme.fontRounded(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.textMuted)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 8)
                    Spacer()
                }
            } else {
                VStack(spacing: 8) {
                    ratingProgressBar(label: "😊 Easy (ง่ายมาก)", count: snap.easyCount, total: total, color: AppTheme.sageGreen)
                    ratingProgressBar(label: "🟢 Good (จำได้)", count: snap.goodCount, total: total, color: AppTheme.darkNavy)
                    ratingProgressBar(label: "🟡 Hard (ยาก/เกือบกึ่ง)", count: snap.hardCount, total: total, color: AppTheme.woodCozy)
                    ratingProgressBar(label: "🔴 Again (จำไม่ได้/เริ่มใหม่)", count: snap.againCount, total: total, color: Color.red.opacity(0.8))
                }
            }
        }
        .padding(16)
        .background(AppTheme.paperCard)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.borderLight, lineWidth: 1))
        .padding(.horizontal, 24)
    }
    
    private func ratingProgressBar(label: String, count: Int, total: Int, color: Color) -> some View {
        let pct = total > 0 ? Double(count) / Double(total) : 0
        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(AppTheme.fontRounded(size: 11, weight: .bold))
                    .foregroundColor(AppTheme.textDark)
                Spacer()
                Text("\(count) (\(Int(pct * 100))%)")
                    .font(AppTheme.fontRounded(size: 11, weight: .bold))
                    .foregroundColor(AppTheme.textMuted)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(AppTheme.borderLight)
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(pct), height: 6)
                }
            }
            .frame(height: 6)
        }
    }
    
    private var recentTimelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Weekly Study History / ประวัติเรียนย้อนหลัง")
                    .font(AppTheme.fontSerif(size: 16, weight: .bold))
                    .foregroundColor(AppTheme.textDark)
                Spacer()
                Text("Total: \(viewModel.weeklyTotalStudyMinutes) min")
                    .font(AppTheme.fontRounded(size: 11, weight: .bold))
                    .foregroundColor(AppTheme.sakuraPink)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppTheme.sakuraPinkLight)
                    .cornerRadius(6)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.recentDays) { day in
                        Button(action: {
                            withAnimation {
                                viewModel.selectedDate = day.date
                            }
                        }) {
                            VStack(spacing: 8) {
                                // Day Name
                                Text(dayOfWeekString(from: day.date))
                                    .font(AppTheme.fontRounded(size: 10, weight: .bold))
                                    .foregroundColor(AppTheme.textMuted)
                                
                                // Date Number
                                Text(dayOfMonthString(from: day.date))
                                    .font(AppTheme.fontSerif(size: 15, weight: .bold))
                                    .foregroundColor(AppTheme.textDark)
                                    .frame(width: 32, height: 32)
                                    .background(Calendar.current.isDate(day.date, inSameDayAs: viewModel.selectedDate) ? AppTheme.sakuraPinkLight : Color.clear)
                                    .clipShape(Circle())
                                
                                // Mood Indicator
                                Text(day.mood?.emoji ?? "❔")
                                    .font(.system(size: 18))
                                
                                // Minutes indicator
                                Text("\(day.manualStudyMinutes)m")
                                    .font(AppTheme.fontRounded(size: 9, weight: .bold))
                                    .foregroundColor(day.manualStudyMinutes > 0 ? AppTheme.sageGreen : AppTheme.textMuted.opacity(0.5))
                                
                                // Note Indicator
                                if day.hasNote {
                                    Image(systemName: "doc.text")
                                        .font(.system(size: 9))
                                        .foregroundColor(AppTheme.sakuraPink)
                                } else {
                                    Spacer().frame(height: 9)
                                }
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                            .background(AppTheme.paperBeige.opacity(0.3))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Calendar.current.isDate(day.date, inSameDayAs: viewModel.selectedDate) ? AppTheme.sakuraPink : Color.clear, lineWidth: 1.5))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(16)
        .background(AppTheme.paperCard)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.borderLight, lineWidth: 1))
        .padding(.horizontal, 24)
    }
    
    // MARK: - Date Helpers
    
    private func dayOfWeekString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
    
    private func dayOfMonthString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
}

// Wrapper for safe environmental variables lookup
struct DailySummaryScreen_Wrapper: View {
    @EnvironmentObject private var dailySummaryService: DailySummaryService
    @EnvironmentObject private var srsService: SRSService
    @EnvironmentObject private var libraryService: StudyUserLibraryService
    @EnvironmentObject private var userVocabularyService: UserVocabularyService
    @EnvironmentObject private var writingProgressService: WritingPracticeProgressService
    @EnvironmentObject private var simpleVocabProgressService: SimpleVocabularyProgressService
    
    var body: some View {
        DailySummaryScreen(
            service: dailySummaryService,
            srsService: srsService,
            libraryService: libraryService,
            userVocabularyService: userVocabularyService,
            writingProgressService: writingProgressService,
            simpleVocabProgressService: simpleVocabProgressService
        )
    }
}
