import SwiftUI
import UniformTypeIdentifiers

struct LecturesOverviewScreen: View {
    @Binding var selectedBook: LectureBook?
    
    @State private var booksList: [LectureBook] = []
    @State private var searchText: String = ""
    @State private var selectedChip: String = "All Subjects"
    @State private var showingFileImporter = false
    @State private var isAscendingSort = true
    @State private var showingCreateBookSheet = false
    @State private var bookToDelete: LectureBook? = nil
    @State private var showingDeleteAlert = false
    
    let chips = ["All Subjects", "In Progress", "Completed", "Favorites", "Sort"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Screen Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Lectures 🌸")
                        .font(AppTheme.fontSerif(size: 28, weight: .bold))
                        .foregroundColor(AppTheme.textDark)
                    
                    Text("Your library of knowledge.")
                        .font(AppTheme.fontRounded(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.textMuted)
                }
                Spacer()
                
                // Header icons matching Home Screen
                HStack(spacing: 12) {
                    HeaderIconButton(iconName: "calendar")
                    HeaderIconButton(iconName: "bell.badge", badgeCount: 3)
                    HeaderIconButton(iconName: "person.crop.circle")
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)
            
            // Search Bar & Filter Chips
            VStack(spacing: 12) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppTheme.textMuted.opacity(0.6))
                    
                    TextField("Search lectures, topics, or notes...", text: $searchText)
                        .font(AppTheme.fontRounded(size: 14))
                        .foregroundColor(AppTheme.textDark)
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(AppTheme.textMuted.opacity(0.6))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(AppTheme.paperBeige.opacity(0.4))
                .cornerRadius(12)
                .padding(.horizontal, 24)
                
                // Filter Chips Scroll
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(chips, id: \.self) { chip in
                            Button(action: {
                                if chip == "Sort" {
                                    isAscendingSort.toggle()
                                } else {
                                    selectedChip = chip
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Text(chip == "Sort" ? (isAscendingSort ? "Sort: A-Z" : "Sort: Z-A") : chip)
                                        .font(AppTheme.fontRounded(size: 13, weight: .medium))
                                    
                                    if chip == "Sort" {
                                        Image(systemName: isAscendingSort ? "arrow.up" : "arrow.down")
                                            .font(.system(size: 10, weight: .bold))
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(selectedChip == chip || (chip == "Sort" && selectedChip == "Sort") ? AppTheme.darkNavy : AppTheme.paperCard)
                                )
                                .foregroundColor(selectedChip == chip || (chip == "Sort" && selectedChip == "Sort") ? AppTheme.paperBackground : AppTheme.textDark)
                                .overlay(
                                    Capsule()
                                        .stroke(AppTheme.borderLight, lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 4)
                }
            }
            .padding(.bottom, 16)
            
            // Scrollable Bookshelf Content
            GeometryReader { geo in
                let columnsCount = geo.size.width > 600 ? 4 : 2
                let shelfWidth = geo.size.width - 48
                
                ScrollView {
                    VStack(spacing: 32) {
                        let shelfItems = getShelfItems()
                        let chunks = chunkShelfItems(shelfItems, size: columnsCount)
                        
                        ForEach(0..<chunks.count, id: \.self) { rowIndex in
                            VStack(spacing: 0) {
                                HStack(spacing: 20) {
                                    ForEach(chunks[rowIndex], id: \.id) { item in
                                        switch item {
                                        case .book(let book):
                                            Button(action: {
                                                selectedBook = book
                                            }) {
                                                NotebookCoverView(book: book, size: CGSize(width: (shelfWidth - CGFloat(columnsCount - 1) * 20) / CGFloat(columnsCount), height: geo.size.width > 600 ? 150 : 130))
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                            .contextMenu {
                                                Button(role: .destructive) {
                                                    bookToDelete = book
                                                    showingDeleteAlert = true
                                                } label: {
                                                    Label("Delete Notebook", systemImage: "trash")
                                                }
                                            }
                                            
                                        case .createBook:
                                            CreateBookCoverView(size: CGSize(width: (shelfWidth - CGFloat(columnsCount - 1) * 20) / CGFloat(columnsCount), height: geo.size.width > 600 ? 150 : 130)) {
                                                showingCreateBookSheet = true
                                            }
                                            
                                        case .addPDF:
                                            AddPDFCoverView(size: CGSize(width: (shelfWidth - CGFloat(columnsCount - 1) * 20) / CGFloat(columnsCount), height: geo.size.width > 600 ? 150 : 130)) {
                                                showingFileImporter = true
                                            }
                                        }
                                    }
                                    
                                    // Empty paddings to keep grid alignment
                                    let emptySlots = columnsCount - chunks[rowIndex].count
                                    if emptySlots > 0 {
                                        ForEach(0..<emptySlots, id: \.self) { _ in
                                            Spacer()
                                                .frame(width: (shelfWidth - CGFloat(columnsCount - 1) * 20) / CGFloat(columnsCount))
                                        }
                                    }
                                }
                                .padding(.horizontal, 24)
                                .padding(.bottom, 2)
                                
                                // Wooden shelf plank
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
                                    .shadow(color: Color.black.opacity(0.18), radius: 3, x: 0, y: 3)
                                    .padding(.horizontal, 16)
                            }
                        }
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 36)
                }
            }
        }
        .background(AppTheme.paperBackground)
        .onAppear {
            reloadBooks()
        }
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [UTType.pdf],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                if let _ = LectureStorageService.shared.importPDF(from: url) {
                    reloadBooks()
                }
            case .failure(let error):
                print("Failed to select PDF: \(error.localizedDescription)")
            }
        }
        .sheet(isPresented: $showingCreateBookSheet) {
            CreateBookSheet(isPresented: $showingCreateBookSheet) { title, subtitle, colorHex, emoji, subject in
                createNewBook(title: title, subtitle: subtitle, coverColorHex: colorHex, decorationEmoji: emoji, subject: subject)
            }
        }
        .alert("Delete Notebook", isPresented: $showingDeleteAlert, presenting: bookToDelete) { book in
            Button("Delete", role: .destructive) {
                LectureStorageService.shared.deleteBook(id: book.id)
                reloadBooks()
                bookToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                bookToDelete = nil
            }
        } message: { book in
            Text("Delete this lecture notebook \"\(book.title)\"? This cannot be undone.")
        }
    }
    
    private func reloadBooks() {
        booksList = LectureStorageService.shared.loadBooks()
    }
    
    private func createNewBook(title: String, subtitle: String, coverColorHex: String, decorationEmoji: String, subject: String) {
        let newBook = LectureBook(
            title: title,
            subtitle: subtitle,
            coverColorHex: coverColorHex,
            progress: 0.0,
            subject: subject,
            isFavorite: false,
            isCompleted: false,
            decorationEmoji: decorationEmoji
        )
        LectureStorageService.shared.saveBook(newBook)
        
        // Start new book with 1 blank Grid page (pre-create)
        let initialPage = LecturePage(pageNumber: 1, paperPreset: .grid)
        LectureStorageService.shared.savePages([initialPage], for: newBook.id)
        
        reloadBooks()
    }
    
    private func getShelfItems() -> [ShelfItem] {
        var items = filteredBooks().map { ShelfItem.book($0) }
        items.append(.createBook)
        items.append(.addPDF)
        return items
    }
    
    private func chunkShelfItems(_ items: [ShelfItem], size: Int) -> [[ShelfItem]] {
        var chunks: [[ShelfItem]] = []
        for i in stride(from: 0, to: items.count, by: size) {
            let end = min(i + size, items.count)
            chunks.append(Array(items[i..<end]))
        }
        return chunks
    }
    
    private func filteredBooks() -> [LectureBook] {
        var list = booksList
        
        // Search text filter
        if !searchText.isEmpty {
            list = list.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.subtitle.localizedCaseInsensitiveContains(searchText) ||
                $0.subject.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Chip selection filter
        switch selectedChip {
        case "In Progress":
            list = list.filter { $0.progress > 0.0 && $0.progress < 0.99 }
        case "Completed":
            list = list.filter { $0.progress >= 0.99 }
        case "Favorites":
            list = list.filter { $0.isFavorite }
        default:
            break
        }
        
        // Sort filter
        if isAscendingSort {
            list.sort { $0.title < $1.title }
        } else {
            list.sort { $0.title > $1.title }
        }
        
        return list
    }
}

// Private enum matching book cards and actions on the shelf
private enum ShelfItem: Identifiable {
    case book(LectureBook)
    case createBook
    case addPDF
    
    var id: String {
        switch self {
        case .book(let b): return b.id.uuidString
        case .createBook: return "createBook"
        case .addPDF: return "addPDF"
        }
    }
}

// Create blank notebook cover view
struct CreateBookCoverView: View {
    var size: CGSize
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(AppTheme.sakuraPink.opacity(0.6), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [5, 4]))
                    .background(AppTheme.sakuraPinkLight.opacity(0.15))
                    .frame(width: size.width, height: size.height)
                
                VStack(spacing: 8) {
                    Image(systemName: "plus.book.closed.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AppTheme.sakuraPink)
                    
                    Text("New Notebook")
                        .font(AppTheme.fontRounded(size: 11, weight: .bold))
                        .foregroundColor(AppTheme.textDark)
                    
                    Text("Create a blank lecture")
                        .font(AppTheme.fontRounded(size: 7, weight: .regular))
                        .foregroundColor(AppTheme.textMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 4)
                }
                .frame(width: size.width, height: size.height)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// PDF Import Book Card
struct AddPDFCoverView: View {
    var size: CGSize
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(AppTheme.textMuted.opacity(0.35), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [5, 4]))
                    .background(AppTheme.paperBeige.opacity(0.15))
                    .frame(width: size.width, height: size.height)
                
                VStack(spacing: 8) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 24))
                        .foregroundColor(AppTheme.textMuted.opacity(0.6))
                    
                    Text("Add PDF")
                        .font(AppTheme.fontRounded(size: 11, weight: .bold))
                        .foregroundColor(AppTheme.textDark)
                    
                    Text("Import PDF as a lecture")
                        .font(AppTheme.fontRounded(size: 7, weight: .regular))
                        .foregroundColor(AppTheme.textMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 4)
                }
                .frame(width: size.width, height: size.height)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Cozy Custom Sheet for creating a book
struct CreateBookSheet: View {
    @Binding var isPresented: Bool
    var onCreate: (String, String, String, String, String) -> Void
    
    @State private var title: String = ""
    @State private var subtitle: String = ""
    @State private var subject: String = "Language"
    @State private var coverColorHex: String = "EAA09B"
    @State private var decorationEmoji: String = "🌸"
    
    let subjects = ["Language", "Grammar", "Listening", "Kanji", "Culture", "Arts", "Science", "Humanities"]
    
    let coverColors = [
        ("Sakura Pink", "EAA09B"),
        ("Sage Green", "8A9A86"),
        ("Cozy Beige", "DFD7C7"),
        ("Steel Blue", "9AB3C2"),
        ("Warm Mustard", "DCC096"),
        ("Sand Clay", "DECBB7"),
        ("Dark Navy", "1C2A3A")
    ]
    
    let emojis = ["🌸", "🌿", "🎧", "🧠", "⛩️", "📚", "✍️", "🍵", "🎌", "✏️"]
    
    var body: some View {
        ZStack {
            AppTheme.paperBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Text("Create Notebook")
                            .font(AppTheme.fontSerif(size: 24, weight: .bold))
                            .foregroundColor(AppTheme.textDark)
                        Spacer()
                        Button {
                            isPresented = false
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(AppTheme.textMuted.opacity(0.6))
                        }
                    }
                    .padding(.bottom, 8)
                    
                    // Preview Cover
                    VStack(spacing: 8) {
                        Text("Preview Cover")
                            .font(AppTheme.fontRounded(size: 13, weight: .bold))
                            .foregroundColor(AppTheme.textMuted)
                        
                        NotebookCoverView(
                            book: LectureBook(
                                title: title.isEmpty ? "Notebook Title" : title,
                                subtitle: subtitle.isEmpty ? "Subtitle" : subtitle,
                                coverColorHex: coverColorHex,
                                progress: 0.0,
                                subject: subject,
                                isFavorite: false,
                                isCompleted: false,
                                decorationEmoji: decorationEmoji
                            ),
                            size: CGSize(width: 120, height: 165)
                        )
                        .padding(10)
                        .background(AppTheme.paperCard)
                        .cornerRadius(12)
                        .shadow(color: AppTheme.shadowColor, radius: 6)
                    }
                    
                    // Form fields
                    VStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Title")
                                .font(AppTheme.fontRounded(size: 13, weight: .bold))
                                .foregroundColor(AppTheme.textDark)
                            
                            TextField("Enter title (e.g. JLPT N4 Grammar)", text: $title)
                                .font(AppTheme.fontRounded(size: 14))
                                .padding(12)
                                .background(AppTheme.paperCard)
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.borderLight, lineWidth: 1))
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Subtitle (Japanese title optional)")
                                .font(AppTheme.fontRounded(size: 13, weight: .bold))
                                .foregroundColor(AppTheme.textDark)
                            
                            TextField("Enter subtitle (e.g. 日本語文法)", text: $subtitle)
                                .font(AppTheme.fontRounded(size: 14))
                                .padding(12)
                                .background(AppTheme.paperCard)
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.borderLight, lineWidth: 1))
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Subject")
                                .font(AppTheme.fontRounded(size: 13, weight: .bold))
                                .foregroundColor(AppTheme.textDark)
                            
                            HStack {
                                Picker("Subject", selection: $subject) {
                                    ForEach(subjects, id: \.self) { sub in
                                        Text(sub).tag(sub)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .padding(6)
                                .background(AppTheme.paperCard)
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.borderLight, lineWidth: 1))
                                
                                Spacer()
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Cover Color")
                                .font(AppTheme.fontRounded(size: 13, weight: .bold))
                                .foregroundColor(AppTheme.textDark)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(coverColors, id: \.1) { name, hex in
                                        Circle()
                                            .fill(Color(hex: hex))
                                            .frame(width: 36, height: 36)
                                            .overlay(
                                                Circle()
                                                    .stroke(coverColorHex == hex ? AppTheme.darkNavy : Color.clear, lineWidth: 3)
                                            )
                                            .onTapGesture {
                                                coverColorHex = hex
                                            }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Cover Ornament Emoji")
                                .font(AppTheme.fontRounded(size: 13, weight: .bold))
                                .foregroundColor(AppTheme.textDark)
                            
                            HStack(spacing: 10) {
                                ForEach(emojis, id: \.self) { emoji in
                                    Text(emoji)
                                        .font(.system(size: 22))
                                        .padding(8)
                                        .background(decorationEmoji == emoji ? AppTheme.sakuraPinkLight : Color.clear)
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(decorationEmoji == emoji ? AppTheme.sakuraPink.opacity(0.6) : Color.clear, lineWidth: 1)
                                        )
                                        .onTapGesture {
                                            decorationEmoji = emoji
                                        }
                                }
                            }
                        }
                    }
                    .padding(20)
                    .background(AppTheme.paperCard)
                    .cornerRadius(16)
                    .shadow(color: AppTheme.shadowColor, radius: 4)
                    
                    HStack(spacing: 16) {
                        Button {
                            isPresented = false
                        } label: {
                            Text("Cancel")
                                .font(AppTheme.fontRounded(size: 15, weight: .bold))
                                .foregroundColor(AppTheme.textMuted)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppTheme.paperCard)
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.borderLight, lineWidth: 1))
                        }
                        
                        Button {
                            guard !title.isEmpty else { return }
                            onCreate(title, subtitle, coverColorHex, decorationEmoji, subject)
                            isPresented = false
                        } label: {
                            Text("Create Notebook")
                                .font(AppTheme.fontRounded(size: 15, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(title.isEmpty ? AppTheme.textMuted.opacity(0.4) : AppTheme.sakuraPink)
                                .cornerRadius(10)
                        }
                        .disabled(title.isEmpty)
                    }
                    .padding(.top, 8)
                }
                .padding(24)
            }
        }
    }
}

