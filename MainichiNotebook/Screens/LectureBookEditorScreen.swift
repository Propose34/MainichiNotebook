import SwiftUI
import PencilKit
import PhotosUI
import PDFKit
import QuickLook

// MARK: - Active Sheet Enum (fixes picker-cancel freeze)

private enum ActiveSheet: Identifiable {
    case stickerPalette
    case shareExport(items: [Any])
    case templateLibrary

    var id: String {
        switch self {
        case .stickerPalette:    return "stickerPalette"
        case .shareExport:       return "shareExport"
        case .templateLibrary:   return "templateLibrary"
        }
    }
}

// MARK: - Editor Screen

struct LectureBookEditorScreen: View {
    let book: LectureBook
    @Binding var isSidebarCollapsed: Bool
    var onBack: () -> Void

    @EnvironmentObject private var templateService: PaperTemplateService

    // MARK: Core page state
    @State private var pages: [LecturePage] = []
    @State private var selectedPage: Int = 1
    @State private var activeBook: LectureBook? = nil

    // MARK: Drawing state — single source of truth
    @State private var currentDrawing: PKDrawing = PKDrawing()
    @State private var toolState: DrawingToolState = DrawingToolState()
    @StateObject private var canvasController = PencilCanvasController()

    // MARK: Sheet / picker state — single enum replaces 3 separate Bools
    @State private var activeSheet: ActiveSheet? = nil
    @State private var showingFileAttachmentPicker: Bool = false   // fileImporter needs own Bool
    @State private var showingAttachmentsDrawer: Bool = false      // Inline panel, not a sheet
    @State private var showingPDFPageImporter: Bool = false        // Import PDF as pages

    // MARK: Page management
    @State private var pageToDelete: LecturePage? = nil
    @State private var showingDeleteConfirmation: Bool = false
    @State private var showingBookDeleteConfirmation: Bool = false

    // MARK: Photos picker (separate from sheets — not a .sheet modifier)
    @State private var selectedPhotoItem: PhotosPickerItem? = nil

    // MARK: Tool settings pass 2
    @State private var showingSettingsPanel: Bool = false
    @State private var savedColors: [String] = [
        "131B26", "3D5A80", "8A9A86", "B56B5D",
        "FEEA9A", "F8BBD0", "C8E6C9", "B3E5FC"
    ]
    @State private var customSelectedColor: Color = Color(hex: "131B26")

    // MARK: Polish pass 3 state
    @State private var saveTask: Task<Void, Never>? = nil
    @State private var mockTaper: CGFloat = 0.0
    @State private var mockSmoothing: CGFloat = 0.8

    // MARK: Polish pass 4 state
    @State private var toastMessage: String? = nil
    @State private var previewURL: URL? = nil

    // MARK: Polish pass 5 (Pen Experience Polish) state
    @State private var previewDrawing: PKDrawing = PKDrawing()
    @State private var showingAddFavoriteAlert: Bool = false
    @State private var newFavoriteName: String = ""
    @State private var toolbarIsExpanded: Bool = false
    @State private var settingsTab: SettingsTab = .penStyle
    @State private var favoriteToDelete: FavoriteToolItem? = nil
    @State private var presetSlotToReset: Int? = nil
    @State private var favoriteToRename: FavoriteToolItem? = nil
    @State private var renamedFavoriteName: String = ""
    @State private var presetToRenameIndex: Int? = nil
    @State private var renamedPresetName: String = ""

    // MARK: Focus Mode State
    @State private var toolbarIsHidden: Bool = {
        UserDefaults.standard.bool(forKey: "com.mainichi.toolbarIsHidden")
    }()
    @State private var restoreButtonPosition: RestoreButtonPosition = {
        if let raw = UserDefaults.standard.string(forKey: "com.mainichi.restoreButtonPosition"),
           let pos = RestoreButtonPosition(rawValue: raw) {
            return pos
        }
        return .bottomRight
    }()
    @State private var restoreButtonDragOffset: CGSize = .zero
    @State private var zoomFitTrigger = UUID()

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            editorHeader
            Divider()
            topEditingToolbar
            Divider()
            paperPresetRow
            Divider()

            HStack(spacing: 0) {
                leftPageStrip
                Divider()

                ZStack(alignment: toolbarIsHidden ? restoreButtonAlignment : .bottom) {
                    paperCanvasArea
                    
                    if toolbarIsHidden {
                        floatingRestoreButton
                            .offset(restoreButtonDragOffset)
                            .padding(16)
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        floatingBottomToolTray
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .background(AppTheme.paperBackground)

                if showingAttachmentsDrawer {
                    Divider()
                    attachmentsDrawerPanel
                }
            }
        }
        .background(AppTheme.paperBackground)
        .alert("Save Favorite Tool", isPresented: $showingAddFavoriteAlert) {
            TextField("Name (e.g. Red Grammar Pen)", text: $newFavoriteName)
            Button("Save") {
                toolState.addCurrentAsFavorite(name: newFavoriteName)
                newFavoriteName = ""
            }
            Button("Cancel", role: .cancel) {
                newFavoriteName = ""
            }
        } message: {
            Text("Enter a name for this favorite tool combination.")
        }
        .alert("Delete Favorite?", isPresented: Binding(
            get: { favoriteToDelete != nil },
            set: { if !$0 { favoriteToDelete = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let fav = favoriteToDelete {
                    withAnimation {
                        toolState.deleteFavorite(id: fav.id)
                    }
                    showToast(message: "Favorite '\(fav.name)' removed.")
                }
                favoriteToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                favoriteToDelete = nil
            }
        } message: {
            if let fav = favoriteToDelete {
                Text("Are you sure you want to remove the favorite '\(fav.name)'?")
            }
        }
        .alert("Reset Preset Slot?", isPresented: Binding(
            get: { presetSlotToReset != nil },
            set: { if !$0 { presetSlotToReset = nil } }
        )) {
            Button("Reset to Default", role: .destructive) {
                if let idx = presetSlotToReset {
                    let name = toolState.penPresets[idx].name
                    withAnimation {
                        toolState.resetPresetToDefault(index: idx)
                    }
                    showToast(message: "Preset slot '\(name)' reset to default.")
                }
                presetSlotToReset = nil
            }
            Button("Cancel", role: .cancel) {
                presetSlotToReset = nil
            }
        } message: {
            if let idx = presetSlotToReset {
                let name = toolState.penPresets[idx].name
                Text("Are you sure you want to reset the preset slot '\(name)' back to its default configurations?")
            }
        }
        .alert("Rename Favorite", isPresented: Binding(
            get: { favoriteToRename != nil },
            set: { if !$0 { favoriteToRename = nil } }
        )) {
            TextField("Name", text: $renamedFavoriteName)
            Button("Save") {
                if let fav = favoriteToRename {
                    toolState.renameFavorite(id: fav.id, newName: renamedFavoriteName)
                    showToast(message: "Favorite renamed to '\(renamedFavoriteName)'")
                }
                favoriteToRename = nil
            }
            Button("Cancel", role: .cancel) {
                favoriteToRename = nil
            }
        } message: {
            if let fav = favoriteToRename {
                Text("Enter a new name for the favorite tool '\(fav.name)'.")
            }
        }
        .alert("Rename Preset Slot", isPresented: Binding(
            get: { presetToRenameIndex != nil },
            set: { if !$0 { presetToRenameIndex = nil } }
        )) {
            TextField("Preset Name", text: $renamedPresetName)
            Button("Rename") {
                if let idx = presetToRenameIndex {
                    toolState.penPresets[idx].name = renamedPresetName
                    toolState.savePresets()
                    showToast(message: "Preset slot renamed to '\(renamedPresetName)'")
                }
                presetToRenameIndex = nil
            }
            Button("Cancel", role: .cancel) {
                presetToRenameIndex = nil
            }
        } message: {
            if let idx = presetToRenameIndex {
                Text("Enter a new name for preset slot \(idx + 1).")
            }
        }

        // MARK: Single sheet handler (fixes cancel freeze)
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .stickerPalette:
                StickerPaletteView(isPresented: Binding(
                    get: { activeSheet != nil },
                    set: { if !$0 { activeSheet = nil } }
                )) { emoji in
                    addStickerAnnotation(emoji)
                    activeSheet = nil
                }

            case .shareExport(let items):
                ShareSheet(activityItems: items)
                    .onDisappear { activeSheet = nil }

            case .templateLibrary:
                PaperTemplatePickerView(
                    onApplyToCurrent: { template in
                        applyTemplateToCurrentPage(template)
                    },
                    onAddNewPage: { template in
                        addNewPageWithTemplate(template)
                    }
                )
            }
        }



        // MARK: Photos picker handler
        .onChange(of: selectedPhotoItem) { _ in
            guard let newItem = selectedPhotoItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    let imageName = "\(UUID().uuidString).jpg"
                    if LectureStorageService.shared.saveInsertedImage(data: data, bookId: book.id, imageName: imageName) != nil {
                        let annotation = AnnotationItem(type: .image, content: imageName, width: 220, height: 165)
                        if !pages.isEmpty && selectedPage >= 1 && selectedPage <= pages.count {
                            pages[selectedPage - 1].annotations.append(annotation)
                            savePagesList()
                        }
                    }
                }
                selectedPhotoItem = nil
            }
        }

        // MARK: Auto-save on drawing change
        .onChange(of: currentDrawing) { _ in
            guard !pages.isEmpty && selectedPage >= 1 && selectedPage <= pages.count else { return }
            let pageId = pages[selectedPage - 1].id
            LectureStorageService.shared.saveDrawing(currentDrawing, bookId: book.id, pageId: pageId)
        }

        // MARK: Color synchronization
        .onChange(of: customSelectedColor) { _ in
            if let hex = customSelectedColor.toHex() {
                if toolState.colorHex != hex {
                    toolState.selectColor(hex)
                }
            }
        }
        .onChange(of: toolState.colorHex) { _ in
            let newColor = Color(hex: toolState.colorHex)
            if customSelectedColor != newColor {
                customSelectedColor = newColor
            }
        }

        // MARK: Initial load
        .onAppear {
            if activeBook == nil {
                activeBook = book
            }
            pages = LectureStorageService.shared.loadPages(for: book.id)
            if selectedPage > pages.count || selectedPage < 1 { selectedPage = 1 }
            if !pages.isEmpty && selectedPage >= 1 && selectedPage <= pages.count {
                let pageId = pages[selectedPage - 1].id
                currentDrawing = LectureStorageService.shared.loadDrawing(bookId: book.id, pageId: pageId)
            }
            customSelectedColor = Color(hex: toolState.colorHex)
        }

        // MARK: Delete page alert
        .alert("Delete Page", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                if let page = pageToDelete { deletePage(page) }
            }
            Button("Cancel", role: .cancel) { pageToDelete = nil }
        } message: {
            Text("Delete Page \(pageToDelete?.pageNumber ?? 0)? All drawing and annotations will be removed.")
        }
        
        // MARK: Delete notebook alert
        .alert("Delete Notebook", isPresented: $showingBookDeleteConfirmation) {
            let active = activeBook ?? book
            Button("Delete", role: .destructive) {
                LectureStorageService.shared.deleteBook(id: active.id)
                onBack()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            let active = activeBook ?? book
            Text("Delete this lecture notebook \"\(active.title)\"? This cannot be undone.")
        }
        
        // MARK: Quick Look Preview
        .quickLookPreview($previewURL)
        
        // MARK: Toast Notification Overlay
        .overlay(
            Group {
                if let message = toastMessage {
                    VStack {
                        Spacer()
                        Text(message)
                            .font(AppTheme.fontRounded(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.8))
                                    .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 3)
                            )
                            .padding(.bottom, 60)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.25), value: toastMessage)
        )
    }

    // MARK: - Header

    @ViewBuilder
    private var editorHeader: some View {
        HStack {
            HStack(spacing: 16) {
                Button {
                    saveCurrentPageData()
                    onBack()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .bold))
                        Text("Lectures")
                            .font(AppTheme.fontRounded(size: 15, weight: .semibold))
                    }
                    .foregroundColor(AppTheme.sakuraPink)
                }
                
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isSidebarCollapsed.toggle()
                    }
                } label: {
                    Image(systemName: "sidebar.left")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppTheme.sakuraPink)
                        .padding(6)
                        .background(Circle().fill(isSidebarCollapsed ? Color.clear : AppTheme.sakuraPinkLight))
                }
                .buttonStyle(PlainButtonStyle())
            }

            Spacer()

            VStack(spacing: 2) {
                let active = activeBook ?? book
                Text(active.title)
                    .font(AppTheme.fontSerif(size: 16, weight: .bold))
                    .foregroundColor(AppTheme.textDark)
                Text(active.subtitle)
                    .font(AppTheme.fontSerif(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.textMuted)
            }

            Spacer()

            HStack(spacing: 16) {
                Button {
                    withAnimation { showingAttachmentsDrawer.toggle() }
                } label: {
                    Image(systemName: "paperclip.badge.ellipsis")
                        .font(.system(size: 16))
                        .foregroundColor(showingAttachmentsDrawer ? AppTheme.sakuraPink : AppTheme.textMuted)
                }

                Button(action: exportCurrentPage) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16))
                        .foregroundColor(AppTheme.textMuted)
                }

                Button {
                    showingBookDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                        .foregroundColor(AppTheme.sakuraPink)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 12)
        .background(AppTheme.paperBackground)
    }

    // MARK: - Top Editing Toolbar

    @ViewBuilder
    private var topEditingToolbar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ToolbarButton(title: "Stickers", iconName: "face.smiling.fill") {
                    activeSheet = .stickerPalette
                }

                ToolbarButton(title: "Post-it", iconName: "note.text") {
                    addPostItAnnotation()
                }

                PhotosPicker(
                    selection: $selectedPhotoItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    HStack(spacing: 6) {
                        Image(systemName: "photo")
                            .font(.system(size: 13))
                        Text("Image")
                            .font(AppTheme.fontRounded(size: 12, weight: .semibold))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(AppTheme.paperCard)
                    .foregroundColor(AppTheme.textDark)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.borderLight, lineWidth: 0.8))
                }

                ToolbarButton(title: "Text", iconName: "textformat") {
                    addTextAnnotation()
                }

                let attachmentsCount = (!pages.isEmpty && selectedPage >= 1 && selectedPage <= pages.count) ? pages[selectedPage - 1].attachments.count : 0
                ToolbarButton(
                    title: attachmentsCount > 0 ? "Attach File (\(attachmentsCount))" : "Attach File",
                    iconName: "paperclip"
                ) {
                    showingFileAttachmentPicker = true
                }
                .fileImporter(
                    isPresented: $showingFileAttachmentPicker,
                    allowedContentTypes: [.item],
                    allowsMultipleSelection: false
                ) { result in
                    showingFileAttachmentPicker = false
                    switch result {
                    case .success(let urls):
                        guard let url = urls.first else { return }
                        let active = activeBook ?? book
                        if let attachment = LectureStorageService.shared.saveAttachment(fileURL: url, bookId: active.id) {
                            guard !pages.isEmpty && selectedPage >= 1 && selectedPage <= pages.count else { return }
                            pages[selectedPage - 1].attachments.append(attachment)
                            savePagesList()
                            showToast(message: "File attached to this page. Open it from Attachments.")
                        }
                    case .failure(let error):
                        print("File attachment error: \(error.localizedDescription)")
                    }
                }
                
                ToolbarButton(title: "Import PDF as Pages", iconName: "doc.badge.plus") {
                    showingPDFPageImporter = true
                }
                .fileImporter(
                    isPresented: $showingPDFPageImporter,
                    allowedContentTypes: [.pdf],
                    allowsMultipleSelection: false
                ) { result in
                    showingPDFPageImporter = false
                    switch result {
                    case .success(let urls):
                        guard let url = urls.first else { return }
                        importPDFPagesAction(url: url)
                    case .failure(let error):
                        print("PDF page importer error: \(error.localizedDescription)")
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
        }
        .background(AppTheme.paperBeige.opacity(0.3))
    }

    // MARK: - Paper Preset Row

    @ViewBuilder
    private var paperPresetRow: some View {
        if !pages.isEmpty && selectedPage >= 1 && selectedPage <= pages.count {
            HStack(spacing: 0) {
                let currentPreset = pages[selectedPage - 1].paperPreset
                PaperPresetPicker(currentPreset: currentPreset) { newPreset in
                    pages[selectedPage - 1].paperPreset = newPreset
                    pages[selectedPage - 1].paperTemplateId = nil
                    pages[selectedPage - 1].customTemplateFileName = nil
                    pages[selectedPage - 1].customTemplateKind = nil
                    savePagesList()
                }
                
                Spacer()
                
                Button {
                    activeSheet = .templateLibrary
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "square.grid.3x3.fill")
                            .font(.system(size: 13))
                        Text("Template Library")
                            .font(AppTheme.fontRounded(size: 11, weight: .bold))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AppTheme.sakuraPink.opacity(0.1))
                    .foregroundColor(AppTheme.sakuraPink)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(AppTheme.sakuraPink.opacity(0.3), lineWidth: 1)
                    )
                }
                .padding(.trailing, 16)
                .buttonStyle(PlainButtonStyle())
            }
            .background(AppTheme.paperBeige.opacity(0.15))
        }
    }

    // MARK: - Left Page Strip

    @ViewBuilder
    private var leftPageStrip: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Pages")
                    .font(AppTheme.fontRounded(size: 12, weight: .bold))
                    .foregroundColor(AppTheme.textMuted)
                Spacer()
                Button(action: addNewPage) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppTheme.sakuraPink)
                        .padding(4)
                        .background(Circle().fill(AppTheme.paperCard))
                        .shadow(color: AppTheme.shadowColor, radius: 2)
                }
            }
            .padding(.horizontal, 12)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(pages.indices, id: \.self) { index in
                        pageThumbCell(for: pages[index])
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .frame(width: 84)
        .padding(.top, 16)
        .background(AppTheme.paperBeige.opacity(0.15))
    }

    @ViewBuilder
    private func pageThumbCell(for page: LecturePage) -> some View {
        let idx = page.pageNumber
        VStack(spacing: 4) {
            ZStack(alignment: .topTrailing) {
                Button { changePage(to: idx) } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(AppTheme.paperCard)
                            .frame(width: 60, height: 80)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(
                                        selectedPage == idx ? AppTheme.sakuraPink : AppTheme.borderLight,
                                        lineWidth: selectedPage == idx ? 2 : 1
                                    )
                            )
                            .shadow(color: Color.black.opacity(0.05), radius: 2)

                        if book.isPDF {
                            Image(systemName: "doc.richtext")
                                .font(.system(size: 18))
                                .foregroundColor(AppTheme.textMuted.opacity(0.5))
                        } else {
                            GridPaperView(spacing: 8, lineColor: AppTheme.sageGreen.opacity(0.12))
                                .frame(width: 50, height: 70)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())

                if selectedPage == idx && pages.count > 1 {
                    Button {
                        pageToDelete = page
                        showingDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.red)
                            .background(Circle().fill(Color.white))
                    }
                    .offset(x: 4, y: -4)
                }
            }

            Text("\(idx)")
                .font(AppTheme.fontRounded(size: 10, weight: .bold))
                .foregroundColor(selectedPage == idx ? AppTheme.sakuraPink : AppTheme.textMuted)
        }
    }

    // MARK: - Canvas Area

    @ViewBuilder
    private var paperCanvasArea: some View {
        let currentPageId = !pages.isEmpty && selectedPage >= 1 && selectedPage <= pages.count ? pages[selectedPage - 1].id : UUID()
        ZoomablePaperScrollView(pageId: currentPageId, fitTrigger: $zoomFitTrigger, width: 800, height: 1040) {
            ZStack(alignment: .topLeading) {
                // Paper background
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppTheme.paperCard)
                    .frame(width: 720, height: 960)
                    .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 5)

                paperBackground
                    .frame(width: 720, height: 960)

                // Annotation overlays
                if !pages.isEmpty && selectedPage >= 1 && selectedPage <= pages.count {
                    ForEach(pages[selectedPage - 1].annotations.indices, id: \.self) { index in
                        DraggableOverlayWrapper(
                            item: $pages[selectedPage - 1].annotations[index],
                            isSelectMoveMode: toolState.isSelectMoveMode,
                            onDelete: {
                                pages[selectedPage - 1].annotations.remove(at: index)
                                savePagesList()
                            },
                            onDragEnded: {
                                savePagesListDebounced()
                            }
                        ) {
                            annotationContentView(for: pages[selectedPage - 1].annotations[index])
                        }
                    }
                }

                // Drawing canvas — hit testing disabled during Select/Move mode
                PencilCanvasView(
                    drawing: $currentDrawing,
                    toolState: $toolState,
                    controller: canvasController
                )
                .frame(width: 720, height: 960)
                .allowsHitTesting(toolState.isDrawingMode)
            }
            .frame(width: 720, height: 960)
            .coordinateSpace(name: "canvas")
            .padding(40)
        }
    }

    // MARK: - Paper Background per preset

    @ViewBuilder
    private var paperBackground: some View {
        if !pages.isEmpty && selectedPage >= 1 && selectedPage <= pages.count {
            let page = pages[selectedPage - 1]
            if let templateId = page.paperTemplateId {
                if let customFileName = page.customTemplateFileName {
                    let fileURL = templateService.getTemplateFileURL(fileName: customFileName)
                    if page.customTemplateKind == PaperTemplateKind.importedPDF.rawValue {
                        PDFPageBackgroundView(pdfURL: fileURL, pageIndex: 0, canvasSize: CGSize(width: 720, height: 960))
                            .id("\(page.id.uuidString)_template_\(customFileName)")
                    } else {
                        if let uiImage = UIImage(contentsOfFile: fileURL.path) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 720, height: 960)
                                .clipped()
                                .id("\(page.id.uuidString)_template_\(customFileName)")
                        } else {
                            Color.white
                        }
                    }
                } else {
                    let presetId = templateService.templates.first(where: { $0.id == templateId })?.builtInPresetId ?? templateId
                    BuiltInPaperTemplateBackgroundView(presetId: presetId)
                        .id("\(page.id.uuidString)_template_\(presetId)")
                }
            } else {
                let active = activeBook ?? book
                if active.isPDF,
                   let pdfFileName = active.pdfFileName,
                   let pdfPageIdx = page.pdfPageNumber {
                    let pdfURL = LectureStorageService.shared.getPDFUrl(bookId: active.id, pdfFileName: pdfFileName)
                    PDFPageBackgroundView(pdfURL: pdfURL, pageIndex: pdfPageIdx, canvasSize: CGSize(width: 720, height: 960))
                        .id(page.id)
                } else {
                    currentPaperView
                }
            }
        } else {
            currentPaperView
        }
    }

    @ViewBuilder
    private var currentPaperView: some View {
        let preset = (pages.isEmpty || selectedPage < 1 || selectedPage > pages.count)
            ? PaperPreset.grid
            : pages[selectedPage - 1].paperPreset

        switch preset {
        case .blank:
            Color.white
        case .ruled:
            RuledPaperView(spacing: 26)
        case .grid:
            GridPaperView(spacing: 22)
        case .dotGrid:
            DotGridPaperView(spacing: 22)
        case .genkouYoushi:
            GenkouYoushiView()
        case .kana:
            KanaPracticeView()
        case .kanji:
            KanjiPracticeView()
        }
    }

    // MARK: - Bottom Tool Tray

    @ViewBuilder
    private var compactBottomToolbar: some View {
        HStack(spacing: 12) {
            // Selected Tool Indicator with icon
            HStack(spacing: 6) {
                Image(systemName: toolState.tool.icon)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppTheme.sakuraPink)
                Text(toolState.tool.label)
                    .font(AppTheme.fontRounded(size: 11, weight: .bold))
                    .foregroundColor(AppTheme.textDark)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(AppTheme.sakuraPinkLight))
            
            Divider().frame(height: 20)
            
            // Undo/Redo compact
            HStack(spacing: 8) {
                Button { canvasController.undo() } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(canvasController.canUndo ? AppTheme.textDark : AppTheme.textMuted.opacity(0.4))
                }
                .disabled(!canvasController.canUndo)
                
                Button { canvasController.redo() } label: {
                    Image(systemName: "arrow.uturn.forward")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(canvasController.canRedo ? AppTheme.textDark : AppTheme.textMuted.opacity(0.4))
                }
                .disabled(!canvasController.canRedo)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(RoundedRectangle(cornerRadius: 6).fill(AppTheme.paperBeige.opacity(0.4)))
            
            Divider().frame(height: 20)
            
            // Top 4 Favorites (compact badges)
            HStack(spacing: 6) {
                ForEach(toolState.favorites.prefix(4)) { fav in
                    Button {
                        withAnimation {
                            toolState.applyFavorite(fav)
                        }
                    } label: {
                        HStack(spacing: 4) {
                            if fav.tool == .eraser {
                                Image(systemName: "eraser.line.dashed")
                                    .font(.system(size: 8))
                                    .foregroundColor(AppTheme.textDark)
                            } else {
                                Circle()
                                    .fill(Color(hex: fav.colorHex))
                                    .frame(width: 8, height: 8)
                            }
                            
                            Text(fav.name.prefix(8))
                                .font(AppTheme.fontRounded(size: 9, weight: .bold))
                                .foregroundColor(AppTheme.textDark)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(isFavoriteActive(fav) ? AppTheme.sakuraPinkLight : AppTheme.paperBeige.opacity(0.4))
                        )
                        .overlay(
                            Capsule()
                                .stroke(isFavoriteActive(fav) ? AppTheme.sakuraPink : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .contextMenu {
                        Button {
                            renamedFavoriteName = fav.name
                            favoriteToRename = fav
                        } label: {
                            Label("Rename Favorite", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            favoriteToDelete = fav
                        } label: {
                            Label("Delete Favorite", systemImage: "trash")
                        }
                    }
                }
            }
            
            Spacer()
            
            // Color Indicator (opens expanded settings panel)
            if toolState.showsColorAndWidth {
                Button {
                    withAnimation {
                        toolbarIsExpanded = true
                        showingSettingsPanel = true
                    }
                } label: {
                    Circle()
                        .fill(Color(hex: toolState.colorHex))
                        .frame(width: 18, height: 18)
                        .overlay(
                            Circle().stroke(Color.white, lineWidth: 1.5)
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 1)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Settings Slider Icon
            Button {
                withAnimation {
                    toolbarIsExpanded = true
                    showingSettingsPanel = true
                }
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.textMuted)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Hide Button
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    toolbarIsHidden = true
                    UserDefaults.standard.set(true, forKey: "com.mainichi.toolbarIsHidden")
                }
            } label: {
                Image(systemName: "eye.slash")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.textMuted)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expand Button
            Button {
                withAnimation {
                    toolbarIsExpanded = true
                }
            } label: {
                Image(systemName: "chevron.up.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(AppTheme.sakuraPink)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    private var restoreButtonAlignment: Alignment {
        switch restoreButtonPosition {
        case .topLeft:     return .topLeading
        case .topRight:    return .topTrailing
        case .bottomLeft:  return .bottomLeading
        case .bottomRight: return .bottomTrailing
        }
    }

    @ViewBuilder
    private var floatingRestoreButton: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                toolbarIsHidden = false
                UserDefaults.standard.set(false, forKey: "com.mainichi.toolbarIsHidden")
            }
        } label: {
            ZStack {
                Circle()
                    .fill(AppTheme.paperCard)
                    .frame(width: 46, height: 46)
                    .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)
                    .overlay(Circle().stroke(AppTheme.borderLight, lineWidth: 1.5))
                
                Image(systemName: "pencil.tip.crop.circle")
                    .font(.system(size: 24))
                    .foregroundColor(AppTheme.sakuraPink)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .gesture(
            DragGesture()
                .onChanged { value in
                    restoreButtonDragOffset = value.translation
                }
                .onEnded { value in
                    let isRight = (restoreButtonPosition == .topRight || restoreButtonPosition == .bottomRight)
                    let isBottom = (restoreButtonPosition == .bottomLeft || restoreButtonPosition == .bottomRight)
                    
                    let startX: CGFloat = isRight ? 360 : -360
                    let startY: CGFloat = isBottom ? 480 : -480
                    
                    let finalX = startX + value.translation.width
                    let finalY = startY + value.translation.height
                    
                    let targetRight = finalX >= 0
                    let targetBottom = finalY >= 0
                    
                    let targetPosition: RestoreButtonPosition
                    if targetRight {
                        targetPosition = targetBottom ? .bottomRight : .topRight
                    } else {
                        targetPosition = targetBottom ? .bottomLeft : .topLeft
                    }
                    
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        restoreButtonPosition = targetPosition
                        restoreButtonDragOffset = .zero
                    }
                    UserDefaults.standard.set(targetPosition.rawValue, forKey: "com.mainichi.restoreButtonPosition")
                }
        )
    }

    @ViewBuilder
    private var floatingBottomToolTray: some View {
        VStack(spacing: 0) {
            if toolbarIsExpanded {
                // Collapsible settings panel (sliders, picker, custom palette)
                if showingSettingsPanel && toolState.showsColorAndWidth {
                    settingsPanel
                        .padding(.bottom, 12)
                    Divider()
                        .padding(.bottom, 10)
                }

                // Contextual preset selector row
                if toolState.showsColorAndWidth {
                    presetSelectorRow
                        .padding(.bottom, 8)
                }

                // Favorites quick access row
                if toolState.isDrawingMode {
                    favoritesRow
                        .padding(.bottom, 8)
                }

                // Main tray row
                mainToolRow
            } else {
                compactBottomToolbar
            }
        }
        .padding(.horizontal, toolbarIsExpanded ? 20 : 0)
        .padding(.vertical, toolbarIsExpanded ? 10 : 0)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.paperCard)
                .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
        )
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.borderLight, lineWidth: 1))
        .padding(.bottom, 20)
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private var presetSelectorRow: some View {
        HStack(spacing: 12) {
            HStack(spacing: 4) {
                Image(systemName: "slider.horizontal.below.rectangle")
                    .font(.system(size: 11))
                Text("Presets")
                    .font(AppTheme.fontRounded(size: 10, weight: .bold))
            }
            .foregroundColor(AppTheme.textMuted)
            .frame(width: 75, alignment: .leading)

            if toolState.tool == .pen {
                ForEach(0..<3, id: \.self) { idx in
                    let preset = toolState.penPresets[idx]
                    let isSelected = toolState.selectedPenPresetIndex == idx
                    let presetColor = Color(hex: preset.colorHex)
                    
                    Button {
                        toolState.selectPenPreset(index: idx)
                    } label: {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(presetColor)
                                .frame(width: max(3.0, min(14.0, preset.thickness * 0.8)), height: max(3.0, min(14.0, preset.thickness * 0.8)))
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text(preset.name)
                                    .font(AppTheme.fontRounded(size: 10, weight: .bold))
                                    .lineLimit(1)
                                Text(String(format: "%.1f pt • %@", preset.thickness, preset.penType.label))
                                    .font(AppTheme.fontRounded(size: 8, weight: .semibold))
                                    .lineLimit(1)
                            }
                            .foregroundColor(isSelected ? AppTheme.textDark : AppTheme.textMuted)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(isSelected ? presetColor.opacity(0.15) : AppTheme.paperBeige.opacity(0.4))
                        )
                        .overlay(
                            Capsule().stroke(isSelected ? presetColor : Color.clear, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .contextMenu {
                        Button {
                            withAnimation {
                                toolState.selectedPenPresetIndex = idx
                                toolState.saveCurrentToPreset()
                            }
                            showToast(message: "Saved active tool settings to Slot \(idx + 1)!")
                        } label: {
                            Label("Save Current to Slot", systemImage: "square.and.arrow.down")
                        }
                        Button {
                            renamedPresetName = preset.name
                            presetToRenameIndex = idx
                        } label: {
                            Label("Rename Slot", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            presetSlotToReset = idx
                        } label: {
                            Label("Reset to Default", systemImage: "arrow.counterclockwise")
                        }
                    }
                }
            } else {
                let activeWidths = toolState.tool == .pencil ? toolState.pencilPresetWidths : toolState.highlighterPresetWidths
                let activeIndex = toolState.tool == .pencil ? toolState.selectedPencilPresetIndex : toolState.selectedHighlighterPresetIndex
                let activeColor = Color(hex: toolState.colorHex)
                
                ForEach(0..<3, id: \.self) { idx in
                    let width = activeWidths[idx]
                    let isSelected = activeIndex == idx
                    
                    Button {
                        if toolState.tool == .pencil {
                            toolState.selectedPencilPresetIndex = idx
                            toolState.strokeWidth = width
                        } else if toolState.tool == .highlighter {
                            toolState.selectedHighlighterPresetIndex = idx
                            toolState.strokeWidth = width
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(isSelected ? activeColor : AppTheme.textMuted)
                                .frame(width: max(3.0, min(14.0, width * 0.8)), height: max(3.0, min(14.0, width * 0.8)))
                            
                            Text(String(format: "%.1f pt", width))
                                .font(AppTheme.fontRounded(size: 11, weight: .bold))
                                .foregroundColor(isSelected ? AppTheme.textDark : AppTheme.textMuted)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(isSelected ? activeColor.opacity(0.15) : AppTheme.paperBeige.opacity(0.4))
                        )
                        .overlay(
                            Capsule().stroke(isSelected ? activeColor : Color.clear, lineWidth: 1.2)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    @ViewBuilder
    private var favoritesRow: some View {
        HStack(spacing: 10) {
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .foregroundColor(AppTheme.sakuraPink)
                    .font(.system(size: 11))
                Text("Favorites")
                    .font(AppTheme.fontRounded(size: 10, weight: .bold))
            }
            .foregroundColor(AppTheme.textMuted)
            .frame(width: 75, alignment: .leading)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(toolState.favorites) { fav in
                        Button {
                            withAnimation {
                                toolState.applyFavorite(fav)
                            }
                        } label: {
                            HStack(spacing: 5) {
                                if fav.tool == .eraser {
                                    Image(systemName: "eraser.line.dashed")
                                        .font(.system(size: 8))
                                        .foregroundColor(AppTheme.textDark)
                                } else {
                                    Circle()
                                        .fill(Color(hex: fav.colorHex))
                                        .frame(width: 8, height: 8)
                                }
                                
                                Text(fav.name)
                                    .font(AppTheme.fontRounded(size: 10, weight: .bold))
                                    .foregroundColor(AppTheme.textDark)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(isFavoriteActive(fav) ? AppTheme.sakuraPinkLight : AppTheme.paperBeige.opacity(0.4))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(isFavoriteActive(fav) ? AppTheme.sakuraPink : Color.clear, lineWidth: 1.2)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .contextMenu {
                            Button {
                                renamedFavoriteName = fav.name
                                favoriteToRename = fav
                            } label: {
                                Label("Rename Favorite", systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                favoriteToDelete = fav
                            } label: {
                                Label("Delete Favorite", systemImage: "trash")
                            }
                        }
                    }
                    
                    // Add Favorite button
                    Button {
                        newFavoriteName = ""
                        showingAddFavoriteAlert = true
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "plus")
                                .font(.system(size: 9, weight: .bold))
                            Text("Save Current")
                                .font(AppTheme.fontRounded(size: 10, weight: .bold))
                        }
                        .foregroundColor(AppTheme.sakuraPink)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .stroke(AppTheme.sakuraPink, style: StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round, dash: [3]))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func isFavoriteActive(_ fav: FavoriteToolItem) -> Bool {
        guard toolState.tool == fav.tool else { return false }
        if fav.tool == .eraser { return true }
        if fav.tool == .pen && toolState.activePenType != fav.penType { return false }
        
        let colorDiff = toolState.colorHex.lowercased() == fav.colorHex.lowercased()
        let opacityDiff = abs(toolState.opacity - fav.opacity) < 0.05
        let widthDiff = abs(toolState.strokeWidth - fav.thickness) < 0.2
        
        return colorDiff && opacityDiff && widthDiff
    }

    @ViewBuilder
    private var settingsPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Tab Selector Picker
            Picker("Settings Section", selection: $settingsTab) {
                ForEach(SettingsTab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.bottom, 2)
            
            // Tab Contents
            switch settingsTab {
            case .penStyle:
                // Pen Tester & Preview Area
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Pen Tester & Preview")
                            .font(AppTheme.fontRounded(size: 11, weight: .bold))
                            .foregroundColor(AppTheme.textMuted)
                        
                        Spacer()
                        
                        Button {
                            previewDrawing = PKDrawing()
                        } label: {
                            Text("Clear Preview")
                                .font(AppTheme.fontRounded(size: 10, weight: .bold))
                                .foregroundColor(AppTheme.sakuraPink)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(AppTheme.paperBeige.opacity(0.6))
                            .frame(height: 80)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(AppTheme.borderLight, lineWidth: 1)
                            )
                        
                        if previewDrawing.strokes.isEmpty {
                            Text("Scribble here to test pen...")
                                .font(AppTheme.fontRounded(size: 11, weight: .medium))
                                .foregroundColor(AppTheme.textMuted.opacity(0.5))
                        }
                        
                        MiniPreviewCanvasView(drawing: $previewDrawing, toolState: $toolState)
                            .frame(height: 80)
                            .cornerRadius(10)
                    }
                }
                .padding(.bottom, 4)

                // Pen Type Selector (only shown for Pen tool)
                if toolState.tool == .pen {
                    HStack(spacing: 12) {
                        Image(systemName: "pencil.circle")
                            .foregroundColor(AppTheme.textMuted)
                            .frame(width: 24)
                        
                        Text("Pen Style:")
                            .font(AppTheme.fontRounded(size: 12, weight: .bold))
                            .foregroundColor(AppTheme.textDark)
                            .frame(width: 75, alignment: .leading)
                        
                        HStack(spacing: 8) {
                            ForEach(PenType.allCases) { type in
                                let isSelected = toolState.activePenType == type
                                Button {
                                    toolState.setPenType(type)
                                } label: {
                                    Text(type.label)
                                        .font(AppTheme.fontRounded(size: 11, weight: .bold))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(
                                            Capsule().fill(isSelected ? AppTheme.sakuraPinkLight : AppTheme.paperBeige.opacity(0.4))
                                        )
                                        .foregroundColor(isSelected ? AppTheme.sakuraPink : AppTheme.textMuted)
                                        .overlay(
                                            Capsule().stroke(isSelected ? AppTheme.sakuraPink : Color.clear, lineWidth: 1)
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
                
                // Slider 1: Thickness
                HStack(spacing: 12) {
                    Image(systemName: "line.horizontal.3.decrease")
                        .foregroundColor(AppTheme.textMuted)
                        .frame(width: 24)
                    
                    Text("Size:")
                        .font(AppTheme.fontRounded(size: 12, weight: .bold))
                        .foregroundColor(AppTheme.textDark)
                        .frame(width: 75, alignment: .leading)
                    
                    Slider(
                        value: Binding(
                            get: { toolState.strokeWidth },
                            set: { toolState.strokeWidth = $0 }
                        ),
                        in: toolState.minThickness...toolState.maxThickness
                    )
                    .accentColor(AppTheme.sakuraPink)
                    
                    Text(String(format: "%.1f pt", toolState.strokeWidth))
                        .font(AppTheme.fontRounded(size: 12, weight: .bold))
                        .foregroundColor(AppTheme.textDark)
                        .frame(width: 50, alignment: .trailing)
                }
                
                // Slider 2: Opacity
                HStack(spacing: 12) {
                    Image(systemName: "square.grid.3x1.below.line.grid.1x2")
                        .foregroundColor(AppTheme.textMuted)
                        .frame(width: 24)
                    
                    Text("Opacity:")
                        .font(AppTheme.fontRounded(size: 12, weight: .bold))
                        .foregroundColor(AppTheme.textDark)
                        .frame(width: 75, alignment: .leading)
                    
                    Slider(
                        value: Binding(
                            get: { toolState.opacity },
                            set: { toolState.setOpacity($0) }
                        ),
                        in: 0.1...1.0
                    )
                    .accentColor(AppTheme.sakuraPink)
                    
                    Text(String(format: "%d%%", Int(toolState.opacity * 100)))
                        .font(AppTheme.fontRounded(size: 12, weight: .bold))
                        .foregroundColor(AppTheme.textDark)
                        .frame(width: 50, alignment: .trailing)
                }
                
                // Experimental Sharpness & Smoothing (PencilKit managed)
                if toolState.tool == .pen || toolState.tool == .pencil {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 12) {
                            Image(systemName: "gauge.with.needle")
                                .foregroundColor(AppTheme.textMuted)
                                .frame(width: 24)
                            
                            Text("Taper:")
                                .font(AppTheme.fontRounded(size: 11, weight: .bold))
                                .foregroundColor(AppTheme.textMuted)
                                .frame(width: 75, alignment: .leading)
                            
                            Slider(value: $mockTaper, in: 0.0...1.0)
                                .accentColor(AppTheme.sageGreen)
                                .disabled(true) // Native PK dynamic
                            
                            Text("Automatic")
                                .font(AppTheme.fontRounded(size: 10, weight: .medium))
                                .foregroundColor(AppTheme.textMuted)
                                .frame(width: 60, alignment: .trailing)
                        }
                        .opacity(0.6)
                        
                        HStack(spacing: 12) {
                            Image(systemName: "waveform.path")
                                .foregroundColor(AppTheme.textMuted)
                                .frame(width: 24)
                            
                            Text("Smooth:")
                                .font(AppTheme.fontRounded(size: 11, weight: .bold))
                                .foregroundColor(AppTheme.textMuted)
                                .frame(width: 75, alignment: .leading)
                            
                            Slider(value: $mockSmoothing, in: 0.0...1.0)
                                .accentColor(AppTheme.sageGreen)
                                .disabled(true)
                            
                            Text("Automatic")
                                .font(AppTheme.fontRounded(size: 10, weight: .medium))
                                .foregroundColor(AppTheme.textMuted)
                                .frame(width: 60, alignment: .trailing)
                        }
                        .opacity(0.6)
                        
                        Text("ℹ️ Taper and smoothing are managed automatically by iPadOS PencilKit.")
                            .font(AppTheme.fontRounded(size: 10, weight: .medium))
                            .foregroundColor(AppTheme.textMuted)
                            .padding(.leading, 36)
                    }
                    .padding(.top, 4)
                }
                
            case .presets:
                if toolState.tool == .pen {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Presets (Slot Customization)")
                            .font(AppTheme.fontRounded(size: 12, weight: .bold))
                            .foregroundColor(AppTheme.textDark)
                        
                        HStack(spacing: 12) {
                            ForEach(0..<3, id: \.self) { idx in
                                let preset = toolState.penPresets[idx]
                                let isSelected = toolState.selectedPenPresetIndex == idx
                                let presetColor = Color(hex: preset.colorHex)
                                
                                Button {
                                    toolState.selectPenPreset(index: idx)
                                } label: {
                                    VStack(spacing: 4) {
                                        Circle()
                                            .fill(presetColor)
                                            .frame(width: 14, height: 14)
                                        Text(preset.name)
                                            .font(AppTheme.fontRounded(size: 10, weight: .bold))
                                            .foregroundColor(isSelected ? AppTheme.textDark : AppTheme.textMuted)
                                        Text(String(format: "%.1f pt • %@", preset.thickness, preset.penType.label))
                                            .font(AppTheme.fontRounded(size: 8, weight: .semibold))
                                            .foregroundColor(AppTheme.textMuted)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(isSelected ? presetColor.opacity(0.12) : AppTheme.paperBeige.opacity(0.4))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(isSelected ? presetColor : Color.clear, lineWidth: 1.5)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .contextMenu {
                                    Button {
                                        withAnimation {
                                            toolState.selectedPenPresetIndex = idx
                                            toolState.saveCurrentToPreset()
                                        }
                                        showToast(message: "Saved active tool settings to Slot \(idx + 1)!")
                                    } label: {
                                        Label("Save Current to Slot", systemImage: "square.and.arrow.down")
                                    }
                                    Button {
                                        renamedPresetName = preset.name
                                        presetToRenameIndex = idx
                                    } label: {
                                        Label("Rename Slot", systemImage: "pencil")
                                    }
                                    Button(role: .destructive) {
                                        presetSlotToReset = idx
                                    } label: {
                                        Label("Reset to Default", systemImage: "arrow.counterclockwise")
                                    }
                                }
                            }
                        }
                        
                        Divider().padding(.vertical, 2)
                        
                        HStack(spacing: 12) {
                            Image(systemName: "pencil.and.outline")
                                .foregroundColor(AppTheme.textMuted)
                                .frame(width: 24)
                            
                            Text("Name:")
                                .font(AppTheme.fontRounded(size: 11, weight: .bold))
                                .foregroundColor(AppTheme.textDark)
                            
                            TextField("Preset Name", text: Binding(
                                get: { toolState.penPresets[toolState.clampedPenIndex].name },
                                set: { 
                                    toolState.penPresets[toolState.clampedPenIndex].name = $0
                                    toolState.savePresets()
                                }
                            ))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(AppTheme.fontRounded(size: 11, weight: .semibold))
                            .frame(width: 130)
                            
                            Spacer()
                            
                            Button {
                                withAnimation {
                                    toolState.saveCurrentToPreset()
                                }
                                showToast(message: "Saved to Slot \(toolState.selectedPenPresetIndex + 1)!")
                            } label: {
                                Text("Save Current")
                                    .font(AppTheme.fontRounded(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(AppTheme.sakuraPink)
                                    .cornerRadius(6)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Button {
                                presetSlotToReset = toolState.selectedPenPresetIndex
                            } label: {
                                Text("Reset Slot")
                                    .font(AppTheme.fontRounded(size: 10, weight: .bold))
                                    .foregroundColor(AppTheme.textDark)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(AppTheme.paperBeige)
                                    .cornerRadius(6)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 20))
                            .foregroundColor(AppTheme.textMuted)
                        Text("Presets are only available for the Pen tool.")
                            .font(AppTheme.fontRounded(size: 11, weight: .medium))
                            .foregroundColor(AppTheme.textMuted)
                    }
                    .frame(maxWidth: .infinity, minHeight: 100)
                }
                
            case .favorites:
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Quick Favorites Shortcuts")
                            .font(AppTheme.fontRounded(size: 12, weight: .bold))
                            .foregroundColor(AppTheme.textDark)
                        
                        Spacer()
                        
                        Button {
                            newFavoriteName = ""
                            showingAddFavoriteAlert = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Active Tool")
                            }
                            .font(AppTheme.fontRounded(size: 10, weight: .bold))
                            .foregroundColor(AppTheme.sakuraPink)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    if toolState.favorites.isEmpty {
                        Text("No favorites saved yet.")
                            .font(AppTheme.fontRounded(size: 11, weight: .medium))
                            .foregroundColor(AppTheme.textMuted)
                            .frame(maxWidth: .infinity, minHeight: 80, alignment: .center)
                    } else {
                        ScrollView(.vertical, showsIndicators: true) {
                            VStack(spacing: 8) {
                                ForEach(toolState.favorites) { fav in
                                    HStack {
                                        if fav.tool == .eraser {
                                            Image(systemName: "eraser.line.dashed")
                                                .font(.system(size: 12))
                                                .foregroundColor(AppTheme.textDark)
                                                .frame(width: 20)
                                        } else {
                                            Circle()
                                                .fill(Color(hex: fav.colorHex))
                                                .frame(width: 12, height: 12)
                                                .frame(width: 20)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(fav.name)
                                                .font(AppTheme.fontRounded(size: 11, weight: .bold))
                                                .foregroundColor(AppTheme.textDark)
                                            
                                            Text(String(format: "%@ • %.1f pt • %d%% Opacity", fav.tool.label, fav.thickness, Int(fav.opacity * 100)))
                                                .font(AppTheme.fontRounded(size: 9, weight: .medium))
                                                .foregroundColor(AppTheme.textMuted)
                                        }
                                        
                                        Spacer()
                                        
                                        Button {
                                            withAnimation {
                                                toolState.applyFavorite(fav)
                                            }
                                        } label: {
                                            Text("Apply")
                                                .font(AppTheme.fontRounded(size: 10, weight: .bold))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 4)
                                                .background(AppTheme.sageGreen)
                                                .cornerRadius(5)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        
                                        Button {
                                            favoriteToDelete = fav
                                        } label: {
                                            Image(systemName: "trash")
                                                .font(.system(size: 11))
                                                .foregroundColor(.red)
                                                .padding(6)
                                                .background(Circle().fill(Color.red.opacity(0.1)))
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(RoundedRectangle(cornerRadius: 8).fill(AppTheme.paperBeige.opacity(0.3)))
                                }
                            }
                            .padding(.trailing, 4)
                        }
                        .frame(maxHeight: 120)
                    }
                }
            }

            Divider().padding(.vertical, 2)
            
            // Color Picker & Saved Palette (Always visible at the bottom of settingsPanel)
            HStack(spacing: 12) {
                Image(systemName: "paintpalette")
                    .foregroundColor(AppTheme.textMuted)
                    .frame(width: 24)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(savedColors, id: \.self) { hex in
                            Button {
                                toolState.selectColor(hex)
                            } label: {
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Circle()
                                            .stroke(toolState.colorHex == hex ? Color.white : Color.clear, lineWidth: 1.5)
                                            .padding(2)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(toolState.colorHex == hex ? AppTheme.sakuraPink : Color.clear, lineWidth: 1.5)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.vertical, 2)
                }
                
                Divider().frame(height: 20)
                
                ColorPicker("", selection: $customSelectedColor, supportsOpacity: false)
                    .labelsHidden()
                    .frame(width: 28, height: 28)
                
                Button {
                    let hex = customSelectedColor.toHex() ?? "000000"
                    if !savedColors.contains(hex) {
                        savedColors.append(hex)
                    }
                    toolState.selectColor(hex)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(AppTheme.sakuraPink)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 4)
    }

    @ViewBuilder
    private var mainToolRow: some View {
        HStack(spacing: 16) {
            // Undo / Redo
            undoRedoGroup

            Divider().frame(height: 28)

            // Tool selector
            toolSelectorGroup

            // Color swatches (only for inking tools)
            if toolState.showsColorAndWidth {
                Divider().frame(height: 28)
                colorSwatchGroup
                
                Divider().frame(height: 28)
                
                // Settings Toggle Button
                Button {
                    withAnimation {
                        showingSettingsPanel.toggle()
                    }
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 16, weight: showingSettingsPanel ? .bold : .regular))
                        .foregroundColor(showingSettingsPanel ? AppTheme.sakuraPink : AppTheme.textMuted)
                        .padding(6)
                        .background(Circle().fill(showingSettingsPanel ? AppTheme.sakuraPinkLight : Color.clear))
                }
                .buttonStyle(PlainButtonStyle())
            }

            // Select/Move mode hint
            if toolState.isSelectMoveMode {
                Divider().frame(height: 28)
                selectModeHint
            }
            
            Spacer()
            
            // Hide Button
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    toolbarIsHidden = true
                    UserDefaults.standard.set(true, forKey: "com.mainichi.toolbarIsHidden")
                }
            } label: {
                Image(systemName: "eye.slash")
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.textMuted)
                    .padding(6)
            }
            .buttonStyle(PlainButtonStyle())

            // Collapse Button
            Button {
                withAnimation {
                    toolbarIsExpanded = false
                    showingSettingsPanel = false
                }
            } label: {
                Image(systemName: "chevron.down.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppTheme.sakuraPink)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    @ViewBuilder
    private var undoRedoGroup: some View {
        HStack(spacing: 10) {
            Button { canvasController.undo() } label: {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(canvasController.canUndo ? AppTheme.textDark : AppTheme.textMuted.opacity(0.4))
            }
            .disabled(!canvasController.canUndo)

            Button { canvasController.redo() } label: {
                Image(systemName: "arrow.uturn.forward")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(canvasController.canRedo ? AppTheme.textDark : AppTheme.textMuted.opacity(0.4))
            }
            .disabled(!canvasController.canRedo)
            
            Divider()
                .frame(height: 12)
            
            Button { zoomFitTrigger = UUID() } label: {
                Image(systemName: "viewfinder")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppTheme.textDark)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 8).fill(AppTheme.paperBeige.opacity(0.4)))
    }

    @ViewBuilder
    private var toolSelectorGroup: some View {
        HStack(spacing: 10) {
            ForEach(EditorTool.allCases) { tool in
                Button { toolState.selectTool(tool) } label: {
                    VStack(spacing: 2) {
                        Image(systemName: tool.icon)
                            .font(.system(size: 18, weight: toolState.tool == tool ? .bold : .regular))
                            .foregroundColor(toolState.tool == tool ? AppTheme.sakuraPink : AppTheme.textMuted)
                            .padding(7)
                            .background(
                                Circle().fill(toolState.tool == tool ? AppTheme.sakuraPinkLight : Color.clear)
                            )
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    @ViewBuilder
    private var colorSwatchGroup: some View {
        HStack(spacing: 6) {
            ForEach(savedColors.prefix(5), id: \.self) { hex in
                Button { toolState.selectColor(hex) } label: {
                    Circle()
                        .fill(Color(hex: hex))
                        .frame(width: 20, height: 20)
                        .overlay(
                            Circle()
                                .stroke(toolState.colorHex == hex ? Color.white : Color.clear,
                                        lineWidth: 1.5)
                                .padding(2)
                        )
                        .overlay(
                            Circle()
                                .stroke(toolState.colorHex == hex ? AppTheme.sakuraPink : Color.clear,
                                        lineWidth: 1.5)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    @ViewBuilder
    private var selectModeHint: some View {
        HStack(spacing: 4) {
            Image(systemName: "hand.tap")
                .foregroundColor(AppTheme.sakuraPink)
                .font(.system(size: 12))
            Text("Drag objects to move • Resize via handle • Tap ✕ to delete")
                .font(AppTheme.fontRounded(size: 10, weight: .medium))
                .foregroundColor(AppTheme.textMuted)
        }
    }

    // MARK: - Attachments Drawer

    @ViewBuilder
    private var attachmentsDrawerPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Attachments")
                    .font(AppTheme.fontRounded(size: 15, weight: .bold))
                    .foregroundColor(AppTheme.textDark)
                Spacer()
                Button { withAnimation { showingAttachmentsDrawer = false } } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(AppTheme.textMuted)
                }
            }
            .padding(.bottom, 4)

            if !pages.isEmpty && selectedPage >= 1 && selectedPage <= pages.count {
                let attachments = pages[selectedPage - 1].attachments
                if attachments.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "paperclip")
                            .font(.system(size: 24))
                            .foregroundColor(AppTheme.textMuted.opacity(0.3))
                        Text("No files attached on this page.")
                            .font(AppTheme.fontRounded(size: 11))
                            .foregroundColor(AppTheme.textMuted)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(attachments) { att in
                                let url = LectureStorageService.shared.getAttachmentUrl(
                                    bookId: book.id,
                                    relativePath: att.localPath
                                )
                                let sizeStr = getFormattedFileSize(for: att)
                                let iconName = getIconName(for: att.fileName)
                                
                                HStack(spacing: 8) {
                                    Image(systemName: iconName)
                                        .font(.system(size: 16))
                                        .foregroundColor(AppTheme.sakuraPink)
                                        .frame(width: 20)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(att.fileName)
                                            .font(AppTheme.fontRounded(size: 11, weight: .bold))
                                            .lineLimit(1)
                                            .foregroundColor(AppTheme.textDark)
                                        
                                        Text(sizeStr)
                                            .font(AppTheme.fontRounded(size: 9, weight: .regular))
                                            .foregroundColor(AppTheme.textMuted)
                                    }
                                    
                                    Spacer()
                                    
                                    HStack(spacing: 4) {
                                        // Quick Look Preview
                                        Button {
                                            previewURL = url
                                        } label: {
                                            Image(systemName: "eye.fill")
                                                .font(.system(size: 11))
                                                .foregroundColor(AppTheme.textMuted)
                                                .padding(6)
                                                .background(Circle().fill(AppTheme.paperBeige.opacity(0.5)))
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        
                                        // Share/Export
                                        Button {
                                            activeSheet = .shareExport(items: [url])
                                        } label: {
                                            Image(systemName: "square.and.arrow.up")
                                                .font(.system(size: 11))
                                                .foregroundColor(AppTheme.textMuted)
                                                .padding(6)
                                                .background(Circle().fill(AppTheme.paperBeige.opacity(0.5)))
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        
                                        // Trash/Delete
                                        Button {
                                            removeAttachment(att)
                                        } label: {
                                            Image(systemName: "trash.fill")
                                                .font(.system(size: 11))
                                                .foregroundColor(.red.opacity(0.8))
                                                .padding(6)
                                                .background(Circle().fill(Color.red.opacity(0.08)))
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(8)
                                .background(AppTheme.paperBeige.opacity(0.25))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(AppTheme.borderLight, lineWidth: 0.5)
                                )
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(width: 260)
        .background(AppTheme.paperCard)
        .shadow(color: Color.black.opacity(0.08), radius: 4)
        .transition(.move(edge: .trailing))
    }

    // MARK: - Annotation Content Views

    @ViewBuilder
    private func annotationContentView(for item: AnnotationItem) -> some View {
        switch item.type {
        case .sticker:
            Text(item.content)
                .font(.system(size: 40))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(toolState.isSelectMoveMode ? 0.04 : 0))
                .cornerRadius(6)

        case .postIt:
            postItContentView(for: item)

        case .text:
            textAnnotationView(for: item)

        case .image:
            imageAnnotationView(for: item)
        }
    }

    @ViewBuilder
    private func postItContentView(for item: AnnotationItem) -> some View {
        if let pageIdx = pages.firstIndex(where: { $0.pageNumber == selectedPage }),
           let annotIdx = pages[pageIdx].annotations.firstIndex(where: { $0.id == item.id }) {
            PostItView(
                text: $pages[pageIdx].annotations[annotIdx].content,
                isSelectMoveMode: toolState.isSelectMoveMode
            )
        } else {
            Text(item.content)
        }
    }

    @ViewBuilder
    private func textAnnotationView(for item: AnnotationItem) -> some View {
        if let pageIdx = pages.firstIndex(where: { $0.pageNumber == selectedPage }),
           let annotIdx = pages[pageIdx].annotations.firstIndex(where: { $0.id == item.id }) {
            Group {
                if toolState.isSelectMoveMode {
                    TextField("Text...", text: $pages[pageIdx].annotations[annotIdx].content)
                        .font(AppTheme.fontRounded(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.textDark)
                        .padding(6)
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(4)
                } else {
                    Text(item.content.isEmpty ? "Text" : item.content)
                        .font(AppTheme.fontRounded(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.textDark)
                        .padding(6)
                        .background(Color.white.opacity(0.85))
                        .cornerRadius(4)
                }
            }
        } else {
            Text(item.content)
        }
    }

    @ViewBuilder
    private func imageAnnotationView(for item: AnnotationItem) -> some View {
        if let uiImage = LectureStorageService.shared.getCachedImage(bookId: book.id, imageName: item.content) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: CGFloat(item.width), height: CGFloat(item.height))
                .clipped()
                .cornerRadius(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(toolState.isSelectMoveMode ? AppTheme.sakuraPink : Color.clear,
                                lineWidth: 1.5)
                )
        } else {
            Rectangle()
                .fill(Color.gray.opacity(0.1))
                .overlay(Image(systemName: "photo").foregroundColor(.gray))
        }
    }

    // MARK: - Page Management

    private func saveCurrentPageData() {
        guard !pages.isEmpty && selectedPage >= 1 && selectedPage <= pages.count else { return }
        let pageId = pages[selectedPage - 1].id
        LectureStorageService.shared.saveDrawing(currentDrawing, bookId: book.id, pageId: pageId)
        savePagesList()
    }

    private func savePagesList() {
        LectureStorageService.shared.savePages(pages, for: book.id)
    }

    private func savePagesListDebounced() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            guard !Task.isCancelled else { return }
            savePagesList()
        }
    }

    private func changePage(to newPageNum: Int) {
        guard newPageNum >= 1 && newPageNum <= pages.count else { return }

        // Save current page drawing before switching
        if !pages.isEmpty && selectedPage >= 1 && selectedPage <= pages.count {
            let oldPageId = pages[selectedPage - 1].id
            LectureStorageService.shared.saveDrawing(currentDrawing, bookId: book.id, pageId: oldPageId)
        }

        selectedPage = newPageNum
        let newPageId = pages[newPageNum - 1].id
        currentDrawing = LectureStorageService.shared.loadDrawing(bookId: book.id, pageId: newPageId)

        // Reset undo state for the new page's drawing
        canvasController.updateUndoState()
    }

    private func applyTemplateToCurrentPage(_ template: PaperTemplate) {
        guard !pages.isEmpty && selectedPage >= 1 && selectedPage <= pages.count else { return }
        
        if template.kind == .builtIn {
            let presets = ["blank", "ruled", "grid", "dotGrid", "genkouYoushi", "kana", "kanji"]
            if let presetId = template.builtInPresetId, presets.contains(presetId) {
                let preset: PaperPreset
                switch presetId {
                case "blank": preset = .blank
                case "ruled": preset = .ruled
                case "grid": preset = .grid
                case "dotGrid": preset = .dotGrid
                case "genkouYoushi": preset = .genkouYoushi
                case "kana": preset = .kana
                case "kanji": preset = .kanji
                default: preset = .grid
                }
                pages[selectedPage - 1].paperPreset = preset
                pages[selectedPage - 1].paperTemplateId = nil
                pages[selectedPage - 1].customTemplateFileName = nil
                pages[selectedPage - 1].customTemplateKind = nil
            } else {
                pages[selectedPage - 1].paperTemplateId = template.id
                pages[selectedPage - 1].customTemplateFileName = nil
                pages[selectedPage - 1].customTemplateKind = nil
            }
        } else {
            pages[selectedPage - 1].paperTemplateId = template.id
            pages[selectedPage - 1].customTemplateFileName = template.localFileName
            pages[selectedPage - 1].customTemplateKind = template.kind.rawValue
        }
        savePagesList()
        // Reload canvas or trigger background redraw by re-applying pageNumber
        let newPageId = pages[selectedPage - 1].id
        currentDrawing = LectureStorageService.shared.loadDrawing(bookId: book.id, pageId: newPageId)
        canvasController.updateUndoState()
    }
    
    private func addNewPageWithTemplate(_ template: PaperTemplate) {
        saveCurrentPageData()
        let newPageNum = pages.count + 1
        
        var paperTemplateId: String? = nil
        var customTemplateFileName: String? = nil
        var customTemplateKind: String? = nil
        var paperPreset = PaperPreset.grid
        
        if template.kind == .builtIn {
            let presets = ["blank", "ruled", "grid", "dotGrid", "genkouYoushi", "kana", "kanji"]
            if let presetId = template.builtInPresetId, presets.contains(presetId) {
                switch presetId {
                case "blank": paperPreset = .blank
                case "ruled": paperPreset = .ruled
                case "grid": paperPreset = .grid
                case "dotGrid": paperPreset = .dotGrid
                case "genkouYoushi": paperPreset = .genkouYoushi
                case "kana": paperPreset = .kana
                case "kanji": paperPreset = .kanji
                default: paperPreset = .grid
                }
            } else {
                paperTemplateId = template.id
            }
        } else {
            paperTemplateId = template.id
            customTemplateFileName = template.localFileName
            customTemplateKind = template.kind.rawValue
        }
        
        let newPage = LecturePage(
            pageNumber: newPageNum,
            pdfPageNumber: nil,
            paperPreset: paperPreset,
            paperTemplateId: paperTemplateId,
            customTemplateFileName: customTemplateFileName,
            customTemplateKind: customTemplateKind
        )
        pages.append(newPage)
        savePagesList()
        changePage(to: newPageNum)
    }

    private func addNewPage() {
        saveCurrentPageData()
        let newPageNum = pages.count + 1

        // Inherit current page's paper preset
        let isCurrentValid = !pages.isEmpty && selectedPage >= 1 && selectedPage <= pages.count
        let inheritedPreset = isCurrentValid ? pages[selectedPage - 1].paperPreset : PaperPreset.grid

        // Inherit template parameters if present
        let inheritedTemplateId = isCurrentValid ? pages[selectedPage - 1].paperTemplateId : nil
        let inheritedCustomFileName = isCurrentValid ? pages[selectedPage - 1].customTemplateFileName : nil
        let inheritedCustomKind = isCurrentValid ? pages[selectedPage - 1].customTemplateKind : nil

        let newPage = LecturePage(
            pageNumber: newPageNum,
            pdfPageNumber: nil,
            paperPreset: inheritedPreset,
            paperTemplateId: inheritedTemplateId,
            customTemplateFileName: inheritedCustomFileName,
            customTemplateKind: inheritedCustomKind
        )
        pages.append(newPage)
        savePagesList()
        changePage(to: newPageNum)
    }

    private func deletePage(_ page: LecturePage) {
        guard pages.count > 1 else { return }

        // Save current page data if we are NOT deleting the current page
        if !pages.isEmpty && selectedPage >= 1 && selectedPage <= pages.count && page.id != pages[selectedPage - 1].id {
            saveCurrentPageData()
        }

        guard let idx = pages.firstIndex(where: { $0.id == page.id }) else {
            pageToDelete = nil
            return
        }

        pages.remove(at: idx)
        for i in 0..<pages.count { pages[i].pageNumber = i + 1 }
        savePagesList()

        let targetPage = min(selectedPage, pages.count)
        selectedPage = targetPage
        
        let newPageId = pages[targetPage - 1].id
        currentDrawing = LectureStorageService.shared.loadDrawing(bookId: book.id, pageId: newPageId)
        canvasController.updateUndoState()

        pageToDelete = nil
    }

    // MARK: - Annotation Adders

    private func addStickerAnnotation(_ emoji: String) {
        guard !pages.isEmpty && selectedPage >= 1 && selectedPage <= pages.count else { return }
        let sticker = AnnotationItem(type: .sticker, content: emoji, width: 60, height: 60)
        pages[selectedPage - 1].annotations.append(sticker)
        savePagesList()
    }

    private func addPostItAnnotation() {
        guard !pages.isEmpty && selectedPage >= 1 && selectedPage <= pages.count else { return }
        let postIt = AnnotationItem(type: .postIt, content: "", width: 160, height: 160)
        pages[selectedPage - 1].annotations.append(postIt)
        savePagesList()
    }

    private func addTextAnnotation() {
        guard !pages.isEmpty && selectedPage >= 1 && selectedPage <= pages.count else { return }
        // .text type — plain movable label, NOT a post-it
        let textLabel = AnnotationItem(type: .text, content: "Text", width: 160, height: 50)
        pages[selectedPage - 1].annotations.append(textLabel)
        savePagesList()
    }

    // MARK: - Export

    @MainActor
    private func exportCurrentPage() {
        saveCurrentPageData()
        guard !pages.isEmpty && selectedPage >= 1 && selectedPage <= pages.count else { return }

        let preset = pages[selectedPage - 1].paperPreset
        let active = activeBook ?? book
        let page = pages[selectedPage - 1]

        let exportView = ZStack {
            if let templateId = page.paperTemplateId {
                if let customFileName = page.customTemplateFileName {
                    let fileURL = templateService.getTemplateFileURL(fileName: customFileName)
                    if page.customTemplateKind == PaperTemplateKind.importedPDF.rawValue {
                        PDFPageBackgroundView(pdfURL: fileURL, pageIndex: 0, canvasSize: CGSize(width: 720, height: 960))
                    } else {
                        if let uiImage = UIImage(contentsOfFile: fileURL.path) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 720, height: 960)
                                .clipped()
                        } else {
                            Color.white
                        }
                    }
                } else {
                    let presetId = templateService.templates.first(where: { $0.id == templateId })?.builtInPresetId ?? templateId
                    BuiltInPaperTemplateBackgroundView(presetId: presetId)
                }
            } else {
                if active.isPDF,
                   let pdfFileName = active.pdfFileName,
                   let pdfPageIdx = page.pdfPageNumber {
                    let pdfURL = LectureStorageService.shared.getPDFUrl(bookId: active.id, pdfFileName: pdfFileName)
                    PDFPageBackgroundView(pdfURL: pdfURL, pageIndex: pdfPageIdx, canvasSize: CGSize(width: 720, height: 960))
                } else {
                    exportPaperBackground(for: preset)
                }
            }

            ForEach(page.annotations) { item in
                AnnotationRenderView(item: item, bookId: active.id)
            }
        }
        .frame(width: 720, height: 960)

        let renderer = ImageRenderer(content: exportView)
        renderer.scale = 2.0
        guard let bgImage = renderer.uiImage else { return }

        let drawingImage = currentDrawing.image(from: CGRect(x: 0, y: 0, width: 720, height: 960), scale: 2.0)
        let combinedRenderer = UIGraphicsImageRenderer(size: CGSize(width: 720, height: 960))
        let finalImage = combinedRenderer.image { _ in
            bgImage.draw(in: CGRect(x: 0, y: 0, width: 720, height: 960))
            drawingImage.draw(in: CGRect(x: 0, y: 0, width: 720, height: 960))
        }

        activeSheet = .shareExport(items: [finalImage])
    }

    @ViewBuilder
    private func exportPaperBackground(for preset: PaperPreset) -> some View {
        switch preset {
        case .blank:        Color.white
        case .ruled:        RuledPaperView()
        case .grid:         GridPaperView(spacing: 22)
        case .dotGrid:      DotGridPaperView(spacing: 22)
        case .genkouYoushi: GenkouYoushiView()
        case .kana:         KanaPracticeView()
        case .kanji:        KanjiPracticeView()
        }
    }

    // MARK: - Polish Pass 4 Helpers

    private func getFormattedFileSize(for item: AttachmentItem) -> String {
        let active = activeBook ?? book
        let url = LectureStorageService.shared.getAttachmentUrl(bookId: active.id, relativePath: item.localPath)
        do {
            let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
            if let fileSize = resourceValues.fileSize {
                let formatter = ByteCountFormatter()
                formatter.allowedUnits = [.useAll]
                formatter.countStyle = .file
                return formatter.string(fromByteCount: Int64(fileSize))
            }
        } catch {
            print("Error reading file size: \(error)")
        }
        return "Unknown size"
    }

    private func getIconName(for fileName: String) -> String {
        let ext = URL(fileURLWithPath: fileName).pathExtension.lowercased()
        switch ext {
        case "pdf":
            return "doc.richtext.fill"
        case "png", "jpg", "jpeg", "heic", "gif":
            return "doc.image.fill"
        case "txt", "rtf", "pages":
            return "doc.text.fill"
        case "mp3", "m4a", "wav":
            return "doc.audio.fill"
        case "mp4", "mov":
            return "doc.video.fill"
        case "zip", "tar", "gz":
            return "doc.zipper"
        default:
            return "doc.fill"
        }
    }

    private func removeAttachment(_ attachment: AttachmentItem) {
        guard !pages.isEmpty && selectedPage >= 1 && selectedPage <= pages.count else { return }
        let active = activeBook ?? book
        
        if let idx = pages[selectedPage - 1].attachments.firstIndex(where: { $0.id == attachment.id }) {
            pages[selectedPage - 1].attachments.remove(at: idx)
            savePagesList()
            
            let fileURL = LectureStorageService.shared.getAttachmentUrl(bookId: active.id, relativePath: attachment.localPath)
            try? FileManager.default.removeItem(at: fileURL)
            
            showToast(message: "Attachment removed.")
        }
    }

    private func showToast(message: String) {
        toastMessage = message
        Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000) // 2.5 seconds
            withAnimation {
                if toastMessage == message {
                    toastMessage = nil
                }
            }
        }
    }

    private func importPDFPagesAction(url: URL) {
        let active = activeBook ?? book
        let startingPageNumber = pages.count + 1
        
        if let result = LectureStorageService.shared.importPDFPages(from: url, into: active, startingPageNumber: startingPageNumber) {
            // Update book details
            activeBook = result.updatedBook
            
            // Append imported pages to the notebook
            pages.append(contentsOf: result.importedPages)
            savePagesList()
            
            // Go to the first newly imported page
            changePage(to: startingPageNumber)
            
            showToast(message: "PDF imported as pages \(startingPageNumber) - \(pages.count)!")
        } else {
            showToast(message: "Failed to import PDF pages.")
        }
    }
}

// MARK: - Toolbar Button Component

struct ToolbarButton: View {
    let title: String
    let iconName: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: iconName)
                    .font(.system(size: 13))
                Text(title)
                    .font(AppTheme.fontRounded(size: 12, weight: .semibold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(AppTheme.paperCard)
            .foregroundColor(AppTheme.textDark)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(AppTheme.borderLight, lineWidth: 0.8)
            )
            .shadow(color: Color.black.opacity(0.02), radius: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Mini Preview Canvas for Tester Pad

struct MiniPreviewCanvasView: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    @Binding var toolState: DrawingToolState

    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: MiniPreviewCanvasView

        init(_ parent: MiniPreviewCanvasView) {
            self.parent = parent
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            if canvasView.drawing != parent.drawing {
                parent.drawing = canvasView.drawing
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.delegate = context.coordinator
        canvas.drawingPolicy = .anyInput
        canvas.isOpaque = false
        canvas.backgroundColor = .clear
        canvas.showsVerticalScrollIndicator = false
        canvas.showsHorizontalScrollIndicator = false
        applyTool(to: canvas)
        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        if uiView.drawing != drawing {
            uiView.drawing = drawing
        }
        applyTool(to: uiView)
    }

    private func applyTool(to canvas: PKCanvasView) {
        let color = Color(hex: toolState.colorHex).uiColor
        let width = toolState.strokeWidth

        switch toolState.tool {
        case .pen:
            let inkType: PKInkingTool.InkType
            switch toolState.activePenType {
            case .ballpoint:
                inkType = .pen
            case .fountain:
                inkType = .fountainPen
            case .brush:
                inkType = .watercolor
            case .smoothStudy:
                inkType = .monoline
            }
            canvas.tool = PKInkingTool(inkType, color: color.withAlphaComponent(toolState.opacity), width: width)

        case .pencil:
            canvas.tool = PKInkingTool(.pencil, color: color.withAlphaComponent(toolState.opacity), width: width)

        case .highlighter:
            canvas.tool = PKInkingTool(.marker, color: color.withAlphaComponent(toolState.opacity * 0.4), width: max(width * 2.5, 12.0))

        case .eraser:
            canvas.tool = PKEraserTool(.vector)

        case .selectMove:
            canvas.tool = PKInkingTool(.pen, color: color, width: width)
        }
    }
}

// MARK: - Settings Tab Selection

enum SettingsTab: String, CaseIterable, Identifiable {
    case penStyle = "Style"
    case presets  = "Presets"
    case favorites = "Favorites"
    
    var id: String { rawValue }
}

// MARK: - Restore Button Position Selection

enum RestoreButtonPosition: String, Codable, CaseIterable {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
}
