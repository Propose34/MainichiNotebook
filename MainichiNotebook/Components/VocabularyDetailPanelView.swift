import SwiftUI

struct VocabularyDetailPanelView: View {
    let item: VocabularyItem?
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var studyUserLibraryService: StudyUserLibraryService
    @EnvironmentObject private var userVocabularyService: UserVocabularyService
    
    @State private var toastMessage: String? = nil
    @State private var showToast: Bool = false
    @State private var showingEditSheet: Bool = false
    @State private var showingDeleteAlert: Bool = false
    
    var body: some View {
        ZStack {
            if let word = item {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Main Japanese Header
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                HStack(spacing: 8) {
                                    Text(word.japanese)
                                        .font(AppTheme.fontSerif(size: 28, weight: .bold))
                                        .foregroundColor(AppTheme.textDark)
                                    
                                    Button(action: {
                                        let success = JapanesePronunciationService.shared.speakVocabulary(word)
                                        if !success {
                                            triggerToast("Japanese voice unavailable")
                                        }
                                    }) {
                                        Image(systemName: "speaker.wave.2")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(AppTheme.sakuraPink)
                                            .padding(6)
                                            .background(AppTheme.sakuraPinkLight)
                                            .clipShape(Circle())
                                    }
                                }
                                Spacer()
                                
                                // POS Badge
                                Text(word.partOfSpeech)
                                    .font(AppTheme.fontRounded(size: 9, weight: .bold))
                                    .foregroundColor(AppTheme.sakuraPink)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(AppTheme.sakuraPinkLight)
                                    .cornerRadius(6)
                            }
                            
                            Text(word.reading)
                                .font(AppTheme.fontSerif(size: 16))
                                .foregroundColor(AppTheme.textMuted)
                            
                            Text("[\(word.romaji)]")
                                .font(AppTheme.fontRounded(size: 14))
                                .foregroundColor(AppTheme.textMuted)
                        }
                        
                        Divider()
                        
                        // Thai Translation
                        VStack(alignment: .leading, spacing: 6) {
                            Text("THAI MEANING / ความหมาย")
                                .font(AppTheme.fontRounded(size: 10, weight: .bold))
                                .foregroundColor(AppTheme.textMuted)
                            
                            Text(word.meaningTh)
                                .font(AppTheme.fontRounded(size: 16, weight: .bold))
                                .foregroundColor(AppTheme.textDark)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.paperCard)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.borderLight, lineWidth: 1))
                        
                        // Example Sentence
                        if let exJp = word.exampleJp, !exJp.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("EXAMPLE SENTENCE / ประโยคตัวอย่าง")
                                    .font(AppTheme.fontRounded(size: 10, weight: .bold))
                                    .foregroundColor(AppTheme.textMuted)
                                
                                Text(exJp)
                                    .font(AppTheme.fontSerif(size: 15, weight: .bold))
                                    .foregroundColor(AppTheme.textDark)
                                    .lineSpacing(4)
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                if let exTh = word.exampleTh, !exTh.isEmpty {
                                    Text(exTh)
                                        .font(AppTheme.fontRounded(size: 13))
                                        .foregroundColor(AppTheme.textMuted)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppTheme.paperCard)
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.borderLight, lineWidth: 1))
                        }
                        
                        // Word Parts
                        if !word.wordParts.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("CONSTRUCTION / ส่วนประกอบคำ")
                                    .font(AppTheme.fontRounded(size: 10, weight: .bold))
                                    .foregroundColor(AppTheme.textMuted)
                                
                                FlowLayout(spacing: 6) {
                                    ForEach(word.wordParts, id: \.self) { part in
                                        Text(part)
                                            .font(AppTheme.fontRounded(size: 11, weight: .medium))
                                            .foregroundColor(AppTheme.textDark)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(AppTheme.paperBeige)
                                            .cornerRadius(6)
                                    }
                                }
                            }
                        }
                        
                        // Tags & Categories
                        VStack(alignment: .leading, spacing: 8) {
                            Text("TAGS & CATEGORY / แท็กและหมวดหมู่")
                                .font(AppTheme.fontRounded(size: 10, weight: .bold))
                                .foregroundColor(AppTheme.textMuted)
                            
                            FlowLayout(spacing: 6) {
                                // Level badge if exists
                                if let level = word.level {
                                    Text(level)
                                        .font(AppTheme.fontRounded(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(AppTheme.woodDark)
                                        .cornerRadius(6)
                                }
                                
                                // Category Badge
                                Text(word.primaryCategory)
                                    .font(AppTheme.fontRounded(size: 10, weight: .bold))
                                    .foregroundColor(AppTheme.darkNavy)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(AppTheme.paperBeige)
                                    .cornerRadius(6)
                                
                                ForEach(word.tags, id: \.self) { tag in
                                    Text("#" + tag)
                                        .font(AppTheme.fontRounded(size: 10))
                                        .foregroundColor(AppTheme.textMuted)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(AppTheme.paperCard)
                                        .cornerRadius(4)
                                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(AppTheme.borderLight, lineWidth: 1))
                                }
                            }
                        }
                        
                        // Builder Pattern
                        if let pattern = word.builderPattern, !pattern.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("PATTERN / รูปแบบสร้างคำ")
                                    .font(AppTheme.fontRounded(size: 10, weight: .bold))
                                    .foregroundColor(AppTheme.textMuted)
                                Text(pattern)
                                    .font(AppTheme.fontRounded(size: 12))
                                    .foregroundColor(AppTheme.textDark)
                                    .padding(8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(AppTheme.paperBeige.opacity(0.5))
                                    .cornerRadius(6)
                            }
                        }
                        
                        Spacer(minLength: 24)
                        
                        // Actions Group
                        let inFlashcards = studyUserLibraryService.isInFlashcards(targetType: .vocabulary, targetId: word.id)
                        let inMyList = studyUserLibraryService.isInMyList(targetType: .vocabulary, targetId: word.id)
                        
                        VStack(spacing: 10) {
                            Button(action: {
                                withAnimation {
                                    studyUserLibraryService.toggleFlashcardCollection(targetType: .vocabulary, targetId: word.id)
                                    if inFlashcards {
                                        triggerToast("Removed from Flash Cards")
                                    } else {
                                        triggerToast("Saved for future flashcard review")
                                    }
                                }
                            }) {
                                HStack {
                                    Image(systemName: inFlashcards ? "square.stack.3d.up.fill" : "square.stack.3d.up")
                                    Text(inFlashcards ? "Remove from Flash Cards" : "Add to Flash Cards")
                                }
                                .font(AppTheme.fontRounded(size: 13, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(inFlashcards ? AppTheme.woodDark : AppTheme.sakuraPink)
                                .cornerRadius(10)
                                .shadow(color: (inFlashcards ? AppTheme.woodDark : AppTheme.sakuraPink).opacity(0.2), radius: 4)
                            }
                            
                            Button(action: {
                                withAnimation {
                                    studyUserLibraryService.toggleMyList(targetType: .vocabulary, targetId: word.id)
                                    if inMyList {
                                        triggerToast("Removed from My List")
                                    } else {
                                        triggerToast("Saved to My List")
                                    }
                                }
                            }) {
                                HStack {
                                    Image(systemName: inMyList ? "checkmark.circle.fill" : "plus.circle.fill")
                                    Text(inMyList ? "In My List (Remove)" : "Add to My List")
                                }
                                .font(AppTheme.fontRounded(size: 13, weight: .bold))
                                .foregroundColor(inMyList ? AppTheme.sageGreen : AppTheme.darkNavy)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(AppTheme.paperCard)
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(inMyList ? AppTheme.sageGreen : AppTheme.borderLight, lineWidth: 1.5))
                            }
                        }
                        
                        if word.status == "custom" {
                            Divider()
                                .padding(.vertical, 4)
                            
                            HStack(spacing: 12) {
                                Button(action: {
                                    showingEditSheet = true
                                }) {
                                    HStack {
                                        Image(systemName: "pencil.circle")
                                        Text("Edit Word")
                                    }
                                    .font(AppTheme.fontRounded(size: 13, weight: .bold))
                                    .foregroundColor(AppTheme.darkNavy)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(AppTheme.paperCard)
                                    .cornerRadius(10)
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.borderLight, lineWidth: 1.5))
                                }
                                
                                Button(action: {
                                    showingDeleteAlert = true
                                }) {
                                    HStack {
                                        Image(systemName: "trash")
                                        Text("Delete")
                                    }
                                    .font(AppTheme.fontRounded(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.red.opacity(0.85))
                                    .cornerRadius(10)
                                    .shadow(color: Color.red.opacity(0.15), radius: 3)
                                }
                            }
                        }
                    }
                    .padding(20)
                }
                .sheet(isPresented: $showingEditSheet) {
                    AddEditWordSheet(wordToEdit: getEditingItem(word: word))
                }
                .alert("Delete Word?", isPresented: $showingDeleteAlert) {
                    Button("Cancel", role: .cancel) {}
                    Button("Delete", role: .destructive) {
                        executeDelete(wordId: word.id)
                    }
                } message: {
                    Text("Are you sure you want to permanently delete '\(word.japanese)'? This will also remove it from Favorites, My List, and Flash Cards.")
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "arrow.left.circle")
                        .font(.system(size: 32))
                        .foregroundColor(AppTheme.textMuted.opacity(0.6))
                    Text("Select a word")
                        .font(AppTheme.fontRounded(size: 15, weight: .bold))
                        .foregroundColor(AppTheme.textDark)
                    Text("Choose a vocabulary word from the left list to see full definition here.")
                        .font(AppTheme.fontRounded(size: 12))
                        .foregroundColor(AppTheme.textMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding()
            }
            
            // Toast notification
            if showToast, let msg = toastMessage {
                VStack {
                    Spacer()
                    Text(msg)
                        .font(AppTheme.fontRounded(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(AppTheme.darkNavy.opacity(0.9))
                        .cornerRadius(20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 24)
                }
                .animation(.spring(), value: showToast)
            }
        }
    }
    
    private func getEditingItem(word: VocabularyItem) -> UserVocabularyItem {
        if let original = userVocabularyService.userVocabularyItem(id: word.id) {
            return original
        }
        // Fallback mapping
        return UserVocabularyItem(
            id: word.id,
            japanese: word.japanese,
            reading: word.reading,
            romaji: word.romaji,
            meaningTh: word.meaningTh,
            partOfSpeech: word.partOfSpeech,
            level: word.level,
            primaryCategory: word.primaryCategory,
            categories: word.categories,
            tags: word.tags,
            exampleJp: word.exampleJp,
            exampleTh: word.exampleTh,
            notes: word.notes,
            wordParts: word.wordParts,
            builderPattern: word.builderPattern,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    private func executeDelete(wordId: String) {
        // Clean up bookmarks
        if studyUserLibraryService.isFavorite(targetType: .vocabulary, targetId: wordId) {
            studyUserLibraryService.toggleFavorite(targetType: .vocabulary, targetId: wordId)
        }
        if studyUserLibraryService.isInMyList(targetType: .vocabulary, targetId: wordId) {
            studyUserLibraryService.toggleMyList(targetType: .vocabulary, targetId: wordId)
        }
        if studyUserLibraryService.isInFlashcards(targetType: .vocabulary, targetId: wordId) {
            studyUserLibraryService.toggleFlashcardCollection(targetType: .vocabulary, targetId: wordId)
        }
        
        userVocabularyService.deleteUserVocabularyItem(id: wordId)
        
        // Dismiss screen if on iPhone navigation push
        dismiss()
    }
    
    private func triggerToast(_ message: String) {
        toastMessage = message
        withAnimation {
            showToast = true
        }
        // Auto dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation {
                showToast = false
            }
        }
    }
}

// A simple FlowLayout view builder to handle chips wrapping beautifully
struct FlowLayout: Layout {
    var spacing: CGFloat
    
    init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let width = proposal.width ?? 0
        
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var maxRowHeight: CGFloat = 0
        var totalWidth: CGFloat = 0
        
        for size in sizes {
            if currentX + size.width > width && currentX > 0 {
                currentX = 0
                currentY += maxRowHeight + spacing
                maxRowHeight = 0
            }
            currentX += size.width + spacing
            maxRowHeight = max(maxRowHeight, size.height)
            totalWidth = max(totalWidth, currentX)
        }
        
        return CGSize(width: totalWidth, height: currentY + maxRowHeight)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        var maxRowHeight: CGFloat = 0
        
        for (index, subview) in subviews.enumerated() {
            let size = sizes[index]
            if currentX + size.width > bounds.maxX && currentX > bounds.minX {
                currentX = bounds.minX
                currentY += maxRowHeight + spacing
                maxRowHeight = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: ProposedViewSize(size))
            currentX += size.width + spacing
            maxRowHeight = max(maxRowHeight, size.height)
        }
    }
}
