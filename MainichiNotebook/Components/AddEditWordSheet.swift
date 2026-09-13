import SwiftUI

struct AddEditWordSheet: View {
    let wordToEdit: UserVocabularyItem?
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var userVocabularyService: UserVocabularyService
    @EnvironmentObject private var studyUserLibraryService: StudyUserLibraryService
    @EnvironmentObject private var studyDataService: StudyDataService
    
    // Form fields
    @State private var japanese: String = ""
    @State private var reading: String = ""
    @State private var romaji: String = ""
    @State private var meaningTh: String = ""
    
    @State private var partOfSpeech: String = "noun"
    @State private var customPartOfSpeech: String = ""
    
    @State private var level: String = "N5"
    
    @State private var selectedCategoryId: String = "all-vocabulary"
    @State private var customCategory: String = ""
    
    @State private var tagsText: String = ""
    @State private var exampleJp: String = ""
    @State private var exampleTh: String = ""
    @State private var notes: String = ""
    
    // Quick Add Toggles
    @State private var isFavorite: Bool = false
    @State private var isInMyList: Bool = false
    @State private var isInFlashCards: Bool = false
    
    // Alerts and Confirmation
    @State private var showingValidationAlert: Bool = false
    @State private var validationAlertMessage: String = ""
    @State private var showingDuplicateWarning: Bool = false
    
    let partsOfSpeechList = ["noun", "verb", "i-adjective", "na-adjective", "adverb", "conjunction", "particle", "phrase", "custom"]
    let levelsList = ["N5", "N4", "N3", "N2", "N1", "None"]
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.paperBackground.ignoresSafeArea()
                
                Form {
                    Section(header: Text("Word Basics (Required)").font(AppTheme.fontRounded(size: 11, weight: .bold))) {
                        TextField("Japanese (e.g. 食べる, 青い)", text: $japanese)
                            .font(AppTheme.fontRounded(size: 14))
                            .autocorrectionDisabled()
                        
                        TextField("Thai Meaning (e.g. กิน, สีน้ำเงิน)", text: $meaningTh)
                            .font(AppTheme.fontRounded(size: 14))
                        
                        TextField("Reading / Hiragana (e.g. たべる, あおい)", text: $reading)
                            .font(AppTheme.fontRounded(size: 14))
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                        
                        TextField("Romaji (e.g. taberu, aoi)", text: $romaji)
                            .font(AppTheme.fontRounded(size: 14))
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                    .listRowBackground(AppTheme.paperCard)
                    
                    Section(header: Text("Classifications").font(AppTheme.fontRounded(size: 11, weight: .bold))) {
                        Picker("Word Type", selection: $partOfSpeech) {
                            ForEach(partsOfSpeechList, id: \.self) { pos in
                                Text(pos).tag(pos)
                            }
                        }
                        .font(AppTheme.fontRounded(size: 14))
                        
                        if partOfSpeech == "custom" {
                            TextField("Enter custom word type", text: $customPartOfSpeech)
                                .font(AppTheme.fontRounded(size: 14))
                        }
                        
                        Picker("JLPT Level", selection: $level) {
                            ForEach(levelsList, id: \.self) { lvl in
                                Text(lvl).tag(lvl)
                            }
                        }
                        .font(AppTheme.fontRounded(size: 14))
                        
                        Picker("Category", selection: $selectedCategoryId) {
                            Text("Custom / None").tag("custom")
                            ForEach(studyDataService.categories.filter { !$0.isVirtual }) { cat in
                                Text(cat.nameEn).tag(cat.id)
                            }
                        }
                        .font(AppTheme.fontRounded(size: 14))
                        
                        if selectedCategoryId == "custom" {
                            TextField("Enter custom category name", text: $customCategory)
                                .font(AppTheme.fontRounded(size: 14))
                        }
                        
                        TextField("Tags (comma separated, e.g. food, verb)", text: $tagsText)
                            .font(AppTheme.fontRounded(size: 14))
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                    .listRowBackground(AppTheme.paperCard)
                    
                    Section(header: Text("Example & Notes").font(AppTheme.fontRounded(size: 11, weight: .bold))) {
                        TextField("Example Japanese Sentence", text: $exampleJp)
                            .font(AppTheme.fontRounded(size: 14))
                            .autocorrectionDisabled()
                        
                        TextField("Example Translation (Thai)", text: $exampleTh)
                            .font(AppTheme.fontRounded(size: 14))
                        
                        ZStack(alignment: .topLeading) {
                            if notes.isEmpty {
                                Text("Study Notes (e.g. usage tips, conjugation rules)")
                                    .font(AppTheme.fontRounded(size: 14))
                                    .foregroundColor(Color.gray.opacity(0.5))
                                    .padding(.top, 8)
                            }
                            TextEditor(text: $notes)
                                .font(AppTheme.fontRounded(size: 14))
                                .frame(minHeight: 80)
                                .padding(.top, 2)
                        }
                    }
                    .listRowBackground(AppTheme.paperCard)
                    
                    Section(header: Text("Collections").font(AppTheme.fontRounded(size: 11, weight: .bold))) {
                        Toggle("Mark as Favorite ⭐️", isOn: $isFavorite)
                            .font(AppTheme.fontRounded(size: 14, weight: .medium))
                        Toggle("Add to My List ➕", isOn: $isInMyList)
                            .font(AppTheme.fontRounded(size: 14, weight: .medium))
                        Toggle("Add to Flash Cards 📇", isOn: $isInFlashCards)
                            .font(AppTheme.fontRounded(size: 14, weight: .medium))
                    }
                    .listRowBackground(AppTheme.paperCard)
                }
                .background(Color.clear)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(wordToEdit == nil ? "Add Vocabulary" : "Edit Vocabulary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(AppTheme.fontRounded(size: 15))
                    .foregroundColor(AppTheme.textMuted)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        validateAndSave()
                    }
                    .font(AppTheme.fontRounded(size: 15, weight: .bold))
                    .foregroundColor(AppTheme.sakuraPink)
                }
            }
            .onAppear {
                prefillFormIfNeeded()
            }
            .alert("Missing Fields", isPresented: $showingValidationAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(validationAlertMessage)
            }
            .alert("Duplicate Word Warning", isPresented: $showingDuplicateWarning) {
                Button("Cancel", role: .cancel) {}
                Button("Save Anyway") {
                    executeSave()
                }
            } message: {
                Text("This word might already exist in your library (same Japanese and reading). Do you want to save it anyway?")
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Prefill Form
    
    private func prefillFormIfNeeded() {
        guard let item = wordToEdit else { return }
        japanese = item.japanese
        reading = item.reading
        romaji = item.romaji
        meaningTh = item.meaningTh
        
        if partsOfSpeechList.contains(item.partOfSpeech) {
            partOfSpeech = item.partOfSpeech
        } else {
            partOfSpeech = "custom"
            customPartOfSpeech = item.partOfSpeech
        }
        
        level = item.level ?? "None"
        
        if studyDataService.categories.contains(where: { $0.id == item.primaryCategory }) {
            selectedCategoryId = item.primaryCategory
        } else {
            selectedCategoryId = "custom"
            customCategory = item.primaryCategory
        }
        
        tagsText = item.tags.joined(separator: ", ")
        exampleJp = item.exampleJp ?? ""
        exampleTh = item.exampleTh ?? ""
        notes = item.notes ?? ""
        
        // Sync collections from user library service
        isFavorite = studyUserLibraryService.isFavorite(targetType: .vocabulary, targetId: item.id)
        isInMyList = studyUserLibraryService.isInMyList(targetType: .vocabulary, targetId: item.id)
        isInFlashCards = studyUserLibraryService.isInFlashcards(targetType: .vocabulary, targetId: item.id)
    }
    
    // MARK: - Validation
    
    private func validateAndSave() {
        let trimmedJp = japanese.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedMean = meaningTh.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedReading = reading.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedRomaji = romaji.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedJp.isEmpty {
            validationAlertMessage = "Please enter the Japanese word."
            showingValidationAlert = true
            return
        }
        
        if trimmedMean.isEmpty {
            validationAlertMessage = "Please enter the Thai translation."
            showingValidationAlert = true
            return
        }
        
        if trimmedReading.isEmpty && trimmedRomaji.isEmpty {
            validationAlertMessage = "Please provide at least a kana Reading or Romaji helper to assist pronunciation."
            showingValidationAlert = true
            return
        }
        
        // Check for duplicates
        let hasDuplicate = checkForDuplicates()
        if hasDuplicate {
            showingDuplicateWarning = true
        } else {
            executeSave()
        }
    }
    
    private func checkForDuplicates() -> Bool {
        let trimmedJp = japanese.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let trimmedReading = reading.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // Don't warn if editing the same item and not changing Japanese/Reading
        if let editing = wordToEdit {
            if editing.japanese.lowercased() == trimmedJp && editing.reading.lowercased() == trimmedReading {
                return false
            }
        }
        
        // 1. Search seed vocabulary
        let seedMatch = studyDataService.vocabularyItems.contains { item in
            item.japanese.lowercased() == trimmedJp && item.reading.lowercased() == trimmedReading
        }
        if seedMatch { return true }
        
        // 2. Search user vocabulary
        let userMatch = userVocabularyService.userItems.contains { item in
            item.japanese.lowercased() == trimmedJp && item.reading.lowercased() == trimmedReading
        }
        return userMatch
    }
    
    // MARK: - Physical Save
    
    private func executeSave() {
        let finalId = wordToEdit?.id ?? "user_\(Date().timeIntervalSince1970)_\(UUID().uuidString.prefix(4))"
        let finalPos = partOfSpeech == "custom" ? customPartOfSpeech.trimmingCharacters(in: .whitespacesAndNewlines) : partOfSpeech
        let finalCategory = selectedCategoryId == "custom" ? customCategory.trimmingCharacters(in: .whitespacesAndNewlines) : selectedCategoryId
        let finalLevel = level == "None" ? nil : level
        
        let parsedTags = tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        let now = Date()
        
        let item = UserVocabularyItem(
            id: finalId,
            japanese: japanese.trimmingCharacters(in: .whitespacesAndNewlines),
            reading: reading.trimmingCharacters(in: .whitespacesAndNewlines),
            romaji: romaji.trimmingCharacters(in: .whitespacesAndNewlines),
            meaningTh: meaningTh.trimmingCharacters(in: .whitespacesAndNewlines),
            partOfSpeech: finalPos.isEmpty ? "noun" : finalPos,
            level: finalLevel,
            primaryCategory: finalCategory.isEmpty ? "custom" : finalCategory,
            categories: [finalCategory.isEmpty ? "custom" : finalCategory],
            tags: parsedTags,
            exampleJp: exampleJp.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : exampleJp.trimmingCharacters(in: .whitespacesAndNewlines),
            exampleTh: exampleTh.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : exampleTh.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes.trimmingCharacters(in: .whitespacesAndNewlines),
            wordParts: [],
            builderPattern: nil,
            createdAt: wordToEdit?.createdAt ?? now,
            updatedAt: now
        )
        
        if wordToEdit == nil {
            userVocabularyService.addUserVocabularyItem(item)
        } else {
            userVocabularyService.updateUserVocabularyItem(item)
        }
        
        // Save bookmarks states
        syncBookmarks(targetId: finalId)
        
        dismiss()
    }
    
    private func syncBookmarks(targetId: String) {
        // Sync favorite
        let currentFav = studyUserLibraryService.isFavorite(targetType: .vocabulary, targetId: targetId)
        if currentFav != isFavorite {
            studyUserLibraryService.toggleFavorite(targetType: .vocabulary, targetId: targetId)
        }
        
        // Sync myList
        let currentList = studyUserLibraryService.isInMyList(targetType: .vocabulary, targetId: targetId)
        if currentList != isInMyList {
            studyUserLibraryService.toggleMyList(targetType: .vocabulary, targetId: targetId)
        }
        
        // Sync flashcard
        let currentFC = studyUserLibraryService.isInFlashcards(targetType: .vocabulary, targetId: targetId)
        if currentFC != isInFlashCards {
            studyUserLibraryService.toggleFlashcardCollection(targetType: .vocabulary, targetId: targetId)
        }
    }
}
